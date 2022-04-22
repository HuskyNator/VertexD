module hoekjed.invoer.gltf;

import hoekjed.invoer.json;
import hoekjed.wereld;
import std.algorithm.searching : countUntil;
import std.conv : to;
import std.exception : enforce;

class GltfLezer {
	Json json;
	byte[][] buffers;

	this(string bestand) {
		this.json = JsonLezer.leesJsonBestand(bestand);
		enforce(json["asset"].voorwerp["version"].str == "2.0");
	}

	void leesMesh(string naam) {
		JsonVal[] meshlijst = json["meshes"].lijst;
		long i = meshlijst.countUntil!((a, b) => a.voorwerp["name"].str == b)(naam);
		enforce(i >= 0, "Kon mesh \"" ~ naam ~ "\" niet vinden.");
		Json mesh = meshlijst[i].voorwerp;

		enforce(mesh["primitives"].lijst.length == 1, "Enkel ondersteuning voor mesh met 1 primitief.");
		Json primitief = mesh["primitives"].lijst[0].voorwerp;

		if (JsonVal* j = "mode" in primitief)
			enforce(j.long_ == 4, "Enkel ondersteuning voor driehoeken.");

		pragma(msg, "Gltf lezer onafgewerkt.");
		assert(0, "Gltf lezer onafgewerkt.");
	}

	private void leesBuffers() {
		JsonVal[] lijst = json["buffers"].lijst;
		foreach (JsonVal buffer; lijst) {
			buffers ~= leesBuffer(buffer.voorwerp);
		}
	}

	private byte[] leesBuffer(Json buffer) {
		const long grootte = buffer["byteLength"].long_;
		byte[] b = new byte[grootte]; //PAS OP: fout in double -> long
		string uri = buffer["uri"].str;

		if (uri.length > 5 && uri[0 .. 5] == "data:") {
			b = cast(byte[]) uri[5 .. $];
		} else {
			import std.uri;
			import std.file;

			string uri_decoded = decode(uri);
			b = cast(byte[]) read(uri_decoded);
		}

		enforce(b.length == grootte, "Buffer grootte onjuist.");
		return b;
	}
}
