module hoekjed.venster;
import hoekjed;
import bindbc.glfw;
import bindbc.opengl;
import std.conv : to;
import std.container.rbtree;

private extern (C) void venster_grootte_terugroeper(GLFWwindow* glfw_venster, int breedte,
		int hoogte) nothrow {
	Venster venster = Venster.vensters[glfw_venster];
	venster.breedte = breedte;
	venster.hoogte = hoogte;
	venster.hervorm();
}

private extern (C) void venster_toets_terugroeper(GLFWwindow* glfw_venster,
		int toets, int toets_sleutel, int gebeurtenis, int toevoeging) nothrow {
	Venster venster = Venster.vensters[glfw_venster];
	ToetsInvoer invoer = ToetsInvoer(venster, toets, toets_sleutel, gebeurtenis, toevoeging);
	Venster.invoer ~= invoer;
	foreach (ToetsTerugroeper terugroeper; Venster.toetsTerugroepers[glfw_venster]) {
		terugroeper(invoer);
	}
	if (toets == GLFW_KEY_F4)
		glfwSetWindowShouldClose(glfw_venster, true);
}

struct ToetsInvoer {
	Venster venster;
	int toets, toets_sleutel, gebeurtenis, toevoeging;
}

alias ToetsTerugroeper = void delegate(ToetsInvoer invoer) nothrow;

class Venster {
	static package Venster[GLFWwindow* ] vensters;
	static package ToetsTerugroeper[][GLFWwindow* ] toetsTerugroepers;
	static package ToetsInvoer[] invoer;

	string naam;
	int breedte;
	int hoogte;
	Scherm scherm;
	package GLFWwindow* glfw_venster;

	alias scherm this;

	static void zetStandaardZichtbaar(bool zichtbaar) {
		glfwWindowHint(GLFW_VISIBLE, zichtbaar);
	}

	static void zetStandaardRand(bool rand) {
		glfwWindowHint(GLFW_DECORATED, rand);
	}

	static void zetStandaardDoorzichtig(bool doorzichtig) {
		glfwWindowHint(GLFW_TRANSPARENT_FRAMEBUFFER, doorzichtig);
	}

	this(string naam = "HoekjeD", int glfw_breedte = 1920 / 2, int glfw_hoogte = 1080 / 2) {
		this.glfw_venster = glfwCreateWindow(glfw_breedte, glfw_hoogte, naam.ptr, null, null);
		assert(glfw_venster !is null, "GLFW kon geen scherm aanmaken.");
		Venster.vensters[glfw_venster] = this;
		glfwMakeContextCurrent(glfw_venster); // PAS OP: Moet voor multithreading & meerdere vensters nog een oplossing vinden.

		glfwSetKeyCallback(glfw_venster, &venster_toets_terugroeper);
		glfwSetWindowSizeCallback(glfw_venster, &venster_grootte_terugroeper);

		this.naam = naam;
		glfwGetFramebufferSize(glfw_venster, &breedte, &hoogte);
		this.scherm = Scherm();
		this.scherm.hervorm(Vec!(2, int)([0, 0]), Vec!(2, int)([breedte, hoogte]));

		glfwSetFramebufferSizeCallback(glfw_venster, &venster_grootte_terugroeper);

		GLSupport gl_versie = loadOpenGL();
		assert(gl_versie == GLSupport.gl46, "GL laadt niet: " ~ gl_versie.to!string);
		// VOEG TOE: opengl foutterugroeper.
	}

	void toon() {
		glfwShowWindow(glfw_venster);
		glClearColor(0, 0, 0.5, 0.1);
		glClear(GL_COLOR_BUFFER_BIT);
		glfwSwapBuffers(glfw_venster);
	}

	void verstop() {
		glfwHideWindow(glfw_venster);
	}

	void teken() {
		glViewport(0, 0, breedte, hoogte); // Zet het tekengebied.
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT); // Verschoont het scherm.
		scherm.teken();

		// VOEG TOE:
		// Hebben een beter denksysteem nodig. Per voorwerp of/en ook per scherm.
		// VOEG TOE: alle denk functies in een globale lijst, voorkomt herhaalde instructies & maakt
		// het mogelijk de "bijgewerkt" te verwijderen en "werkBij" sneller te maken door veranderde
		// voorwerpen in een globale set te plaatsen & hun en hun kinderen specifiek bij te werken.

		// Mogelijk is het beter dit niet blobaal te doen maar per wereld, met werelden in een
		// globale lijst, omdat het zo eenvoudiger is een wereld te pauzeren.

		// Kan net als veel motoren voorwerpen eigenschappen geven opdat het uitschakelen van een
		// voorwerp bijvoorbeeld eenvoudig door te voeren is naar het verwijderen van zijn denk opdracht(en).
		glfwSwapBuffers(glfw_venster);
	}

	void voegToetsTerugroeperToe(ToetsTerugroeper toetsTerugroeper) {
		Venster.toetsTerugroepers[glfw_venster] ~= toetsTerugroeper;
	}

	unittest {
		import hoekjed;

		hdZetOp();
		Venster.zetStandaardDoorzichtig(true);

		bool called = false;
		ToetsTerugroeper foo = (Venster venster, int toets, int toets_sleutel,
				int gebeurtenis, int toevoeging) { called = true; };
		Venster venster = new Venster();
		venster.voegToetsTerugroeperToe(foo);

		Venster.toetsTerugroepers[venster.glfw_venster][0](venster, 0, 0, 0, 0);
		assert(called);

		import core.time;
		import core.thread;

		venster.toon();
		Thread.sleep(dur!("seconds")(10));
	}

	// VOEG TOE: glfw mogelijkheden, zoals openen/sluiten/focus/muis/toetsen (toetsen per scherm of venster?)

	protected void hervorm() nothrow {
		Vec!(2, int) lb = {[0, 0]};
		Vec!(2, int) grootte = {[breedte, hoogte]};
		scherm.hervorm(lb, grootte);
	}

	unittest {
		import hoekjed;

		hdZetOp();
		Venster.zetStandaardZichtbaar(false);
		Venster venster = new Venster();
		Vec!(2, int) ro = venster.scherm.rechtsonder;
		venster.breedte *= 2;
		venster.hervorm();
		Vec!(2, int) ro2 = venster.scherm.rechtsonder;
		assert(ro2.x == 2 * ro.x && ro2.y == ro.y,
				"[2 * " ~ ro.x.to!string ~ ", " ~ ro.y.to!string ~ "] != " ~ ro2.to!string);
	}
}

struct Scherm {
	Vec!2 linksboven_f = {[0, 0]};
	Vec!2 rechtsonder_f = {[1, 1]};
	Vec!(2, int) linksboven;
	Vec!(2, int) rechtsonder;

	Scherm[] deelschermen;
	Wereld wereld;
	Zicht zicht; // In principe kan deze uit een andere wereld komen. . . Parallele werelden?

	void teken() {
		foreach (Scherm scherm; deelschermen)
			scherm.teken();
		if (zicht is null)
			return;
		glViewport(linksboven.x, linksboven.y, rechtsonder.x, rechtsonder.y); // Zet het tekengebied.
		if (deelschermen.length != 0)
			glClear(GL_DEPTH_BUFFER_BIT); // Over deelscherm heen tekenen.

		zicht.teken(wereld);
	}

	protected void hervorm(Vec!(2, int) lb, Vec!(2, int) grootte) nothrow {
		linksboven = lb + cast(Vec!(2, int))(linksboven_f * grootte);
		rechtsonder = lb + cast(Vec!(2, int))(rechtsonder_f * grootte);
		if (deelschermen.length != 0) {
			Vec!(2, int) eigen_grootte = rechtsonder - linksboven;
			foreach (Scherm scherm; deelschermen) {
				scherm.hervorm(linksboven, eigen_grootte);
			}
		}
	}

	unittest {
		Scherm s = {rechtsonder_f: {[0.25, 0.5]}};
		Vec!(2, int) a = {[5, 5]};
		Vec!(2, int) b = {[1, 2]};
		s.hervorm(a, b);
		assert(s.rechtsonder.x == 5 && s.rechtsonder.y == 6);
	}
}
