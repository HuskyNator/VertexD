module hoekjed.wereld.voorwerp;

import hoekjed.kern.wiskunde;
import hoekjed.kern.quaternions;
import hoekjed.driehoeksnet.driehoeksnet;
import hoekjed.wereld.wereld;
import hoekjed.overig;
import std.datetime : Duration;

struct Houding {
	Vec!3 plek = Vec!3([0, 0, 0]);
	// Vec!3 draai = Vec!3([0, 0, 0]);
	Quat draai = Quat(1.0f, 0.0f, 0.0f, 0.0f);
	Vec!3 grootte = Vec!3([1, 1, 1]);
}

class Voorwerp {
	interface Eigenschap {
		void werkBij(Wereld wereld, Voorwerp ouder);
	}

	string naam;
	Voorwerp ouder;
	Voorwerp[] kinderen = [];
	Houding houding;
	Driehoeksnet[] driehoeksnetten;

	Eigenschap[] eigenschappen = [];

	Mat!4 eigenMatrix = Mat!4(1);
	Mat!4 voorwerpMatrix = Mat!4(1);

	private bool aangepast = true;

	this(string naam, Driehoeksnet[] driehoeksnetten = []) {
		this.naam = naam;
		this.driehoeksnetten = driehoeksnetten;
	}

	public @property {
		Vec!3 plek() nothrow {
			return houding.plek;
		}

		Quat draai() nothrow {
			return houding.draai;
		}

		Vec!3 grootte() nothrow {
			return houding.grootte;
		}

		void plek(Vec!3 plek) nothrow {
			houding.plek = plek;
			aangepast = true;
		}

		void draai(Quat draai) nothrow {
			houding.draai = draai;
			aangepast = true;
		}

		void grootte(Vec!3 grootte) nothrow {
			houding.grootte = grootte;
			aangepast = true;
		}
	}

	void teken() {
		foreach (Driehoeksnet net; driehoeksnetten) {
			net.verver.zetUniform("u_kleur", net.materiaal.pbr.kleur);
			net.teken(this);
		}
		foreach (Voorwerp kind; kinderen)
			kind.teken();
	}

	// TODO
	void denkStap(Duration deltaT) {
		foreach (Voorwerp kind; kinderen) {
			kind.denkStap(deltaT);
		}
	}

	void werkEigenMatrixBij() {
		this.eigenMatrix = Mat!4();
		eigenMatrix[0][0] = houding.grootte.x;
		eigenMatrix[1][1] = houding.grootte.y;
		eigenMatrix[2][2] = houding.grootte.z;
		eigenMatrix[3][3] = 1;

		eigenMatrix = draai.naarMat!4() ^ eigenMatrix;

		eigenMatrix[0][3] = houding.plek.x;
		eigenMatrix[1][3] = houding.plek.y;
		eigenMatrix[2][3] = houding.plek.z;
	}

	void werkBij(Wereld wereld, bool ouderAangepast) {
		assert(!(ouderAangepast && ouder is null));
		bool werkBij = aangepast || ouderAangepast;

		if (aangepast)
			werkEigenMatrixBij();
		if (werkBij) {
			voorwerpMatrix = (ouder is null) ? eigenMatrix : ouder.voorwerpMatrix.maal(eigenMatrix);
			foreach (Voorwerp.Eigenschap e; eigenschappen)
				e.werkBij(wereld, this);
		}

		foreach (Voorwerp kind; kinderen)
			kind.werkBij(wereld, werkBij);

		aangepast = false;
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
