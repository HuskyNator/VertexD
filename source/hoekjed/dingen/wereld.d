module hoekjed.dingen.wereld;

import hoekjed;

class Wereld {
	string naam;
	Voorwerp[] kinderen;

	public void teken(Zicht zicht) {
		foreach (Voorwerp kind; kinderen)
			kind.teken(zicht);
	}

	public void denkStap(float deltaT) {
		foreach (Voorwerp kind; kinderen)
			kind.denkStap(deltaT);
	}

	public void werkMatricesBij() {
		foreach (Voorwerp kind; kinderen)
			kind.werkMatrixBij(false);
	}
}
