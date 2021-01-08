import std.stdio;
import std.conv;
import bindbc.glfw;

extern (C) void glfw_foutterugroep(int soort, const char* beschrijving) nothrow {
	try {
		writefln("Fout %d: %s", soort, beschrijving.to!string);
	} catch (Exception e) {
	}
}

extern (C) void glfw_toetsterugroep_debug(GLFWwindow* scherm, int toets,
		int toetsgetal, int handeling, int toevoeging) nothrow {
	if (toets == GLFW_KEY_GRAVE_ACCENT) {
		import core.sys.windows.windows;

		try {
			// Hide / Unhide console.
			AllocConsole();
			std.stdio.stdout.reopen("CONOUT$", "w");
			std.stdio.stdin.reopen("CONIN$", "r");
		} catch (Exception e) {
		}
	} else {
		// roep normale terugroep
	}

}

void main() {
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
