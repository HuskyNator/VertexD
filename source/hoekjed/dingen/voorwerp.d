module hoekjed.dingen.voorwerp;

import hoekjed;

class Voorwerp : Ding {
	private VAO vao;
	Verver verver;

	invariant(verver !is null);

	this(Vec!3[] plekken, Vec!(3, uint)[] volgorde, Vec!3[] normalen = null,
			Vec!2[] beeldplekken = null, Verver verver = Verver.plaatsvervanger) {
		this.vao = new VAO();

		vao.zetInhoud(0, plekken);
		if (normalen !is null)
			vao.zetInhoud(1, normalen);
		if (beeldplekken !is null)
			vao.zetInhoud(2, beeldplekken);
		vao.zetVolgorde(volgorde);

		this.verver = verver;
	}

	protected void zetUniformen() {
		verver.gebruik(); // TODO: voor de zekerheid, kan weg.
		verver.zetUniform("tekenM", tekenM); // TODO: mogelijk gekantelde
	}

	override public void teken() {
		zetUniformen();
		vao.teken();
		import std.stdio;

		auto tussen = Zicht.huidig.zichtM.maal(tekenM);
		auto na = Zicht.huidig.projectieM.maal(tussen);
		auto midden = na.maal([0, 1, 0, 1]);
		writeln(midden.toString(true));
	}

	override public void denk() {
	}
}
