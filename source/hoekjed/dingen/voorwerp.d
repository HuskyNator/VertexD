module hoekjed.dingen.voorwerp;

import hoekjed;

struct Houding {
	Vec!3 plek = Vec!3([0, 0, 0]);
	Vec!3 draai = Vec!3([0, 0, 0]);
	Vec!3 grootte = Vec!3([1, 1, 1]);
}

abstract class Voorwerp {
	Voorwerp ouder;
	Voorwerp[] kinderen;
	Houding houding;
	Uiterlijk uiterlijk;

	Mat!4 eigenMatrix = Mat!4(1);
	Mat!4 voorwerpMatrix = Mat!4(1);

	private bool aangepast = true;

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

	void teken(Zicht zicht) {
		if (uiterlijk !is null)
			uiterlijk.teken(zicht, voorwerpMatrix);
		foreach (Voorwerp kind; kinderen)
			kind.teken(zicht);
	}

	abstract void denkStap(float deltaT);

	static pure Mat!4 krijgEigenMatrix(Houding houding) {
		Mat!4 eigenMatrix = Mat!4(1);
		eigenMatrix[0][0] = houding.grootte.x;
		eigenMatrix[1][1] = houding.grootte.y;
		eigenMatrix[2][2] = houding.grootte.z;

		eigenMatrix = Mat!(4).draaiMz(houding.draai.z).maal(Mat!(4)
				.draaiMx(houding.draai.x)
				.maal(Mat!(4).draaiMy(houding.draai.y).maal(eigenMatrix)));

		eigenMatrix[0][3] = houding.plek.x;
		eigenMatrix[1][3] = houding.plek.y;
		eigenMatrix[2][3] = houding.plek.z;
		return eigenMatrix;
	}

	void werkMatrixBij(bool ouderAangepast) {
		assert(!(ouderAangepast && ouder is null));
		bool werkBij = aangepast || ouderAangepast;

		if (aangepast) {
			eigenMatrix = Voorwerp.krijgEigenMatrix(this.houding);
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
