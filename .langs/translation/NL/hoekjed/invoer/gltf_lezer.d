module hoekjed.invoer.gltf_lezer;

import bindbc.opengl;
import hoekjed;
import hoekjed.invoer.gltf;
import std.algorithm.searching : countUntil;
import std.array : array;
import std.conv : to;
import std.exception : enforce;
import std.file : readText;
import std.math : PI_4;
import std.path : dirName;
import std.stdio;
import std.typecons : Nullable;

class GltfLezer {
	Json json;
	Wereld hoofd_wereld;
	Wereld[] werelden;
	Voorwerp[] voorwerpen;
	Materiaal[] materialen;

	Textuur[] texturen;
	Afbeelding[] afbeeldingen;
	Sampler[] samplers;

	Licht[] lichten;

	Buffer[] buffers;
	ubyte[][] buffers_inhoud;
	Driehoeksnet.Koppeling[] koppelingen;
	Driehoeksnet.Eigenschap[] eigenschappen;
	Driehoeksnet[][] netten;

	Zicht[] zichten;

	private ulong[] gezochte_tussensprongen;

	this(string bestand) {
		string dir = dirName(bestand);
		this.json = JsonLezer.leesJsonBestand(bestand);
		enforce(json["asset"].voorwerp["version"].string_ == "2.0");

		leesBuffers(dir);
		leesKoppelingen();
		leesEigenschappen();
		zoekTussensprongen();

		leesLichten(); // KHR_lights_punctual uitbreiding

		leesSamplers();
		leesAfbeeldingen(dir);
		leesTextures();

		leesMaterialen();
		leesDriehoeksnetten();
		leesZichten();
		leesVoorwerpen();
		leesWerelden();
	}

	private void leesWerelden() {
		JsonVal[] werelden_json = json["scenes"].lijst;
		foreach (JsonVal wereld; werelden_json)
			werelden ~= leesWereld(wereld.voorwerp);

		if (JsonVal* j = "scene" in json)
			hoofd_wereld = werelden[j.long_];
		else
			hoofd_wereld = null;
	}

	private Wereld leesWereld(Json wereld_json) {
		string naam = wereld_json["name"].string_;
		Wereld wereld = new Wereld(naam);
		JsonVal[] kinderen = wereld_json["nodes"].lijst;

		void voegEigenschappenToe(Voorwerp v) {
			foreach (Voorwerp.Eigenschap e; v.eigenschappen) {
				if (Licht l = cast(Licht) e) {
					wereld.lichtVerzameling += l;
				}
			}
			foreach (Voorwerp kind; v.kinderen)
				voegEigenschappenToe(kind);
		}

		foreach (JsonVal kind; kinderen) {
			Voorwerp v = voorwerpen[kind.long_];
			wereld.kinderen ~= v;
			voegEigenschappenToe(v);
		}
		return wereld;
	}

	private void leesVoorwerpen() {
		JsonVal[] voorwerpen_json = json["nodes"].lijst;
		foreach (JsonVal voorwerp; voorwerpen_json)
			voorwerpen ~= leesVoorwerp(voorwerp.voorwerp);
	}

	private Voorwerp leesVoorwerp(Json voorwerp_json) {
		string naam = "";
		if (JsonVal* j = "name" in voorwerp_json)
			naam = j.string_;

		Driehoeksnet[] netten = [];
		if (JsonVal* j = "mesh" in voorwerp_json)
			netten = this.netten[j.long_];

		Voorwerp voorwerp = new Voorwerp(naam, netten);

		if (JsonVal* j = "camera" in voorwerp_json) {
			long z = j.long_;
			voorwerp.eigenschappen ~= zichten[z];
		}

		if (JsonVal* e = "extensions" in voorwerp_json)
			if (JsonVal* el = "KHR_lights_punctual" in e.voorwerp) {
				long l = el.voorwerp["light"].long_;
				voorwerp.eigenschappen ~= lichten[l];
			}

		if (JsonVal* j = "children" in voorwerp_json)
			foreach (JsonVal kindj; j.lijst) {
				Voorwerp kind = voorwerpen[kindj.long_];
				voorwerp.kinderen ~= kind;
				kind.ouder = voorwerp;
			}

		Houding houding;
		if (JsonVal* j = "translation" in voorwerp_json) {
			houding.plek = j.vec!(3, nauwkeurigheid);
		}
		if (JsonVal* j = "rotation" in voorwerp_json) {
			Vec!4 r = j.vec!(4, nauwkeurigheid);
			houding.draai = Quat(r.w, r.x, r.y, r.z);
		}
		if (JsonVal* j = "scale" in voorwerp_json) {
			houding.grootte = j.vec!(3, nauwkeurigheid);
		}

		voorwerp.houding = houding;
		return voorwerp;
	}

	private void leesZichten() {
		if (JsonVal* j = "cameras" in json) {
			JsonVal[] zichten_json = json["cameras"].lijst;
			foreach (JsonVal zicht; zichten_json)
				zichten ~= leesZicht(zicht.voorwerp);
		}
	}

	private Zicht leesZicht(Json zicht_json) {
		string naam = "";
		if (JsonVal* j = "name" in zicht_json)
			naam = j.string_;

		string soort = zicht_json["type"].string_;
		if (soort == "perspective") {
			Json instelling = zicht_json["perspective"].voorwerp;
			nauwkeurigheid aspect = 1 / instelling["aspectRatio"].double_;

			double yfov = instelling["yfov"].double_;
			nauwkeurigheid xfov = yfov / aspect;

			nauwkeurigheid voorvlak = instelling["znear"].double_;
			nauwkeurigheid achtervlak = instelling["zfar"].double_;

			Mat!4 projectieM = Zicht.perspectiefProjectie(aspect, xfov, voorvlak, achtervlak);
			return new Zicht(projectieM);
		} else {
			enforce(soort == "orthographic");
			assert(0, "Orthografisch zicht nog niet geïmplementeerd.");
			// TODO Orthografisch zicht
		}
	}

	private void leesDriehoeksnetten() {
		JsonVal[] driehoeksnetten_json = json["meshes"].lijst;
		foreach (JsonVal net; driehoeksnetten_json)
			netten ~= leesDriehoeksnet(net.voorwerp);
	}

	private Driehoeksnet[] leesDriehoeksnet(Json driehoeksnet_json) {
		string naam = driehoeksnet_json.get("name", JsonVal("")).string_;

		Driehoeksnet[] netten;
		JsonVal[] primitieven = driehoeksnet_json["primitives"].lijst;
		foreach (i; 0 .. primitieven.length) {
			netten ~= leesPrimitief(primitieven[i].voorwerp, naam ~ "#" ~ i.to!string);
		}

		return netten;
	}

	private Driehoeksnet leesPrimitief(Json primitief, string naam) {
		Driehoeksnet.Koppeling vertaalKoppeling(Driehoeksnet.Koppeling k) {
			k.buffer = this.buffers[k.buffer].buffer;
			return k;
		}

		Json eigenschappen = primitief["attributes"].voorwerp;
		enforce("POSITION" in eigenschappen && "NORMAL" in eigenschappen,
			"Aanwezigheid van POSITION/NORMAL attributen aangenomen.");

		Driehoeksnet.Eigenschap[] net_eigenschappen;
		string[] net_eigenschap_namen;
		net_eigenschappen ~= this.eigenschappen[eigenschappen["POSITION"].long_];
		net_eigenschappen ~= this.eigenschappen[eigenschappen["NORMAL"].long_];
		net_eigenschap_namen ~= "POSITION";
		net_eigenschap_namen ~= "NORMAL";
		for (uint i = 0; 16u; i++) {
			string s = "TEXCOORD_" ~ i.to!string;
			if (s !in eigenschappen)
				break;
			net_eigenschappen ~= this.eigenschappen[eigenschappen[s].long_];
			net_eigenschap_namen ~= s;
		}
		for (uint i = 0; 16u; i++) {
			string s = "COLOR_" ~ i.to!string;
			if (s !in eigenschappen)
				break;
			net_eigenschappen ~= this.eigenschappen[eigenschappen[s].long_];
			net_eigenschap_namen ~= s;
		}

		Driehoeksnet.Koppeling[] net_koppelingen;
		uint[uint] koppelingen_vertaling;
		foreach (ref Driehoeksnet.Eigenschap eigenschap; net_eigenschappen) {
			uint i = eigenschap.koppeling;
			if (i !in koppelingen_vertaling) {
				koppelingen_vertaling[i] = cast(uint) koppelingen_vertaling.length;
				net_koppelingen ~= vertaalKoppeling(this.koppelingen[i]);
			}
			eigenschap.koppeling = koppelingen_vertaling[i];
		}

		Driehoeksnet.Knoopindex knoopindex;
		if ("indices" !in primitief) {
			knoopindex.buffer.nullify();
			knoopindex.knooptal = cast(int) net_eigenschappen[0].elementtal;
			knoopindex.begin = 0;
		} else {
			Driehoeksnet.Eigenschap eigenschap = this.eigenschappen[primitief["indices"].long_];
			Driehoeksnet.Koppeling koppeling = vertaalKoppeling(
				this.koppelingen[eigenschap.koppeling]);

			knoopindex.buffer = koppeling.buffer;
			knoopindex.knooptal = cast(int) eigenschap.elementtal;
			knoopindex.begin = cast(uint)(eigenschap.begin + koppeling.begin);
			knoopindex.soort = eigenschap.soort;
		}

		Materiaal materiaal = Gltf.standaard_materiaal;
		if (JsonVal* j = "material" in primitief)
			materiaal = this.materialen[j.long_];

		Verver verver = Gltf.genereerVerver(net_eigenschappen, net_eigenschap_namen, materiaal);

		return new Driehoeksnet(naam, net_eigenschappen, net_koppelingen, knoopindex, verver, materiaal);
	}

	private void leesSamplers() {
		if (JsonVal* ss_json = "samplers" in json) {
			JsonVal[] ss = ss_json.lijst;
			samplers = new Sampler[ss.length + 1];
			foreach (long i; 0 .. ss.length)
				samplers[i] = leesSampler(ss[i].voorwerp);
		}
	}

	private Sampler leesSampler(Json s_json) {
		uint minFilter = GL_NEAREST_MIPMAP_LINEAR;
		uint magFilter = GL_NEAREST;
		if (JsonVal* j = "minFilter" in s_json)
			minFilter = gltfNaarGlFilter(j.long_, true);
		if (JsonVal* j = "magFilter" in s_json)
			magFilter = gltfNaarGlFilter(j.long_, false);

		uint wrapS = gltfNaarGlWrap(s_json.get("wrapS", JsonVal(10497)).long_);
		uint wrapT = gltfNaarGlWrap(s_json.get("wrapT", JsonVal(10497)).long_);
		string naam = s_json.get("name", JsonVal("")).string_;

		return new Sampler(naam, wrapS, wrapT, minFilter, magFilter);
	}

	private uint gltfNaarGlWrap(long gltfWrap) {
		switch (gltfWrap) {
		case 33071:
			return GL_CLAMP_TO_EDGE;
		case 33648:
			return GL_MIRRORED_REPEAT;
		case 10497:
			return GL_REPEAT;
		default:
			assert(0, "Onjuiste waarde voor wrapS/T: " ~ gltfWrap.to!string);
		}
	}

	private uint gltfNaarGlFilter(long gltfFilter, bool isMinFilter) {
		switch (gltfFilter) {
		case 9728:
			return GL_NEAREST;
		case 9729:
			return GL_LINEAR;
		default:
		}
		enforce(isMinFilter, "Onjuiste waarde voor magFilter: " ~ gltfFilter.to!string);
		switch (gltfFilter) {
		case 9984:
			return GL_NEAREST_MIPMAP_NEAREST;
		case 9985:
			return GL_LINEAR_MIPMAP_NEAREST;
		case 9986:
			return GL_NEAREST_MIPMAP_LINEAR;
		case 9987:
			return GL_LINEAR_MIPMAP_LINEAR;
		default:
			assert(0, "Onjuiste waarde voor minFilter: " ~ gltfFilter.to!string);
		}
	}

	private void leesAfbeeldingen(string dir) {
		if (JsonVal* j = "images" in json)
			foreach (JsonVal a_json; j.lijst)
				afbeeldingen ~= leesAfbeelding(a_json.voorwerp, dir);
	}

	private Afbeelding leesAfbeelding(Json a_json, string dir) {
		ubyte[] inhoud;
		if (JsonVal* uri_json = "uri" in a_json) {
			assert("bufferView" !in a_json);
			inhoud = leesURI(uri_json.string_, dir);
		} else {
			inhoud = leesKoppelingInhoud(cast(uint) a_json["bufferView"].long_);
		}
		string naam = a_json.get("name", JsonVal("")).string_;
		return new Afbeelding(inhoud, naam);
	}

	private void leesTextures() {
		if (JsonVal* ts_json = "textures" in json) {
			JsonVal[] ts = ts_json.lijst;
			texturen = new Textuur[ts.length];
			foreach (long i; 0 .. ts.length) {
				Json t_json = ts[i].voorwerp;
				Textuur t;
				t.naam = t_json.get("sampler", JsonVal("")).string_;
				if (JsonVal* s = "sampler" in t_json)
					t.sampler = samplers[s.long_];
				else
					t.sampler = samplers[$ - 1];
				assert("source" in t_json, "Textuur heeft geen afbeelding");
				t.afbeelding = afbeeldingen[t_json["source"].long_];
				texturen[i] = t;
			}
		}
	}

	private void leesMaterialen() {
		if (JsonVal* j = "materials" in json)
			foreach (JsonVal m_json; j.lijst)
				materialen ~= leesMateriaal(m_json.voorwerp);
	}

	private TextuurInfo leesTextuurInfo(Json ti_json) {
		TextuurInfo ti;
		ti.textuur = texturen[ti_json["index"].long_];
		ti.beeldplek = cast(uint) ti_json.get("texCoord", JsonVal(0)).long_;
		return ti;
	}

	private NormaalTextuurInfo leesNormaalTextuurInfo(Json ti_json) {
		NormaalTextuurInfo ti;
		ti.textuurInfo = leesTextuurInfo(ti_json);
		ti.normaal_schaal = cast(nauw) ti_json.get("scale", JsonVal(1.0)).double_;
		return ti;
	}

	private OcclusionTextuurInfo leesOcclusionTextuurInfo(Json ti_json) {
		OcclusionTextuurInfo ti;
		ti.textuurInfo = leesTextuurInfo(ti_json);
		ti.occlusion_sterkte = cast(nauw) ti_json.get("strength", JsonVal(1.0)).double_;
		return ti;
	}

	private Materiaal leesMateriaal(Json m_json) {
		Materiaal.AlphaGedrag vertaalAlphaGedrag(string gedrag) {
			switch (gedrag) {
			case "OPAQUE":
				return Materiaal.AlphaGedrag.ONDOORZICHTIG;
			case "MASK":
				return Materiaal.AlphaGedrag.MASKER;
			case "BLEND":
				return Materiaal.AlphaGedrag.MENGEN;
			default:
				assert(0, "Ongeldig alphagedrag: " ~ gedrag);
			}
		}

		Materiaal materiaal = Gltf.standaard_materiaal;
		materiaal.naam = m_json.get("name", JsonVal("")).string_;

		materiaal.pbr = Gltf.standaard_pbr;
		if (JsonVal* pbr_jval = "pbrMetallicRoughness" in m_json)
			materiaal.pbr = leesPBR(pbr_jval.voorwerp);

		if (JsonVal* j = "normalTexture" in m_json)
			materiaal.normaal_textuur = leesNormaalTextuurInfo(j.voorwerp);
		if (JsonVal* j = "occlusionTexture" in m_json)
			materiaal.occlusion_textuur = leesOcclusionTextuurInfo(j.voorwerp);
		if (JsonVal* j = "emissiveTexture" in m_json)
			materiaal.straling_textuur = leesTextuurInfo(j.voorwerp);
		if (JsonVal* j = "emissiveFactor" in m_json)
			materiaal.straling_factor = j.vec!(3, nauw);
		if (JsonVal* j = "alphaMode" in m_json)
			materiaal.alpha_gedrag = vertaalAlphaGedrag(j.string_);
		if (JsonVal* j = "alphaCutoff" in m_json)
			materiaal.alpha_scheiding = cast(nauw) j.double_;
		if (JsonVal* j = "doubleSided" in m_json)
			materiaal.tweezijdig = j.bool_;
		return materiaal;
	}

	private PBR leesPBR(Json pbr_j) {
		PBR pbr = Gltf.standaard_pbr;
		if (JsonVal* j = "baseColorFactor" in pbr_j)
			pbr.kleur_factor = j.vec!(4, nauwkeurigheid);
		if (JsonVal* j = "baseColorTexture" in pbr_j)
			pbr.kleur_textuur = leesTextuurInfo(j.voorwerp);
		if (JsonVal* j = "metallicFactor" in pbr_j)
			pbr.metaal = j.double_;
		if (JsonVal* j = "roughnessFactor" in pbr_j)
			pbr.ruwheid = j.double_;
		if (JsonVal* j = "metallicRoughnessTexture" in pbr_j)
			pbr.metaal_ruwheid_textuur = leesTextuurInfo(j.voorwerp);
		return pbr;
	}

	private void leesLichten() {
		if (JsonVal* e = "extensions" in json)
			if (JsonVal* el = "KHR_lights_punctual" in e.voorwerp) {
				foreach (JsonVal l_jv; el.voorwerp["lights"].lijst) {
					lichten ~= leesLicht(l_jv.voorwerp);
				}
			}
	}

	private Licht leesLicht(Json lj) {
		string naam = "";
		Vec!3 kleur = Vec!3(1);
		nauwkeurigheid sterkte = 1;

		if (JsonVal* nj = "name" in lj)
			naam = nj.string_;
		if (JsonVal* cj = "color" in lj)
			kleur = cj.vec!(3, nauwkeurigheid);
		if (JsonVal* sj = "intensity" in lj)
			sterkte = sj.double_;

		nauwkeurigheid rijkweidte = lj.get("range", JsonVal(double.infinity)).double_;

		string soort = lj["type"].string_;
		switch (soort) {
		case "directional":
			return new Licht(Licht.Soort.STRAAL, kleur, sterkte, rijkweidte);
		case "point":
			return new Licht(Licht.Soort.PUNT, kleur, sterkte, rijkweidte);
		case "spot":
			Json spotj = lj["spot"].voorwerp;
			nauwkeurigheid binnenhoek = spotj.get("innerConeAngle", JsonVal(0.0)).double_;
			nauwkeurigheid buitenhoek = spotj.get("outerConeAngle", JsonVal(PI_4)).double_;
			return new Licht(Licht.Soort.SCHIJNWERPER, kleur, sterkte, rijkweidte, binnenhoek, buitenhoek);
		default:
			assert(0, "Licht soort onbekend: " ~ soort);
		}
	}

	private void zoekTussensprongen() {
		Tussensprong: foreach (ulong i; 0 .. gezochte_tussensprongen.length) {
			foreach (Driehoeksnet.Eigenschap e; eigenschappen) {
				if (e.koppeling != i)
					continue;
				koppelingen[i].tussensprong = cast(int) bepaalTussensprong(e);
				continue Tussensprong;
			}
			koppelingen[i].tussensprong = 0;
			writeln(
				"Kon geen accessor vinden om tussensprong van koppeling#" ~ i.to!string ~ " te vinden.");
		}
	}

	private size_t bepaalTussensprong(Driehoeksnet.Eigenschap e) {
		return e.soorttal * eigenschapSoortGrootte(e.soort);
	}

	private size_t eigenschapSoortGrootte(GLenum soort) {
		switch (soort) {
		case GL_UNSIGNED_BYTE:
			return ubyte.sizeof;
		case GL_BYTE:
			return byte.sizeof;
		case GL_UNSIGNED_SHORT:
			return ushort.sizeof;
		case GL_SHORT:
			return short.sizeof;
		case GL_UNSIGNED_INT:
			return uint.sizeof;
		case GL_FLOAT:
			return float.sizeof;
		default:
			assert(0, "Onondersteund accessor.componentType: " ~ soort.to!string);
		}
	}

	private void leesEigenschappen() {
		JsonVal[] eigenschappen_json = json["accessors"].lijst;
		foreach (JsonVal eigenschap_json; eigenschappen_json)
			eigenschappen ~= leesEigenschap(eigenschap_json.voorwerp);
	}

	private uint vertaalEigenschapSoort(int soort) {
		switch (soort) {
		case 5120:
			return GL_BYTE;
		case 5121:
			return GL_UNSIGNED_BYTE;
		case 5122:
			return GL_SHORT;
		case 5123:
			return GL_UNSIGNED_SHORT;
		case 5125:
			return GL_UNSIGNED_INT;
		case 5126:
			return GL_FLOAT;
		default:
			assert(0, "Onondersteund accessor.componentType: " ~ soort.to!string);
		}
	}

	private ubyte vertaalEigenschapSoorttal(string soort) {
		switch (soort) {
		case "SCALAR":
			return 1;
		case "VEC2":
			return 2;
		case "VEC3":
			return 3;
		case "VEC4":
			return 4;
		case "MAT2":
			return 4;
		case "MAT3":
			return 9;
		case "MAT4":
			return 16;
		default:
			assert(0, "Onondersteuned accessors.type: " ~ soort);
		}
	}

	private Driehoeksnet.Eigenschap leesEigenschap(Json eigenschap_json) {
		Driehoeksnet.Eigenschap eigenschap;
		if ("sparse" in eigenschap_json || "bufferView" !in eigenschap_json)
			assert(0, "Sparse accessor / lege bufferview niet geimplementeerd");
		eigenschap.koppeling = cast(uint) eigenschap_json["bufferView"].long_;
		eigenschap.soort = vertaalEigenschapSoort(
			cast(int) eigenschap_json["componentType"].long_);
		eigenschap.soorttal = vertaalEigenschapSoorttal(eigenschap_json["type"].string_);
		eigenschap.matrix = (eigenschap_json["type"].string_[0 .. 3] == "MAT");
		eigenschap.genormaliseerd = eigenschap_json.get("normalized", JsonVal(false)).bool_;
		eigenschap.elementtal = eigenschap_json["count"].long_;
		eigenschap.begin = cast(uint) eigenschap_json.get("byteOffset", JsonVal(0L)).long_;
		return eigenschap;
	}

	private void leesKoppelingen() {
		JsonVal[] koppelingen_json = json["bufferViews"].lijst;
		koppelingen = new Driehoeksnet.Koppeling[koppelingen_json.length];
		for (int i = 0; i < koppelingen_json.length; i++) {
			Json koppeling_json = koppelingen_json[i].voorwerp;
			Driehoeksnet.Koppeling koppeling;
			koppeling.buffer = cast(uint) koppeling_json["buffer"].long_;
			koppeling.grootte = koppeling_json["byteLength"].long_;
			koppeling.begin = koppeling_json.get("byteOffset", JsonVal(0L)).long_;
			if (JsonVal* j = "byteStride" in koppeling_json)
				koppeling.tussensprong = cast(int) j.long_;
			else
				gezochte_tussensprongen ~= i;
			koppelingen[i] = koppeling;
		}
	}

	private void leesBuffers(string dir) {
		JsonVal[] lijst = json["buffers"].lijst;
		buffers = new Buffer[lijst.length];
		buffers_inhoud = new ubyte[][lijst.length];
		for (uint i = 0; i < lijst.length; i++) {
			Json buffer = lijst[i].voorwerp;
			const long grootte = buffer["byteLength"].long_;
			string uri = buffer["uri"].string_;
			ubyte[] inhoud = leesURI(uri, dir);

			enforce(inhoud.length == grootte, "Buffer grootte onjuist: "
					~ inhoud.length.to!string ~ " in plaats van " ~ grootte.to!string);

			buffers[i] = new Buffer(inhoud);
			buffers_inhoud[i] = inhoud;
		}
	}

	private ubyte[] leesURI(string uri, string dir) {
		if (uri.length > 5 && uri[0 .. 5] == "data:") {
			import std.base64;

			uint char_p = 5;
			while (uri[char_p] != ',') {
				char_p++;
				enforce(char_p < uri.length, "Onjuiste data uri bevat geen ','");
			}
			return Base64.decode(uri[(char_p + 1) .. $]);
		} else {
			import std.uri;
			import std.file;

			string uri_decoded = dir ~ `\` ~ decode(uri);
			return cast(ubyte[]) read(uri_decoded);
		}
	}

	private ubyte[] leesKoppelingInhoud(uint koppeling_index) {
		Driehoeksnet.Koppeling koppeling = koppelingen[koppeling_index];
		ubyte[] bron = buffers_inhoud[koppeling.buffer];
		assert(koppeling.tussensprong == 0 || koppeling.tussensprong == 1,
			"Tussensprong probleem bij uitlezen van koppeling.");
		return bron[koppeling.begin .. koppeling.begin + koppeling.grootte].dup;
	}
}
