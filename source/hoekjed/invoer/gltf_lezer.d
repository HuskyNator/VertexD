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

class GltfLezer {
	Json json;
	Wereld hoofd_wereld;
	Wereld[] werelden;
	Voorwerp[] voorwerpen;
	Materiaal[] materialen;

	Licht[] lichten;

	Buffer[] buffers;
	Driehoeksnet.Koppeling[] koppelingen;
	Driehoeksnet.Eigenschap[] eigenschappen;
	Driehoeksnet[][] driehoeksnetten;

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
			netten = this.driehoeksnetten[j.long_];

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
			JsonVal[] translatie = j.lijst;
			for (int i = 0; i < 3; i++)
				houding.plek[i] = translatie[i].double_;
		}
		if (JsonVal* j = "rotation" in voorwerp_json) {
			// TODO Quaternions
		}
		if (JsonVal* j = "scale" in voorwerp_json) {
			JsonVal[] schaal = j.lijst;
			for (int i = 0; i < 3; i++)
				houding.plek[i] = schaal[i].double_;
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

		string type = zicht_json["type"].string_;
		if (type == "perspective") {
			Json instelling = zicht_json["perspective"].voorwerp;
			nauwkeurigheid aspect = 1 / instelling["aspectRatio"].double_;

			double yfov = instelling["yfov"].double_;
			nauwkeurigheid xfov = yfov / aspect;

			nauwkeurigheid voorvlak = instelling["znear"].double_;
			nauwkeurigheid achtervlak = instelling["zfar"].double_;

			Mat!4 projectieM = Zicht.perspectiefProjectie(aspect, xfov, voorvlak, achtervlak);
			return new Zicht(projectieM);
		} else {
			enforce(type == "orthographic");
			assert(0, "Orthografisch zicht nog niet geïmplementeerd.");
			// TODO Orthografisch zicht
		}
	}

	private void leesDriehoeksnetten() {
		JsonVal[] driehoeksnetten_json = json["meshes"].lijst;
		foreach (JsonVal driehoeksnet; driehoeksnetten_json)
			driehoeksnetten ~= leesDriehoeksnet(driehoeksnet.voorwerp);
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
		Json attributen = primitief["attributes"].voorwerp;
		enforce("POSITION" in attributen && "NORMAL" in attributen,
			"Aanwezigheid van POSITION/NORMAL attributen aangenomen.");

		Driehoeksnet.Eigenschap[] net_eigenschappen;
		net_eigenschappen ~= this.eigenschappen[attributen["POSITION"].long_];
		net_eigenschappen ~= this.eigenschappen[attributen["NORMAL"].long_];
		for (uint i = 0; 16u; i++) {
			string s = "TEXCOORD_" ~ i.to!string;
			if (s !in attributen)
				break;
			net_eigenschappen ~= this.eigenschappen[attributen[s].long_];
		}

		Driehoeksnet.Koppeling[] net_koppelingen;
		uint[uint] koppelingen_vertaling;
		foreach (ref Driehoeksnet.Eigenschap eigenschap; net_eigenschappen) {
			uint i = eigenschap.koppeling;
			if (i !in koppelingen_vertaling) {
				koppelingen_vertaling[i] = cast(uint) koppelingen_vertaling.length;
				net_koppelingen ~= this.koppelingen[i];
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
			Driehoeksnet.Koppeling koppeling = this.koppelingen[eigenschap.koppeling];

			knoopindex.buffer = koppeling.buffer;
			knoopindex.knooptal = cast(int) eigenschap.elementtal;
			knoopindex.begin = cast(uint)(eigenschap.begin + koppeling.begin);
			knoopindex.soort = eigenschap.soort;
		}

		Materiaal materiaal = Gltf.standaard_materiaal;
		if (JsonVal* j = "material" in primitief)
			materiaal = this.materialen[j.long_];

		return new Driehoeksnet(naam, net_eigenschappen, net_koppelingen, knoopindex, Gltf.standaard_verver, materiaal);
	}

	private void leesMaterialen() {
		if (JsonVal* j = "materials" in json)
			foreach (JsonVal m_json; j.lijst) {
				materialen ~= leesMateriaal(m_json.voorwerp);
			}
	}

	private Materiaal leesMateriaal(Json m_json) {
		Materiaal materiaal;
		materiaal.naam = m_json.get("name", JsonVal("")).string_;

		PBR pbr = Gltf.standaard_pbr;
		if (JsonVal* pbr_jval = "pbrMetallicRoughness" in m_json) {
			Json pbr_j = pbr_jval.voorwerp;
			if (JsonVal* j = "baseColorFactor" in pbr_j)
				pbr.kleur = j.vec!(4, nauwkeurigheid);
			if (JsonVal* j = "metallicFactor" in pbr_j)
				pbr.metaal = j.double_;
			if (JsonVal* j = "roughnessFactor" in pbr_j)
				pbr.ruwheid = j.double_;
		}
		materiaal.pbr = pbr;

		// TODO Rest van materiaal
		return materiaal;
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
			assert(0, "Kon geen accessor vinden om tussensprong van koppeling#" ~ i.to!string ~ " te vinden.");
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
		eigenschap.soort = vertaalEigenschapSoort(cast(int) eigenschap_json["componentType"].long_);
		eigenschap.soorttal = vertaalEigenschapSoorttal(eigenschap_json["type"].string_);
		eigenschap.genormaliseerd = eigenschap_json.get("normalized", JsonVal(false)).bool_;
		eigenschap.elementtal = eigenschap_json["count"].long_;
		eigenschap.begin = cast(uint) eigenschap_json.get("byteOffset", JsonVal(0L)).long_;
		return eigenschap;
	}

	private void leesKoppelingen() {
		JsonVal[] koppelingen_json = json["bufferViews"].lijst;
		foreach (ulong i; 0 .. koppelingen_json.length)
			koppelingen ~= leesKoppeling(koppelingen_json[i].voorwerp, i);
	}

	private Driehoeksnet.Koppeling leesKoppeling(Json koppeling_json, ulong index) {
		Driehoeksnet.Koppeling koppeling;
		koppeling.buffer = cast(uint) buffers[koppeling_json["buffer"].long_].buffer;
		koppeling.grootte = koppeling_json["byteLength"].long_;
		koppeling.begin = koppeling_json.get("byteOffset", JsonVal(0L)).long_;
		if (JsonVal* j = "byteStride" in koppeling_json)
			koppeling.tussensprong = cast(int) j.long_;
		else
			gezochte_tussensprongen ~= index;
		return koppeling;
	}

	private void leesBuffers(string dir) {
		JsonVal[] lijst = json["buffers"].lijst;
		foreach (JsonVal buffer; lijst) {
			buffers ~= leesBuffer(buffer.voorwerp, dir);
		}
	}

	private Buffer leesBuffer(Json buffer, string dir) {
		const long grootte = buffer["byteLength"].long_;
		ubyte[] inhoud = new ubyte[grootte];
		string uri = buffer["uri"].string_;

		if (uri.length > 5 && uri[0 .. 5] == "data:") {
			import std.base64;

			uint char_p = 5;
			while (uri[char_p] != ',') {
				char_p++;
				enforce(char_p < uri.length, "Onjuiste data uri bevat geen ','");
			}
			inhoud = Base64.decode(uri[(char_p + 1) .. $]);
		} else {
			import std.uri;
			import std.file;

			string uri_decoded = dir ~ `\` ~ decode(uri);
			inhoud = cast(ubyte[]) read(uri_decoded);
		}

		enforce(inhoud.length == grootte, "Buffer grootte onjuist: "
				~ inhoud.length.to!string ~ " in plaats van " ~ grootte.to!string);
		return new Buffer(inhoud);
	}
}
