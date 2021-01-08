import std.stdio;
import std.conv;
import bindbc.glfw;
import core.sys.windows.windows;

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
		FreeConsole();
	}

	import bindbc.glfw;
	import bindbc.opengl;
	import wiskunde;

	glfwSetErrorCallback(&glfw_foutterugroep);
	glfwInit();

	GLFWwindow* scherm = glfwCreateWindow(1920 / 2, 1080 / 2, "HoekjeD v0.0.0", null, null);
	assert(scherm != null, "GLFW kon geen scherm aanmaken.");
	glfwMakeContextCurrent(scherm);
	debug glfwSetKeyCallback(scherm, &glfw_toetsterugroep_debug);

	GLSupport gl_versie = loadOpenGL();
	assert(gl_versie == GLSupport.gl46, "GL laadt niet: " ~ gl_versie.to!string);

	while (!glfwWindowShouldClose(scherm)) {
		glfwPollEvents();
	}
}
