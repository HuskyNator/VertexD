module hoekjed.wereld.voorwerp;

import hoekjed;
import std.datetime : Duration;

struct Houding {
	Vec!3 plek = Vec!3([0, 0, 0]);
	Vec!3 draai = Vec!3([0, 0, 0]);
	Vec!3 grootte = Vec!3([1, 1, 1]);
}

class Voorwerp {
	string naam;
	Voorwerp ouder;
	Voorwerp[] kinderen;
	Houding houding;
	Driehoeksnet driehoeksnet;

	Mat!4 eigenMatrix = Mat!4(1);
	Mat!4 voorwerpMatrix = Mat!4(1);

	private bool aangepast = true;

	this(string naam, Driehoeksnet driehoeksnet = null) {
		this.naam = naam;
		this.driehoeksnet = driehoeksnet;
	}

	public @property {
		Vec!3 plek() nothrow {
			return houding.plek;
		}

		Vec!3 draai() nothrow {
			return houding.draai;
		}

		Vec!3 grootte() nothrow {
			return houding.grootte;
		}

		void plek(Vec!3 plek) nothrow {
			houding.plek = plek;
			aangepast = true;
		}

		void draai(Vec!3 draai) nothrow {
			houding.draai = draai;
			aangepast = true;
		}

		void grootte(Vec!3 grootte) nothrow {
			houding.grootte = grootte;
			aangepast = true;
		}
	}

	void teken() {
		if (driehoeksnet !is null) {
			driehoeksnet.teken(this);
		}
		foreach (Voorwerp kind; kinderen)
			kind.teken();
	}

	// abstract void denkStap(Duration deltaT);
	// TODO
	void denkStap(Duration deltaT) {
	}

	void werkEigenMatrixBij() {
		this.eigenMatrix = Mat!4();
		eigenMatrix[0][0] = houding.grootte.x;
		eigenMatrix[1][1] = houding.grootte.y;
		eigenMatrix[2][2] = houding.grootte.z;

		eigenMatrix = Mat!(4).draaiMz(houding.draai.z)
			.maal(Mat!(4).draaiMx(houding.draai.x)
					.maal(Mat!(4).draaiMy(houding.draai.y)
						.maal(eigenMatrix)));

		eigenMatrix[0][3] = houding.plek.x;
		eigenMatrix[1][3] = houding.plek.y;
		eigenMatrix[2][3] = houding.plek.z;
	}

	void werkMatrixBij(bool ouderAangepast) {
		assert(!(ouderAangepast && ouder is null));
		bool werkBij = aangepast || ouderAangepast;

		if (aangepast) {
			werkEigenMatrixBij();
			aangepast = false;
		}
		if (werkBij)
			voorwerpMatrix = (ouder is null) ? eigenMatrix : ouder.voorwerpMatrix.maal(eigenMatrix);

		foreach (Voorwerp kind; kinderen)
			kind.werkMatrixBij(werkBij);
	}

	public void voegKind(Voorwerp kind)
	in (kind !is null)
	in (kind.ouder is null) {
		kind.ouder = this;
		this.kinderen ~= kind;
	}

	public void verwijderKind(Voorwerp kind)
	in (kind !is null) {
		verwijder(kinderen, kind);
		kind.ouder = null;
	}
}
