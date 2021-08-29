module hoekjed.dingen.ding;

import hoekjed;

struct Houding {
	Vec!3 _plek = {[0, 0, 0]};
	Vec!3 _draai = {[0, 0, 0]};
	Vec!3 _grootte = {[1, 1, 1]};
}

abstract class Ding {
	protected Wereld _wereld;
	protected Houding houding;

	protected alias houding this;

	private bool aangepast = true;
	private bool _ingeschakeld = true; // VERBETER: zoek manier om toe te passen voor elke teken/denk/werkBij stap.

	protected Mat!4 eigenM = Mat!(4).identiteit;
	protected Mat!4 tekenM = Mat!(4).identiteit;

	Ding ouder;
	Ding[] kinderen;

	@property Wereld wereld() nothrow {
		return _wereld;
	}

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

	@property bool ingeschakeld() nothrow {
		return _ingeschakeld;
	}

	@property void ingeschakeld(bool waarde) {
		_ingeschakeld = waarde;
		wereld.zetIngeschakeld(this, waarde);
		foreach (Ding kind; kinderen) {
			kind.ingeschakeld(waarde);
		}
	}

	protected abstract void denk();
	protected abstract void teken();

	public static pure Mat!4 krijgEigenM(Houding houding) {
		Mat!4 eigenM = Mat!(4).identiteit;
		eigenM[0][0] = houding._grootte.x;
		eigenM[1][1] = houding._grootte.y;
		eigenM[2][2] = houding._grootte.z;
		eigenM = Mat!(4).draaiMz(houding._draai.z).maal(Mat!(4).draaiMx(houding._draai.x)
			.maal(Mat!(4).draaiMy(houding._draai.y).maal(eigenM)));
		// [x, y, z] komen dus overeen met een [theta, psi, rho] stelsel.
		eigenM[0][3] = houding._plek.x;
		eigenM[1][3] = houding._plek.y;
		eigenM[2][3] = houding._plek.z;
		return eigenM;
	}

	protected void werkBij(bool ouderAangepast) {
		if (!ingeschakeld)
			return;

		assert(!(ouderAangepast && ouder is null)); // Kan ouder niet aanpassen als deze niet bestaat.
		bool bijgewerkt = aangepast || ouderAangepast;

		if (aangepast) {
			eigenM = Ding.krijgEigenM(this.houding);
			aangepast = false;
		}

		if (bijgewerkt)
			tekenM = (ouder is null) ? eigenM : ouder.tekenM.maal(eigenM);

		foreach (Ding kind; kinderen)
			kind.werkBij(bijgewerkt);
	}

	public void voegKind(Ding kind) {
		assert(kind !is null);
		assert(kind.ouder is null);
		kind.ouder = this;
		this.kinderen ~= kind;

		if (this._wereld !is null)
			this._wereld.voegDing(kind);
	}

	public void verwijderKind(Ding kind) {
		assert(kind !is null);
		kinderen.verwijder(kind);
		kind.ouder = null;
		if(kind._wereld !is null)
			kind._wereld.verwijderDing(kind);
	}

}
