module hoekjed.net.net;

import bindbc.opengl;
import hoekjed.ververs.materiaal;
import hoekjed.ververs.verver;
import hoekjed.wereld.voorwerp;
import std.conv : to;
import std.stdio : writeln;
import std.typecons : Nullable;

final class Driehoeksnet {
	struct Eigenschap {
		uint koppeling;
		GLenum soort;
		ubyte soorttal; // 1-4 / 9 / 16
		bool matrix;
		bool genormaliseerd;
		size_t elementtal;
		uint begin;
	}

	struct Koppeling {
		uint buffer;
		size_t grootte; // bytes
		size_t begin; // bytes
		int tussensprong; //bytes
	}

	struct Knoopindex {
		Nullable!uint buffer;
		int knooptal;
		int begin; // bytes
		GLenum soort; // ubyte/ushort/uint
	}

	string naam;
	private uint vao;
	private Knoopindex knoopindex;
	Verver verver;
	Materiaal materiaal;

	public this(string naam, Eigenschap[] eigenschappen, Koppeling[] koppelingen,
		Knoopindex knoopindex, Verver verver, Materiaal materiaal) {
		this.naam = naam;
		this.verver = verver;
		this.materiaal = materiaal;

		glCreateVertexArrays(1, &vao);
		writeln("Driehoeksnet aangemaakt: " ~ vao.to!string);

		for (uint i = 0; i < eigenschappen.length; i++) {
			Eigenschap e = eigenschappen[i];
			glEnableVertexArrayAttrib(vao, i);
			glVertexArrayAttribFormat(vao, i, e.soorttal, e.soort, e.genormaliseerd, e.begin);
			glVertexArrayAttribBinding(vao, i, e.koppeling);
		}

		for (uint i = 0; i < koppelingen.length; i++) {
			Koppeling k = koppelingen[i];
			assert(k.tussensprong > 0,
				"Tussensprong moet hoger dan 0 zijn maar was: " ~ k.tussensprong.to!string);
			glVertexArrayVertexBuffer(vao, i, k.buffer, k.begin, k.tussensprong);
		}

		this.knoopindex = knoopindex;
		if (!knoopindex.buffer.isNull())
			glVertexArrayElementBuffer(vao, knoopindex.buffer.get());
	}

	~this() {
		import core.stdc.stdio : printf;

		glDeleteVertexArrays(1, &vao);
		printf("Driehoeksnet verwijderd: %u\n", vao);
	}

	public void teken(Voorwerp voorwerp) {
		verver.gebruik();
		verver.zetUniform("voorwerpM", voorwerp.voorwerpMatrix);
		glBindVertexArray(vao);
		if (knoopindex.buffer.isNull())
			glDrawArrays(GL_TRIANGLES, knoopindex.begin, knoopindex.knooptal);
		else
			glDrawElements(GL_TRIANGLES, knoopindex.knooptal, knoopindex.soort, cast(void*) knoopindex
					.begin);
	}
}
