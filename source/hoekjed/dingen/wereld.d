module hoekjed.dingen.wereld;

import hoekjed;

class Wereld : Ding {
	static Wereld[] werelden;
	Voorwerp[][Verver] voorwerpen;
	Ding[] dingen; // Bevat geen voorwerpen.

	this() {
		this._wereld = this;
		Wereld.werelden ~= this;
	}

	public override void teken() {
		// Poging zo min mogelijk van verver te wisselen.
		foreach (Verver verver; voorwerpen.byKey()) {
			verver.gebruik();
			foreach (Voorwerp voorwerp; voorwerpen[verver])
					voorwerp.teken();
		}
		// VERBETER: overige dingen werken mogelijk met meerdere shaders of gebruiken andere tekenmethoden.
		foreach (Ding ding; dingen)
			ding.teken();
	}

	public override void denk() {
		foreach (Voorwerp[] voorwerpen2; voorwerpen.values)
			foreach (Voorwerp voorwerp; voorwerpen2)
				voorwerp.denk();
		foreach (Ding ding; dingen)
			ding.denk();
	}

	public void werkBij() {
		super.werkBij(false); // Werkt alles in de wereldboom bij.
	}

	package void voegDing(Ding ding) {
		assert(ding._wereld is null);
		ding._wereld = this;
		if (Voorwerp voorwerp = cast(Voorwerp) ding) {
			// if ((voorwerp.verver in this.voorwerpen) is null)
			// 	voorwerpen[voorwerp.verver] = new Voorwerp[];
			voorwerpen[voorwerp.verver] ~= voorwerp;
		} else
			dingen ~= ding;
	}

	package void verwijderDing(Ding ding) {
		assert(ding._wereld is this);
		if (Voorwerp voorwerp = cast(Voorwerp) ding)
			voorwerpen[voorwerp.verver].verwijder(voorwerp);
		else
			dingen.verwijder(ding);
		ding._wereld = null;
	}
}
