module venster;
import wiskunde;
import wereld;
import zicht;

struct Venster {
	Vec!2 hoek;
	int breedte;
	int hoogte;
	Scherm scherm;

	void teken() {
		scherm.teken();
	}

	// VOEG TOE: glfw mogelijkheden, zoals openen/sluiten/focus/muis/toetsen (toetsen per scherm of venster?)
}

struct Scherm {
	Vec!(2, int) hoek;
	int breedte;
	int hoogte;
	Scherm[] deelschermen;
	Zicht zicht;

	void teken() {
		import bindbc.opengl;

		glClear(GL_COLOR_BUFFER_BIT); // Verschoont het scherm.
		foreach (Scherm scherm; deelschermen)
			scherm.teken();
		if (zicht !is null) {
			glViewport(hoek.x, hoek.y, breedte, hoogte); // Zet het tekengebied.
			glClear(GL_DEPTH_BUFFER_BIT); // Zorgt dat alles boven de rest getekend wordt.
			zicht.teken();
		}
	}
}
