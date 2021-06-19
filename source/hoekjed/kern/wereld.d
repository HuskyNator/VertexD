module hoekjed.kern.wereld;
import hoekjed.kern;
import std.algorithm;

import bindbc.opengl;

class Wereld {
	static Wereld[] werelden;

	Ding[] dingen;

	// Ding[] aangepast; VOEG TOE: meer optimalisatie.

	this() {
		Wereld.werelden ~= this;
	}

	void denk() {
		foreach (Ding ding; dingen)
			ding.denk(this);
		foreach (Ding ding; dingen)
			ding.werkBij(false);
	}

	void teken() {
		foreach (Ding ding; dingen)
			ding.teken();
	}
}

struct Houding {
	Vec!3 _plek = {[0, 0, 0]};
	Vec!3 _draai = {[0, 0, 0]};
	Vec!3 _grootte = {[1, 1, 1]};
}

abstract class Ding { // VOEG TOE: ouders
	protected Houding houding;
	protected alias houding this;
	Ding ouder;
	Ding[] kinderen;
	Mat!4 eigenM = Mat!(4).identiteit;
	Mat!4 tekenM = Mat!(4).identiteit;
	bool aangepast = true;

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
		// import std.math:PI;
		// static foreach(i;0..waarde.length)
		// 	if(waarde[i] > )
		_draai = waarde;
		aangepast = true;
	}

	@property void grootte(Vec!3 waarde) nothrow {
		_grootte = waarde;
		aangepast = true;
	}

	protected abstract void _teken();
	protected abstract void _denk(Wereld wereld);

	/**
	*	Tekent 
	*/
	final void teken() {
		_teken();
		foreach (Ding kind; kinderen) {
			kind.teken();
		}
	}

	final void denk(Wereld wereld) {
		_denk(wereld);
		foreach (Ding kind; kinderen) {
			kind.denk(wereld);
		}
	}

	void werkBij(bool ouderAangepast) {
		assert(!ouderAangepast || ouder !is null); // Kan ouder niet aanpassen als deze niet bestaat.
		immutable bool ruimwegAangepast = aangepast || ouderAangepast;
		if (aangepast) {
			eigenM = Mat!(4).identiteit;
			eigenM[0][0] = _grootte.x;
			eigenM[1][1] = _grootte.y;
			eigenM[2][2] = _grootte.z;
			eigenM = Mat!(4).draaiMy(_draai.y) * Mat!(4)
				.draaiMx(_draai.x) * Mat!(4).draaiMz(_draai.z) * eigenM; // rollen -> stampen -> gieren.
			eigenM[0][3] = _plek.x;
			eigenM[1][3] = _plek.y;
			eigenM[2][3] = _plek.z;
			aangepast = false;
		}

		if (ruimwegAangepast)
			tekenM = (ouder is null) ? eigenM : eigenM * ouder.tekenM;

		foreach (Ding kind; kinderen)
			kind.werkBij(ruimwegAangepast);
	}

	// Handigheden

	auto opOpAssign(string op)(Ding kind) if (op == "+") {
		assert(kind !is null);
		if (kind.ouder !is null)
			kind.ouder -= kind;
		kinderen ~= kind;
		kind.ouder = this;
		return this;
	}

	auto opOpAssign(string op)(Ding kind) if (op == "-") {
		long i = countUntil(kinderen, kind);
		assert(i >= 0, "Kind niet in kinderen.");
		kinderen = remove(kinderen, i);
		return this;
	}

}

abstract class Voorwerp : Ding { // VERBETER: algemeen ding voor gegevens & zo, & losse versies hier van voor plaatsing? Of alternatief.
	uint VAO;
	uint EBO;
	uint hoekaantal;
	uint[uint] VBO;
	Verver verver; // VERBETER: groepeer dingen met zelfde verver in lijst.
	invariant(verver !is null);

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
		this.hoekaantal = cast(uint) volgorde.length;
		glBindVertexArray(VAO);
		glCreateBuffers(1, &EBO);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
		glBufferData(GL_ELEMENT_ARRAY_BUFFER, 3 * this.hoekaantal * uint.sizeof,
				volgorde.ptr, GL_STATIC_DRAW);
	}

	override void _teken() {
		verver.gebruik();
		zetUniformen();
		tekenVAO();
	}

	void zetUniformen() {
		verver.zetUniform("tekenM", tekenM);
	}

	void tekenVAO() {
		glBindVertexArray(VAO);
		glDrawElements(GL_TRIANGLES, 3 * this.hoekaantal, GL_UNSIGNED_INT, null);
	}

	override void _denk(Wereld wereld) {
	}
}
