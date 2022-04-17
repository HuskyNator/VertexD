module hoekjed.dingen.uiterlijk;

import hoekjed;

class Uiterlijk {
	VAO vao;
	Verver verver;
	invariant (verver !is null);

	this(VAO vao, Verver verver) {
		this.vao = vao;
		this.verver = verver;
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

	void teken(Zicht zicht, Mat!4 voorwerpMatrix) {
		zetUniformen();
		vao.teken();
	}
}
