module hoekjed.dingen.wereld;

import hoekjed;

class Wereld : Ding {
	static Wereld[] werelden;
	Voorwerp[][Verver] voorwerpen;
	Ding[] dingen; // Bevat geen voorwerpen.
	Ding[] uitgeschakeld;

	this() {
		this._wereld = this;
		Wereld.werelden ~= this;
	}

	public void tekenWereld(Zicht zicht) {
		// Poging zo min mogelijk van verver te wisselen.
		this.teken();
		foreach (Verver verver; voorwerpen.byKey()) {
			verver.gebruik();
			verver.zetUniform(zicht);
			foreach (Voorwerp voorwerp; voorwerpen[verver])
				voorwerp.teken();
		}
		// VERBETER: overige dingen werken mogelijk met meerdere shaders of gebruiken andere tekenmethoden.
		foreach (Ding ding; dingen)
			ding.teken();
	}

	public void denkWereld() {
		this.denk();
		foreach (Voorwerp[] voorwerpen2; voorwerpen.values)
			foreach (Voorwerp voorwerp; voorwerpen2)
				voorwerp.denk();
		foreach (Ding ding; dingen)
			ding.denk();
	}

	public void werkWereldBij() {
		super.werkBij(false); // Werkt alles in de wereldboom bij.
	}

	public override void teken() {
	}

	public override void denk() {
	}

	package void voegDing(Ding ding) {
		assert(ding._wereld is null);
		foreach (Ding kind; ding.kinderen)
			voegDing(kind);
		ding._wereld = this;
		if (Voorwerp voorwerp = cast(Voorwerp) ding) {
			voorwerpen[voorwerp.verver] ~= voorwerp;
		} else
			dingen ~= ding;
	}

	package void verwijderDing(Ding ding) {
		assert(ding._wereld is this);
		foreach (Ding kind; ding.kinderen)
			verwijderDing(kind);
		if (Voorwerp voorwerp = cast(Voorwerp) ding)
			voorwerpen[voorwerp.verver].verwijder(voorwerp);
		else
			dingen.verwijder(ding);
		ding._wereld = null;
	}

	void zetIngeschakeld(Ding ding, bool ingeschakeld) {
		if (Voorwerp voorwerp = cast(Voorwerp) ding) {
			if (ingeschakeld) {
				voorwerpen[voorwerp.verver].verwijder(voorwerp);
				uitgeschakeld ~= voorwerp;
			} else {
				uitgeschakeld.verwijder(voorwerp);
				voorwerpen[voorwerp.verver] ~= voorwerp;
			}
		} else {
			if (ingeschakeld) {
				dingen.verwijder(ding);
				uitgeschakeld ~= ding;
			} else {
				uitgeschakeld.verwijder(ding);
				dingen ~= ding;
			}
		}
	}
}
