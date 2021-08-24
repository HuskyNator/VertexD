module hoekjed.kern.kern;
import bindbc.glfw;
import core.sys.windows.windows;
import hoekjed.kern;
import std.conv : to;
import std.stdio : writefln;
import std.datetime.stopwatch;

private extern (C) void glfw_foutterugroep(int soort, const char* beschrijving) nothrow {
	try {
		writefln("GLFW Fout %d: %s", soort, beschrijving.to!string);
	} catch (Exception e) {
	}
}

debug {
	package HWND console;
	package bool console_zichtbaar;
}

void hdZetOp() {
	debug {
		console = GetConsoleWindow();
		SetWindowPos(console, HWND_BOTTOM, 0, 0, 1920 / 3, 1080 / 3, SWP_HIDEWINDOW);
		console_zichtbaar = false;
	} else {
		FreeConsole();
	}

	glfwSetErrorCallback(&glfw_foutterugroep);
	glfwInit();
	_hdTijd = StopWatch(AutoStart.yes); // Herstelt naar 0 zodra hdLus op wordt geroepen.
}

private ulong _hdStaptal = 0;
private StopWatch _hdTijd;

@property
public ulong hdStaptal(){
	return _hdStaptal;
}

@property
public Duration hdTijd(){
	return _hdTijd.peek();
}

public void hdStap() {
	_hdStaptal += 1;

	foreach (Venster venster; Venster.vensters.values)
		venster.verwerkInvoer();

	foreach (Wereld wereld; Wereld.werelden)
		wereld.denkWereld();

	foreach (Wereld wereld; Wereld.werelden)
		wereld.werkWereldBij();

	foreach (Venster venster; Venster.vensters.values) {
		GLFWwindow* glfw_venster = venster.glfw_venster;
		if (glfwWindowShouldClose(venster.glfw_venster)) {
			glfwDestroyWindow(glfw_venster);
			Venster.vensters.remove(glfw_venster);
			//PAS OP: mogelijke nullpointers wanneer werelden of voorwerpen dit venster gebruiken.
		} else
			venster.teken();
	}

	foreach (Venster venster; Venster.vensters.values)
		venster.leegInvoer();

	glfwPollEvents();
}

public void hdLus() {
	_hdTijd.reset();
	while (Venster.vensters.length > 0)
		hdStap();
}
