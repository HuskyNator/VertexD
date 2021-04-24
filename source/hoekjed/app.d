module hoekjed.app;

import bindbc.glfw;
import core.sys.windows.windows;
import std.conv;
import std.datetime.stopwatch;
import std.parallelism;
import std.range : iota;
import std.stdio;
import std.math;

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
	venster.zetMuissoort(Muissoort.GEVANGEN);

	Wereld wereld = new Wereld();

	Vec!(3, nauwkeurigheid)[] plekken = [
		{[-0.5f, 0.5, -0.5f]}, {[0.5f, 0.5, -0.5f]}, {[0, 0.5, 0.5f]}
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

	Vec!(3, nauwkeurigheid)[] plekken2 = [
		{[-0.5f, -0.5, -0.5f]}, {[0.5f, 0.5, -0.5f]}, {[0, -0.5, -0.5f]}
	];
	Voorwerp vloer = new DraadVoorwerp(plekken2, normalen, beeldplekken, volgorde);
	wereld.voorwerpen ~= vloer;

	class Speler : DiepteZicht {

		invariant(loop_x.abs <= 1);
		invariant(loop_y.abs <= 1);
		byte loop_x = 0;
		byte loop_y = 0;
		bool rent = false;
		float snelheid = 0.01;
		float rensnelheid = 0.04;

		override void _denk(Wereld wereld) {
			foreach (ToetsInvoer invoer; Venster.invoer) {
				if (invoer.gebeurtenis == GLFW_REPEAT)
					continue;
				switch (invoer.toets) {
				case GLFW_KEY_A:
					loop_x += (invoer.gebeurtenis == GLFW_PRESS) ? -1 : 1;
					break;
				case GLFW_KEY_W:
					loop_y += (invoer.gebeurtenis == GLFW_PRESS) ? 1 : -1;
					break;
				case GLFW_KEY_S:
					loop_y += (invoer.gebeurtenis == GLFW_PRESS) ? -1 : 1;
					break;
				case GLFW_KEY_D:
					loop_x += (invoer.gebeurtenis == GLFW_PRESS) ? 1 : -1;
					break;
				case GLFW_KEY_LSHIFT:
					rent = invoer.gebeurtenis == GLFW_PRESS;
					break;
				default:
				}
			}

			Vec!(3) richting = Vec!(3)([-sin(draai.z), cos(draai.z), 0]) * (rent
					? rensnelheid : snelheid);
			Vec!(3) rechts = Vec!(3)([richting.y, -richting.x, 0]);
			Vec!(3) stap = richting * loop_y + rechts * loop_x;
			if (loop_x != 0 && loop_y != 0)
				stap = stap * cast(float)(1 / SQRT2);
			plek = plek + stap;
		}
	}

	Zicht zicht = new Speler();
	wereld.voorwerpen ~= zicht;

	venster.wereld = wereld;
	venster.zicht = zicht;

	static double vorigx = 0;
	static double vorigy = 0;
	void draai(double x, double y) {
		double dx = x - vorigx;
		double dy = y - vorigy;
		vorigx = x;
		vorigy = y;
		zicht.draai = zicht.draai + Vec!(3)([-0.05 * dy, 0, -0.05 * dx]);
	}

	venster.voegMuisplekTerugroeperToe(&draai);

	lus();
}
