module hoekjed.hoekjed;
import hoekjed;
import bindbc.glfw;
import std.stdio : writefln;
import std.conv : to;

private extern (C) void glfw_foutterugroep(int soort, const char* beschrijving) nothrow {
	try {
		writefln("GLFW Fout %d: %s", soort, beschrijving.to!string);
	} catch (Exception e) {
	}
}

void hdZetOp() {
	glfwSetErrorCallback(&glfw_foutterugroep);
	glfwInit();
}

private ulong tijd = 0;
void stap() {
	tijd += 1;
	foreach (Wereld wereld; Wereld.werelden) {
		wereld.denk();
	}

	foreach (Venster venster; Venster.vensters.values) {
		GLFWwindow* glfw_venster = venster.glfw_venster;
		if (glfwWindowShouldClose(venster.glfw_venster)) {
			glfwDestroyWindow(glfw_venster);
			Venster.toetsTerugroepers.remove(glfw_venster);
			Venster.vensters.remove(glfw_venster);
		} else
			venster.teken();
	}

	Venster.invoer = [];
	glfwPollEvents();
}

void lus() {
	while (Venster.vensters.length > 0) {
		stap();
	}
}
