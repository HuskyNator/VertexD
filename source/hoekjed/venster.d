module hoekjed.venster;
import hoekjed;
import bindbc.glfw;
import bindbc.opengl;
import std.conv : to;
import std.container.rbtree;

struct ToetsInvoer {
	int toets, toets_sleutel, gebeurtenis, toevoeging;
}

struct MuisknopInvoer {
	int knop, gebeurtenis, toevoeging;
}

struct MuisplekInvoer {
	double x, y;
}

struct MuiswielInvoer {
	double x, y;
}

alias ToetsTerugroeper = void delegate(ToetsInvoer invoer) nothrow;
alias MuisknopTerugroeper = void delegate(MuisknopInvoer invoer) nothrow;
alias MuisplekTerugroeper = void delegate(MuisplekInvoer invoer) nothrow;
alias MuiswielTerugroeper = void delegate(MuiswielInvoer invoer) nothrow;

enum Muissoort {
	NORMAAL = GLFW_CURSOR_NORMAL,
	GEVANGEN = GLFW_CURSOR_DISABLED,
	ONZICHTBAAR = GLFW_CURSOR_HIDDEN
}

class Venster {
	static package Venster[GLFWwindow* ] vensters;
	package GLFWwindow* glfw_venster;

	// Eigenschappen
	string naam;
	int breedte, hoogte;
	Scherm scherm;

	// Invoer
	ToetsTerugroeper[] toetsTerugroepers = [];
	MuisknopTerugroeper[] muisknopTerugroepers = [];
	MuisplekTerugroeper[] muisplekTerugroepers = [];
	MuiswielTerugroeper[] muiswielTerugroepers = [];
	ToetsInvoer[] toetsInvoer = [];
	MuisplekInvoer[] muisplekInvoer = [];
	MuisknopInvoer[] muisknopInvoer = [];
	MuiswielInvoer[] muiswielInvoer = [];

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

	void zetAchtergrondKleur(Vec!(4, float) kleur) {
		glClearColor(kleur.x, kleur.y, kleur.z, kleur.w);
	}

	void zetMuissoort(Muissoort soort) {
		glfwSetInputMode(glfw_venster, GLFW_CURSOR, soort);
	}

	this(string naam = "HoekjeD", int glfw_breedte = 1920 / 2, int glfw_hoogte = 1080 / 2) {
		debug glfwWindowHint(GLFW_OPENGL_DEBUG_CONTEXT, true);

		this.glfw_venster = glfwCreateWindow(glfw_breedte, glfw_hoogte, naam.ptr, null, null);
		assert(glfw_venster !is null, "GLFW kon geen scherm aanmaken.");

		Venster.vensters[glfw_venster] = this;
		glfwMakeContextCurrent(glfw_venster); // PAS OP: Moet voor multithreading & meerdere vensters nog een oplossing vinden.

		glfwSetKeyCallback(glfw_venster, &venster_toets_terugroeper);
		glfwSetMouseButtonCallback(glfw_venster, &venster_muisknop_terugroeper);
		glfwSetCursorPosCallback(glfw_venster, &venster_muisplek_terugroeper);
		glfwSetScrollCallback(glfw_venster, &venster_muiswiel_terugroeper);
		// glfwSetWindowSizeCallback(glfw_venster, &venster_grootte_terugroeper);
		glfwSetFramebufferSizeCallback(glfw_venster, &venster_grootte_terugroeper);

		this.naam = naam;
		glfwGetFramebufferSize(glfw_venster, &breedte, &hoogte);
		this.scherm = Scherm();
		this.scherm.hervorm(Vec!(2, int)([0, 0]), Vec!(2, int)([breedte, hoogte]));


		GLSupport gl_versie = loadOpenGL();
		assert(gl_versie == GLSupport.gl46, "GL laadt niet: " ~ gl_versie.to!string);

		debug {
			glEnable(GL_DEBUG_OUTPUT);
			glDebugMessageCallback(&gl_fout_terugroeper, null);
			glDebugMessageControl(GL_DONT_CARE, GL_DONT_CARE,
					GL_DEBUG_SEVERITY_NOTIFICATION, 0, null, false);
		}
	}

	void toon() {
		glfwShowWindow(glfw_venster);
		glClear(GL_COLOR_BUFFER_BIT);
		glfwSwapBuffers(glfw_venster);
	}

	void verstop() {
		glfwHideWindow(glfw_venster);
	}

	void verwerkInvoer() {
		// Behoudt volgorde van invoer over alle terugroepers.
		foreach (ToetsInvoer invoer; toetsInvoer)
			foreach (ToetsTerugroeper terugroeper; toetsTerugroepers)
				terugroeper(invoer);

		foreach (MuisknopInvoer invoer; muisknopInvoer)
			foreach (MuisknopTerugroeper terugroeper; muisknopTerugroepers)
				terugroeper(invoer);

		foreach (MuisplekInvoer invoer; muisplekInvoer)
			foreach (MuisplekTerugroeper terugroeper; muisplekTerugroepers)
				terugroeper(invoer);

		foreach (MuiswielInvoer invoer; muiswielInvoer)
			foreach (MuiswielTerugroeper terugroeper; muiswielTerugroepers)
				terugroeper(invoer);

		//PAS OP: neemt onafhankelijkheid van muis & toets volgorde aan op korte tijdsverschillen.
	}

	void leegInvoer() {
		toetsInvoer = [];
		muisknopInvoer = [];
		muisplekInvoer = [];
		muiswielInvoer = [];
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

extern (C) void venster_grootte_terugroeper(GLFWwindow* glfw_venster, int breedte, int hoogte) nothrow {
	Venster venster = Venster.vensters[glfw_venster];
	venster.breedte = breedte;
	venster.hoogte = hoogte;
	venster.hervorm();
}

extern (C) void venster_toets_terugroeper(GLFWwindow* glfw_venster, int toets,
		int toets_sleutel, int gebeurtenis, int toevoeging) nothrow {
	debug {
		import core.sys.windows.windows;

		if (toets == GLFW_KEY_GRAVE_ACCENT) {
			ShowWindow(console, console_zichtbaar ? SW_HIDE : SW_RESTORE);
			glfwFocusWindow(glfw_venster);
			console_zichtbaar = !console_zichtbaar;
		}
	}
	if (toets == GLFW_KEY_F4)
		glfwSetWindowShouldClose(glfw_venster, true);

	Venster venster = Venster.vensters[glfw_venster];
	ToetsInvoer invoer = ToetsInvoer(toets, toets_sleutel, gebeurtenis, toevoeging);
	venster.toetsInvoer ~= invoer;
}

extern (C) void venster_muisknop_terugroeper(GLFWwindow* glfw_venster, int knop,
		int gebeurtenis, int toevoeging) nothrow {
	Venster venster = Venster.vensters[glfw_venster];
	MuisknopInvoer invoer = MuisknopInvoer(knop, gebeurtenis, toevoeging);
	venster.muisknopInvoer ~= invoer;
}

extern (C) void venster_muisplek_terugroeper(GLFWwindow* glfw_venster, double x, double y) nothrow {
	Venster venster = Venster.vensters[glfw_venster];
	MuisplekInvoer invoer = MuisplekInvoer(x, y);
	venster.muisplekInvoer ~= invoer;
}

extern (C) void venster_muiswiel_terugroeper(GLFWwindow* glfw_venster, double x, double y) nothrow {
	Venster venster = Venster.vensters[glfw_venster];
	MuiswielInvoer invoer = MuiswielInvoer(x, y);
	venster.muiswielInvoer ~= invoer;
}

debug {
	extern (System) void gl_fout_terugroeper(GLenum bron, GLenum soort, GLuint id,
			GLenum ernstigheid, GLsizei length, const GLchar* message, const void* userParam) nothrow {
		import std.stdio : write, writeln;
		import std.conv : to;
		import bindbc.opengl.bind.types;

		try {
			writeln("OpenGL Fout #" ~ id.to!string);
			write("\tBron: ");
			switch (bron) {
			case GL_DEBUG_SOURCE_API:
				writeln("OpenGL API");
				break;
			case GL_DEBUG_SOURCE_WINDOW_SYSTEM:
				writeln("Venster Systeem API");
				break;
			case GL_DEBUG_SOURCE_SHADER_COMPILER:
				writeln("Shader Compiler");
				break;
			case GL_DEBUG_SOURCE_THIRD_PARTY:
				writeln("Derde Partij");
				break;
			case GL_DEBUG_SOURCE_APPLICATION:
				writeln("Gebruikerscode");
				break;
			case GL_DEBUG_SOURCE_OTHER:
				writeln("Overig");
				break;
			default:
				assert(false);
			}

			write("\tSoort: ");
			switch (soort) {
			case GL_DEBUG_TYPE_ERROR:
				writeln("Fout ╮(. ❛ ᴗ ❛.)╭");
				break;
			case GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR:
				writeln("Verouderd gebruik");
				break;
			case GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR:
				writeln("Ongedefiniëerd gedrag");
				break;
			case GL_DEBUG_TYPE_PORTABILITY:
				writeln("Systeem overzetbaarheid");
				break;
			case GL_DEBUG_TYPE_PERFORMANCE:
				writeln("Uitvoeringsproblemen");
				break;
			case GL_DEBUG_TYPE_MARKER:
				writeln("\"Command stream annotation\"");
				break;
			case GL_DEBUG_TYPE_PUSH_GROUP:
				writeln("\"Group pushing\"");
				break;
			case GL_DEBUG_TYPE_POP_GROUP:
				writeln("\"foo\"");
				break;
			case GL_DEBUG_TYPE_OTHER:
				writeln("Overig");
				break;
			default:
				assert(false);
			}

			write("\tErnstigheid: ");
			switch (ernstigheid) {
			case GL_DEBUG_SEVERITY_HIGH:
				writeln("Hoog");
				break;
			case GL_DEBUG_SEVERITY_MEDIUM:
				writeln("Middelmatig");
				break;
			case GL_DEBUG_SEVERITY_LOW:
				writeln("Laag");
				break;
			case GL_DEBUG_SEVERITY_NOTIFICATION:
				writeln("Melding (Overig)");
				break;
			default:
				assert(false);
			}

			writeln("\tBericht: " ~ message.to!string);
		} catch (Exception e) {
		}
	}
}
