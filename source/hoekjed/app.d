module hoekjed.app;

import bindbc.glfw;
import std.conv;
import std.datetime.stopwatch;
import std.parallelism;
import std.range : iota;
import std.stdio;
import std.math;

void main() {
	import hoekjed;

	hdZetOp();
	// Venster.zetStandaardDoorzichtig(true);
	Venster venster = new Venster();
	venster.zetAchtergrondKleur(Vec!(4, float)([0, 0, 0.5, 0.5]));
	venster.zetMuissoort(Muissoort.GEVANGEN);

	Wereld wereld = new Wereld();

	Vec!3[] plekken = [
		{[-0.5f, 0.5, -0.5f]}, {[0.5f, 0.5, -0.5f]}, {[0, 0.5, 0.5f]}
	];
	Vec!3[] normalen = [{[0.0f, -1, 0]}, {[0, -1, 0]}, {[0, -1, 0]}];
	Vec!2[] beeldplekken = [{[-0.5f, -0.5f]}, {[0.5f, -0.5f]}, {[0, 0.5f]}];
	Vec!(3, uint)[] volgorde = [{[0, 1, 2]}];

	Voorwerp vlak = new DraadVoorwerp(plekken, normalen, beeldplekken, volgorde);
	// vlak.plek = Vec!3([0, 1, 0]);
	wereld.voorwerpen ~= vlak;

	Vec!3[] plekken2 = [
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

		/**
		*	Koppelt invoer van deze speler aan een venster.
		*/
		void koppel(Venster venster) {
			venster.toetsTerugroepers ~= &toetsTerugroeper;
			venster.muisplekTerugroepers ~= &muisplekTerugroeper;
		}

		void ontkoppel(Venster venster) {
			import std.algorithm : remove;

			venster.toetsTerugroepers.remove!(a => a == &toetsTerugroeper);
			venster.muisplekTerugroepers.remove!(a => a == &muisplekTerugroeper);
		}

		void toetsTerugroeper(ToetsInvoer invoer) nothrow {
			if (invoer.gebeurtenis == GLFW_REPEAT)
				return;
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

		void muisplekTerugroeper(MuisplekInvoer invoer) nothrow {
			draai = Vec!(3)([-0.05 * invoer.y, 0, -0.05 * invoer.x]);
		}

		override void _denk(Wereld wereld) {
			Vec!3 richting = Vec!3([-sin(draai.z), cos(draai.z), 0]) * (rent ? rensnelheid
					: snelheid);
			Vec!3 rechts = Vec!3([richting.y, -richting.x, 0]);
			Vec!3 stap = richting * loop_y + rechts * loop_x;
			if (loop_x != 0 && loop_y != 0)
				stap = stap * cast(nauwkeurigheid)(1 / SQRT2);
			plek = plek + stap;
		}
	}

	Speler speler = new Speler();
	speler.koppel(venster);
	wereld.voorwerpen ~= speler;

	venster.wereld = wereld;
	venster.zicht = speler;

	lus();
}
