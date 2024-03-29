module hoekjed.kern.venster;

import bindbc.glfw;
import bindbc.opengl;
import hoekjed.kern;
import hoekjed.wereld;
import std.container.rbtree;
import std.conv : to;

struct ToetsInvoer {
	int toets, toets_verwijzing, gebeurtenis, toevoeging;
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
	// Venster Eigenschappen
	string naam;
	int breedte;
	int hoogte;
	package GLFWwindow* glfw_venster;
	static package Venster[GLFWwindow* ] vensters;

	// Wereld
	Wereld wereld;

	// Invoer
	ToetsTerugroeper[] toetsTerugroepers = [];
	MuisknopTerugroeper[] muisknopTerugroepers = [];
	MuisplekTerugroeper[] muisplekTerugroepers = [];
	MuiswielTerugroeper[] muiswielTerugroepers = [];
	ToetsInvoer[] toetsInvoer = [];
	MuisplekInvoer[] muisplekInvoer = [];
	MuisknopInvoer[] muisknopInvoer = [];
	MuiswielInvoer[] muiswielInvoer = [];

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

	this(string naam = "HoekjeD", int glfw_breedte = 960, int glfw_hoogte = 540) {
		this.naam = naam;

		debug glfwWindowHint(GLFW_OPENGL_DEBUG_CONTEXT, true);
		this.glfw_venster = glfwCreateWindow(glfw_breedte, glfw_hoogte, naam.ptr, null, null);
		assert(glfw_venster !is null, "GLFW kon geen scherm aanmaken.");

		Venster.vensters[glfw_venster] = this;
		glfwMakeContextCurrent(glfw_venster); // TODO: Moet voor multithreading & meerdere vensters nog een oplossing vinden.
		//glfwSwapInterval(0); Kan met 1 vsynch gebruiken.

		glfwSetKeyCallback(glfw_venster, &venster_toets_terugroeper);
		glfwSetMouseButtonCallback(glfw_venster, &venster_muisknop_terugroeper);
		glfwSetCursorPosCallback(glfw_venster, &venster_muisplek_terugroeper);
		glfwSetScrollCallback(glfw_venster, &venster_muiswiel_terugroeper);
		// glfwSetWindowSizeCallback(glfw_venster, &venster_grootte_terugroeper);
		glfwSetFramebufferSizeCallback(glfw_venster, &venster_grootte_terugroeper);

		GLSupport gl_versie = loadOpenGL();
		assert(gl_versie == GLSupport.gl46, "GL laadt niet: " ~ gl_versie.to!string);

		debug {
			glEnable(GL_DEBUG_OUTPUT);
			glEnable(GL_DEBUG_OUTPUT_SYNCHRONOUS);
			glDebugMessageCallback(&gl_fout_terugroeper, null);
			glDebugMessageControl(GL_DONT_CARE, GL_DONT_CARE, GL_DEBUG_SEVERITY_NOTIFICATION, 0, null, false);
		}

		glfwSetCursorPos(glfw_venster, 0, 0);
		glEnable(GL_DEPTH_TEST);
	}

	void teken() {
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT); // Verschoont het scherm.
		wereld.teken();
		glfwSwapBuffers(glfw_venster);
	}

	protected void hervorm(int breedte, int hoogte) nothrow {
		this.breedte = breedte;
		this.hoogte = hoogte;
		glViewport(0, 0, breedte, hoogte);
	}

	void bekijk() {
		glfwFocusWindow(glfw_venster);
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

	// PAS OP: Moet mogelijk testen wat de toevoeging is bij gebrek aan toevoeging of dubbele
	// toevoegingen. Hier is de documentatie niet duidelijk.
	public bool krijgToets(int toets) {
		foreach (ToetsInvoer t; this.toetsInvoer)
			if (t.toets == toets && (t.gebeurtenis == GLFW_PRESS || t.gebeurtenis == GLFW_REPEAT))
				return true;
		return false;
	}

	void leegInvoer() {
		toetsInvoer = [];
		muisknopInvoer = [];
		muisplekInvoer = [];
		muiswielInvoer = [];
	}

	unittest {
		import hoekjed.kern;

		hdZetOp();
		Venster.zetStandaardDoorzichtig(true);

		bool called = false;
		ToetsTerugroeper foo = (ToetsInvoer invoer) { called = true; };
		Venster venster = new Venster();
		venster.toetsTerugroepers ~= foo;

		venster_toets_terugroeper(venster.glfw_venster, 0, 0, 0, 0);
		venster.verwerkInvoer();

		assert(called);
	}
}

extern (C) void venster_grootte_terugroeper(GLFWwindow* glfw_venster, int breedte, int hoogte) nothrow {
	Venster.vensters[glfw_venster].hervorm(breedte, hoogte);
}

extern (C) void venster_toets_terugroeper(GLFWwindow* glfw_venster, int toets,
	int toets_sleutel, int gebeurtenis, int toevoeging) nothrow {
	debug {
		import core.sys.windows.windows;

		if (toets == GLFW_KEY_GRAVE_ACCENT) {
			ShowWindow(console, _console_zichtbaar ? SW_HIDE : SW_RESTORE);
			glfwFocusWindow(glfw_venster);
			_console_zichtbaar = !_console_zichtbaar;
		}
	}
	if (toets == GLFW_KEY_ESCAPE)
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
