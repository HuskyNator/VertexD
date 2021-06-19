module hoekjed.toepassing.voorwerpen;
import hoekjed.kern;
import bindbc.opengl;

class Driehoek : SimpelVoorwerp {
	this(Vec!3[3] plekken, Vec!2[3] beeldplekken) {
		Vec!3 normaal = plekken[0].kruis(plekken[1]).normaliseer();
		Vec!3[3] normalen = [normaal, normaal, normaal];
		Vec!(3, uint)[1] volgorde = [{[0, 1, 2]}];
		super(plekken, normalen, beeldplekken, volgorde);
	}
}

class Vierkant : SimpelVoorwerp {
	this(Vec!3[4] plekken, Vec!2[4] beeldplekken) {
		Vec!3 normaal = plekken[0].kruis(plekken[1]).normaliseer();
		Vec!3[4] normalen = [normaal, normaal, normaal, normaal];
		Vec!(3, uint)[2] volgorde;
		volgorde[0] = Vec!(3, uint)([0u, 1u, 3u]);
		volgorde[1] = Vec!(3, uint)([1u, 2u, 3u]);
		super(plekken, normalen, beeldplekken, volgorde);
	}
}

class SimpelVoorwerp : Voorwerp {

	this(Vec!3[] plekken, Vec!3[] normalen, Vec!2[] beeldplekken, Vec!(3, uint)[] volgorde) {
		this.verver = Verver.voorbeeld;
		glCreateVertexArrays(1, &VAO);
		glBindVertexArray(VAO);
		zetInhoud(0, plekken);
		zetInhoud(1, normalen);
		zetInhoud(2, beeldplekken);
		zetVolgorde(volgorde);
	}
}
