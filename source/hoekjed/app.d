module hoekjed.app;

import bindbc.glfw;
import core.sys.windows.windows;
import std.conv;
import std.datetime.stopwatch;
import std.parallelism;
import std.range : iota;
import std.stdio;

// VOEG TOE: module bestand? + glfw & opengl laden hier mee.
// Zet hier ook gelijk error callbacks voor glfw & opengl.

// extern (C) void glfw_foutterugroep(int soort, const char* beschrijving) nothrow {
// 	try {
// 		writefln("Fout %d: %s", soort, beschrijving.to!string);
// 	} catch (Exception e) {
// 	}
// }

debug {
	private HWND console;
	private bool console_zichtbaar;

	extern (C) void glfw_toetsterugroep_debug(GLFWwindow* scherm, int toets,
			int toetsgetal, int handeling, int toevoeging) nothrow {
		if (toets == GLFW_KEY_GRAVE_ACCENT) {
			ShowWindow(console, console_zichtbaar ? SW_HIDE : SW_RESTORE);
			glfwFocusWindow(scherm);
			console_zichtbaar = !console_zichtbaar;
		} else {
			//VOEG TOE roep normale terugroep
		}

	}
}

void main() {

	debug {
		console = GetConsoleWindow();
		SetWindowPos(console, HWND_BOTTOM, 0, 0, 1920 / 3, 1080 / 3, SWP_HIDEWINDOW);
	} else {
		// FreeConsole();
	}

	import hoekjed;

	hdZetOp();
	// Venster.zetStandaardDoorzichtig(true);
	Venster venster = new Venster();
	venster.zetAchtergrondKleur(Vec!(4, float)([0, 0, 0.5, 0.5]));
	Wereld wereld = new Wereld();

	Vec!(3, nauwkeurigheid)[] plekken = [
		{[-0.5f, -0.5f, 0]}, {[0.5f,  - 0.5f , 0]}, {[0, 0.5f, 0]}
	];
	Vec!(3, nauwkeurigheid)[] normalen = [
		{[0.0f, -1, 0]}, {[0, -1, 0]}, {[0, -1, 0]}
	];
	Vec!(2, nauwkeurigheid)[] beeldplekken = [
		{[-0.5f, -0.5f]}, {[0.5f, -0.5f]}, {[0, 0.5f]}
	];
	Vec!(3, uint)[] volgorde = [{[0, 1, 2]}];

	Voorwerp vlak = new DraadVoorwerp(plekken, normalen, beeldplekken, volgorde);
	// vlak.plek = Vec!3([0, 1, 0]);
	wereld.voorwerpen ~= vlak;

	Zicht zicht = new DiepteZicht();
	wereld.voorwerpen ~= zicht;

	venster.wereld = wereld;
	venster.zicht = zicht;

	void verplaats(ToetsInvoer invoer) nothrow {
		switch (invoer.toets) {
		case GLFW_KEY_A:
			zicht.plek = zicht.plek + Vec!(3)([-1, 0, 0]);
			break;
		case GLFW_KEY_W:
			zicht.plek = zicht.plek + Vec!(3)([0, 1, 0]);
			break;
		case GLFW_KEY_S:
			zicht.plek = zicht.plek + Vec!(3)([0, -1, 0]);
			break;
		case GLFW_KEY_D:
			zicht.plek = zicht.plek + Vec!(3)([1, 0, 0]);
			break;
		default:
		}
	}

	void draai(double x, double y) {
		// static double beginx = x;
		// static double beginy = y;
		// double dx = x - beginx;
		// double dy = y - beginy;
		// beginx = x;
		// beginy = y;
		zicht.draai = zicht.draai + Vec!(3)([0, y, -x]);
	}

	venster.voegToetsTerugroeperToe(&verplaats);
	venster.voegMuisplekTerugroeperToe(&draai);

	lus();
}
