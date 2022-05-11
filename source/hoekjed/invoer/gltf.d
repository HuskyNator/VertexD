module hoekjed.invoer.gltf;

import hoekjed.invoer.json;
import hoekjed.kern.wiskunde;
import hoekjed.opengl;
import hoekjed.wereld;
import std.algorithm.searching : countUntil;
import std.conv : to;
import std.array : array;
import std.exception : enforce;

class GltfLezer {
	Json json;
	Wereld hoofd_wereld;
	Wereld[] werelden;
	Voorwerp[] voorwerpen;

	Buffer[] buffers;
	Koppeling[] koppelingen;
	Eigenschap[] eigenschappen;
	Driehoeksnet[] driehoeksnetten;

	Zicht[] zichten;

	private ulong[] gezochte_tussensprongen;

	this(string bestand) {
		this.json = JsonLezer.leesJsonBestand(bestand);
		enforce(json["asset"].voorwerp["version"].string_ == "2.0");
		leesBuffers();
		leesKoppelingen();
		leesEigenschappen();
		zoekTussensprongen();

		leesMaterialen(); // TODO
		leesDriehoeksnetten();
		leesZichten();
		leesVoorwerpen();
		leesWerelden();
	}

	private void leesWerelden() {
		JsonVal[] werelden_json = json["scenes"].lijst;
		foreach (JsonVal wereld; werelden_json)
			werelden ~= leesWereld(wereld.voorwerp);

		if ("scene" in json)
			hoofd_wereld = werelden[json["scene"].long_];
		else
			hoofd_wereld = null;
	}

	private Wereld leesWereld(Json wereld_json) {
		string naam = wereld_json["name"].string_;
		Wereld wereld = new Wereld(naam);
		JsonVal[] kinderen = wereld_json["nodes"].lijst;
		foreach (JsonVal kind; kinderen)
			wereld.kinderen ~= voorwerpen[kind.long_];
		return wereld;
	}

	private void leesVoorwerpen() {
		JsonVal[] voorwerpen_json = json["nodes"].lijst;
		foreach (JsonVal voorwerp; voorwerpen_json)
			voorwerpen ~= leesVoorwerp(voorwerp.voorwerp);
	}

	private Voorwerp leesVoorwerp(Json voorwerp_json) {
		string naam = "";
		if ("name" in voorwerp_json)
			naam = voorwerp_json["name"].string_;

		Driehoeksnet driehoeksnet = null;
		if ("mesh" in voorwerp_json)
			driehoeksnet = driehoeksnetten[voorwerp_json["mesh"].long_];

		Voorwerp voorwerp = new Voorwerp(naam, driehoeksnet);

		if ("camera" in voorwerp_json) {
			long z = voorwerp_json["camera"].long_;
			zichten[z].ouder = voorwerp;
		}

		if ("children" in voorwerp_json)
			foreach (JsonVal kind; voorwerp_json["children"].lijst)
				voorwerp.kinderen ~= voorwerpen[kind.long_];

		Houding houding;
		if ("translation" in voorwerp_json) {
			JsonVal[] translatie = voorwerp_json["translation"].lijst;
			for (int i = 0; i < 3; i++)
				houding.plek[i] = translatie[i].double_;
		}
		if ("rotation" in voorwerp_json) {
			// TODO Quaternions
		}
		if ("scale" in voorwerp_json) {
			JsonVal[] schaal = voorwerp_json["scale"].lijst;
			for (int i = 0; i < 3; i++)
				houding.plek[i] = schaal[i].double_;
		}

		voorwerp.houding = houding;
		return voorwerp;
	}

	private void leesZichten() {
		if ("cameras" !in json)
			return;
		JsonVal[] zichten_json = json["cameras"].lijst;
		foreach (JsonVal zicht; zichten_json)
			zichten ~= leesZicht(zicht.voorwerp);
	}

	private Zicht leesZicht(Json zicht_json) {
		string naam = "";
		if ("name" in zicht_json)
			naam = zicht_json["name"].string_;

		string type = zicht_json["type"].string_;
		if (type == "perspective") {
			Json instelling = zicht_json["perspective"].voorwerp;
			nauwkeurigheid aspect = 1 / instelling["aspectRatio"].double_;

			double yfov = instelling["yfov"].double_;
			nauwkeurigheid xfov = yfov / aspect;

			nauwkeurigheid voorvlak = instelling["znear"].double_;
			nauwkeurigheid achtervlak = instelling["zfar"].double_;

			Mat!4 projectieM = Zicht.perspectiefProjectie(aspect, xfov, voorvlak, achtervlak);
			return new Zicht(naam, projectieM, null);
		} else {
			enforce(type == "orthographic");
			assert(0, "Orthografisch zicht nog niet geïmplementeerd.");
			// TODO
		}
	}

	private void leesMaterialen() {
		// TODO
	}

	private void leesDriehoeksnetten() {
		JsonVal[] driehoeksnetten_json = json["meshes"].lijst;
		foreach (JsonVal driehoeksnet; driehoeksnetten_json)
			driehoeksnetten ~= leesDriehoeksnet(driehoeksnet.voorwerp);
	}

	private Driehoeksnet leesDriehoeksnet(Json driehoeksnet_json) {
		string naam = driehoeksnet_json.get("name", JsonVal("")).string_;

		if (driehoeksnet_json["primitives"].lijst.length > 1)
			assert(0, "Ondersteuning voor meerdere primitieven niet geïmplementeerd.");

		Json primitief = driehoeksnet_json["primitives"].lijst[0].voorwerp;
		Json attributen = primitief["attributes"].voorwerp;
		enforce("POSITION" in attributen && "NORMAL" in attributen, "Aanwezigheid van POSITION/NORMAL attributen aangenomen.");

		Eigenschap[] net_eigenschappen;
		net_eigenschappen ~= this.eigenschappen[attributen["POSITION"].long_];
		net_eigenschappen ~= this.eigenschappen[attributen["NORMAL"].long_];
		for (uint i = 0; uint.max; i++) {
			string s = "TEXCOORD_" ~ i.to!string;
			if (s !in attributen)
				break;
			net_eigenschappen ~= this.eigenschappen[attributen[s].long_];
		}

		Koppeling[] net_koppelingen;
		uint[uint] koppelingen_vertaling;
		foreach (ref Eigenschap eigenschap; net_eigenschappen) {
			uint i = eigenschap.koppeling;
			if (i !in koppelingen_vertaling) {
				koppelingen_vertaling[i] = cast(uint) koppelingen_vertaling.length;
				net_koppelingen ~= this.koppelingen[i];
			}
			eigenschap.koppeling = koppelingen_vertaling[i];
		}

		Knoopindex knoopindex;
		if ("indices" !in primitief) {
			knoopindex.buffer.nullify();
			knoopindex.knooptal = cast(int) net_eigenschappen[0].elementtal;
			knoopindex.begin = 0;
		} else {
			Eigenschap eigenschap = this.eigenschappen[primitief["indices"].long_];
			Koppeling koppeling = this.koppelingen[eigenschap.koppeling];

			knoopindex.buffer = koppeling.buffer;
			knoopindex.knooptal = cast(int) eigenschap.elementtal;
			knoopindex.begin = cast(uint)(eigenschap.begin + koppeling.begin);
			knoopindex.soort = eigenschap.soort;
		}

		return new Driehoeksnet(naam, net_eigenschappen, net_koppelingen, knoopindex);
	}

	private void zoekTussensprongen() {
		Tussensprong: foreach (ulong i; 0 .. gezochte_tussensprongen.length) {
			foreach (Eigenschap e; eigenschappen) {
				if (e.koppeling != i)
					continue;
				koppelingen[i].tussensprong = cast(int) bepaalTussensprong(e);
				continue Tussensprong;
			}
			assert(0, "Kon geen accessor vinden om tussensprong van koppeling#" ~ i.to!string ~ " te vinden.");
		}
	}

	private size_t bepaalTussensprong(Eigenschap e) {
		return e.soorttal * eigenschapSoortGrootte(e.soort);
	}

	import bindbc.opengl : GLenum;

	private size_t eigenschapSoortGrootte(GLenum soort) {
		import bindbc.opengl;

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
		import bindbc.opengl;

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

	private Eigenschap leesEigenschap(Json eigenschap_json) {
		Eigenschap eigenschap;
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

	private Koppeling leesKoppeling(Json koppeling_json, ulong index) {
		Koppeling koppeling;
		koppeling.buffer = cast(uint) buffers[koppeling_json["buffer"].long_].buffer;
		koppeling.grootte = koppeling_json["byteLength"].long_;
		koppeling.begin = koppeling_json.get("byteOffset", JsonVal(0L)).long_;
		if ("byteStride" in koppeling_json)
			koppeling.tussensprong = cast(int) koppeling_json["byteStride"].long_;
		else
			gezochte_tussensprongen ~= index;
		return koppeling;
	}

	private void leesBuffers() {
		JsonVal[] lijst = json["buffers"].lijst;
		foreach (JsonVal buffer; lijst) {
			buffers ~= leesBuffer(buffer.voorwerp);
		}
	}

	private Buffer leesBuffer(Json buffer) {
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

			string uri_decoded = decode(uri);
			inhoud = cast(ubyte[]) read(uri_decoded);
		}

		enforce(inhoud.length == grootte, "Buffer grootte onjuist: "
				~ inhoud.length.to!string ~ " in plaats van " ~ grootte.to!string);
		return new Buffer(inhoud);
	}
}
