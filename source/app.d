import bindbc.glfw;
import core.sys.windows.windows;
import std.conv;
import std.datetime.stopwatch;
import std.parallelism;
import std.range : iota;
import std.stdio;
import wiskunde;

// VOEG TOE: module bestand? + glfw & opengl laden hier mee.
// Zet hier ook gelijk error callbacks voor glfw & opengl.

extern (C) void glfw_foutterugroep(int soort, const char* beschrijving) nothrow {
	try {
		writefln("Fout %d: %s", soort, beschrijving.to!string);
	} catch (Exception e) {
	}
}

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
			// roep normale terugroep
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

	import bindbc.glfw;
	import bindbc.opengl;

	glfwSetErrorCallback(&glfw_foutterugroep);
	glfwInit();

	Mat!(5, 5, int) a = {
		[
			[1, 2, 3, 4, 5], [1, 2, 3, 4, 5], [1, 2, 3, 4, 5], [1, 2, 3, 4, 5],
			[1, 2, 3, 4, 5]
		]
	};
	Mat!(5, 5, int) b = {
		[
			[0, 1, 0, 1, 2], [0, 1, 0, 1, 2], [0, 1, 0, 1, 2], [0, 1, 0, 1, 2],
			[0, 1, 0, 1, 2]
		]
	};

	a *= 2;

	// GLFWwindow* scherm = glfwCreateWindow(1920 / 2, 1080 / 2, "HoekjeD v0.0.0", null, null);
	// assert(scherm != null, "GLFW kon geen scherm aanmaken.");
	// glfwMakeContextCurrent(scherm);
	// debug glfwSetKeyCallback(scherm, &glfw_toetsterugroep_debug);

	// GLSupport gl_versie = loadOpenGL();
	// assert(gl_versie == GLSupport.gl46, "GL laadt niet: " ~ gl_versie.to!string);

	// while (!glfwWindowShouldClose(scherm)) {
	// 	glfwPollEvents();
	// }
}
