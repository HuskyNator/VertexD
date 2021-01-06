import std.stdio;
import bindbc.glfw;
import bindbc.opengl;
import std.conv;

extern (C) void glfw_foutterugroep(int soort, const char* beschrijving) nothrow {
	try {
		writefln("Fout %d: %s", soort, beschrijving.to!string);
	} catch (Exception e) {
	}
}

void main() {
	glfwSetErrorCallback(&glfw_foutterugroep);
	glfwInit();

	GLFWwindow* scherm = glfwCreateWindow(1920 / 2, 1080 / 2, "HoekjeD v0.0.0", null, null);
	assert(scherm != null);
	glfwMakeContextCurrent(scherm);

	GLSupport gl_versie = loadOpenGL();
	assert(gl_versie == GLSupport.gl46, "GL laadt niet: " ~ gl_versie.to!string);

	while (!glfwWindowShouldClose(scherm)) {
		glfwPollEvents();
	}
}
