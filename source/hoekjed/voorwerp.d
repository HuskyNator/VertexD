module hoekjed.voorwerp;
import hoekjed;
import bindbc.opengl;

struct Houding {
	Vec!3 _plek = {[0, 0, 0]};
	Vec!3 _draai = {[0, 0, 0]};
	Vec!3 _grootte = {[1, 1, 1]};
}

abstract class Voorwerp { // VOEG TOE: ouders
	protected Houding houding;
	Voorwerp ouder;
	Voorwerp[] kinderen;
	Mat!4 tekenM;
	Mat!4 erfM;
	bool aangepast = true;

	protected alias houding this;

	@property Vec!3 plek() nothrow {
		return _plek;
	}

	@property Vec!3 draai() nothrow {
		return _draai;
	}

	@property Vec!3 grootte() nothrow {
		return _grootte;
	}

	@property void plek(Vec!3 waarde) nothrow {
		_plek = waarde;
		aangepast = true;
	}

	@property void draai(Vec!3 waarde) nothrow {
		_draai = waarde;
		aangepast = true;
	}

	@property void grootte(Vec!3 waarde) nothrow {
		_grootte = waarde;
		aangepast = true;
	}

	protected abstract void _teken();
	protected abstract void _denk(Wereld wereld);

	final void teken() {
		_teken();
		foreach (Voorwerp kind; kinderen) {
			kind.teken();
		}
	}

	final void denk(Wereld wereld) {
		_denk(wereld);
		foreach (Voorwerp kind; kinderen) {
			kind.denk(wereld);
		}
	}

	void werkBij() {
		if (aangepast) {
			tekenM = Mat!(4).identiteit;
			tekenM[0][0] = _grootte.x;
			tekenM[1][1] = _grootte.y;
			tekenM[2][2] = _grootte.z;
			Mat!(4) a = Mat!(4).draaiMx(0);
			a = Mat!(4).draaiMy(0);
			a = Mat!(4).draaiMz(0);
			Mat!(4) b = Mat!(4).draaiMz(_draai.z) * tekenM;
			b = Mat!(4).draaiMx(_draai.x) * Mat!(4).draaiMz(_draai.z) * tekenM;
			tekenM = Mat!(4).draaiMy(_draai.y) * Mat!(4)
				.draaiMx(_draai.x) * Mat!(4).draaiMz(_draai.z) * tekenM; // rollen -> stampen -> gieren.
			tekenM[0][3] = _plek.x;
			tekenM[1][3] = _plek.y;
			tekenM[2][3] = _plek.z;
			if (ouder !is null)
				erfM = tekenM * ouder.erfM;
			else
				erfM = tekenM;
			aangepast = false;
		}
		foreach (Voorwerp kind; kinderen)
			kind.werkBij();
	}

}

final class DraadVoorwerp : Voorwerp { // VERBETER: algemeen voorwerp voor gegevens & zo, & losse versies hier van voor plaatsing? Of alternatief.

	uint VAO;
	uint[uint] VBO;
	uint EBO;
	Vec!(3, nauwkeurigheid)[] plekken;
	Vec!(3, nauwkeurigheid)[] normalen;
	Vec!(2, nauwkeurigheid)[] beeldplekken;
	Vec!(3, uint)[] volgorde;
	Verver verver; // VERBETER: groepeer voorwerpen met zelfde verver in lijst.
	invariant(verver !is null);

	this(Vec!(3, nauwkeurigheid)[] plekken, Vec!(3, nauwkeurigheid)[] normalen,
			Vec!(2, nauwkeurigheid)[] beeldplekken, Vec!(3, uint)[] volgorde) {
		this.plekken = plekken;
		this.normalen = normalen;
		this.beeldplekken = beeldplekken;
		this.volgorde = volgorde;
		this.verver = Verver.voorbeeld;
		glCreateVertexArrays(1, &VAO);
		glBindVertexArray(VAO);
		zetInhoud(0, plekken);
		// zetInhoud(1, normalen);
		// zetInhoud(2, beeldplekken);
		zetVolgorde(volgorde);
	}

	void zetInhoud(V : Mat!(L, 1, S), uint L, S)(uint plek, V[] inhoud)
			if (L > 0 && L <= 4) {
		static if (is(S == byte)) // VERBETER, static switch (nog) niet ondersteund, losse functie in opengl module?
			enum soort = GL_BYTE;
		else static if (is(S == ubyte))
			enum soort = GL_UNSIGNED_BYTE;
		else static if (is(S == short))
			enum soort = GL_SHORT;
		else static if (is(S == ushort))
			enum soort = GL_UNSIGNED_SHORT;
		else static if (is(S == int))
			enum soort = GL_INT;
		else static if (is(S == uint))
			enum soort = GL_UNSIGNED_INT;
		else static if (is(S == float))
			enum soort = GL_FLOAT;
		else static if (is(S == double))
			enum soort = GL_FLOAT;
		else
			static assert(0, "Soort " ~ S.stringof ~ " niet ondersteund.");

		uint vbo;
		glCreateBuffers(1, &vbo);
		VBO[plek] = vbo;
		glBindBuffer(GL_ARRAY_BUFFER, vbo);
		glBufferData(GL_ARRAY_BUFFER, inhoud.length * V.sizeof, inhoud.ptr, GL_STATIC_DRAW);
		glBindVertexArray(VAO);
		glVertexAttribPointer(plek, L, soort, false, V.sizeof, null);
		glEnableVertexAttribArray(plek);
	}

	void zetVolgorde(Vec!(3, uint)[] volgorde) {
		glBindVertexArray(VAO);
		glCreateBuffers(1, &EBO);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
		glBufferData(GL_ELEMENT_ARRAY_BUFFER,
				this.volgorde.length * 3 * uint.sizeof, this.volgorde.ptr, GL_STATIC_DRAW);
	}

	override void _teken() {
		verver.gebruik();
		verver.zetUniform("tekenM", tekenM);
		glBindVertexArray(VAO);
		glDrawElements(GL_TRIANGLES, cast(uint) (3 * volgorde.length), GL_UNSIGNED_INT, null);
	}

	override void _denk(Wereld wereld) {
	}
}
