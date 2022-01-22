module hoekjed.dingen.voorwerp;

import hoekjed;

class Voorwerp : Ding {
	protected VAO vao;
	Verver verver; // TODO: Moet bescherm worden, aangezien Wereld het gebruikt als sleutel.

	invariant (verver !is null);

	this(Voorwerp uiterlijk) {
		this.vao = uiterlijk.vao;
		this.verver = uiterlijk.verver;
	}

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
		verver.zetUniform("tekenM", tekenM);
	}

	override public void teken() {
		zetUniformen();
		vao.teken();
	}

	override public void denk() {
	}
}
