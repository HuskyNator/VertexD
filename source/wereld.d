module wereld;
import wiskunde;
import voorwerp;

struct Houding {
	Vec!3 plek;
	Vec!3 draai;
	Vec!3 grootte;
	Mat!4 tekenM;
	bool bijgewerkt;

	void werkBij() {
		if (bijgewerkt)
			return;
		tekenM = Mat!(4).identiteit;
		tekenM[0][0] = grootte.x;
		tekenM[1][1] = grootte.y;
		tekenM[2][2] = grootte.z;
		// VOEG TOE: draai (quaternions)
		tekenM[0][3] = plek.x;
		tekenM[1][3] = plek.y;
		tekenM[2][3] = plek.z;
		bijgewerkt = true;
	}
}

class Wereld {
	Voorwerp[] voorwerpen;

	void teken() {
		// VOEG TOE
		// foreach (Voorwerp voorwerp; voorwerpen)
		// 	voorwerp.teken();
	}

}
