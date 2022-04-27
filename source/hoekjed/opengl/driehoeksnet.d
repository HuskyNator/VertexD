module hoekjed.opengl.driehoeksnet;

import bindbc.opengl;
import hoekjed;
import std.typecons : Nullable;

struct Eigenschap {
	uint koppeling;
	GLenum soort;
	ubyte soorttal; // 1-4
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
}

final class Driehoeksnet {
	string naam;
	private uint vao;
	private Knoopindex knoopindex;
	Verver verver;

	public this(string naam, Eigenschap[] eigenschappen, Koppeling[] koppelingen,
		Knoopindex knoopindex, Verver verver = Verver.plaatsvervanger) {
		this.naam = naam;
		this.verver = verver;

		glCreateVertexArrays(1, &vao);

		for (uint i = 0; i < eigenschappen.length; i++) {
			Eigenschap e = eigenschappen[i];
			glEnableVertexArrayAttrib(vao, i);
			glVertexArrayAttribFormat(vao, i, e.soorttal, e.soort, e.genormaliseerd, e.begin);
			glVertexArrayAttribBinding(vao, i, e.koppeling);
		}

		for (uint i = 0; i < koppelingen.length; i++) {
			Koppeling k = koppelingen[i];
			glVertexArrayVertexBuffer(vao, i, k.buffer, k.begin, k.tussensprong);
		}

		this.knoopindex = knoopindex;
		if (!knoopindex.buffer.isNull())
			glVertexArrayElementBuffer(vao, knoopindex.buffer.get());
	}

	~this() {
		glDeleteVertexArrays(1, &vao);
	}

	public void teken(Voorwerp voorwerp) {
		verver.zetUniform(voorwerp);
		glBindVertexArray(vao);
		if (knoopindex.buffer.isNull())
			glDrawArrays(GL_TRIANGLES, knoopindex.begin, knoopindex.knooptal);
		else
			glDrawElements(GL_TRIANGLES, knoopindex.knooptal, GL_UNSIGNED_INT, cast(void*)knoopindex.begin);
	}
}
