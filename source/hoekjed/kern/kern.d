module hoekjed.kern.kern;
import bindbc.glfw;
import core.sys.windows.windows;
import hoekjed.kern;
import hoekjed.wereld;
import std.conv : to;
import std.datetime.stopwatch;
import std.stdio : writefln;
import std.stdio;

private extern (C) void glfw_foutterugroep(int soort, const char* beschrijving) nothrow {
	try {
		writefln("GLFW Fout %d: %s", soort, beschrijving.to!string);
	} catch (Exception e) {
	}
}

debug {
	package HWND console = null;
	package bool _console_zichtbaar = false;
}

debug void hdToonConsole(bool zichtbaar) {
	ShowWindow(console, zichtbaar ? SW_SHOW : SW_HIDE);
	_console_zichtbaar = zichtbaar;
}

void hdZetOp() {
	debug {
		console = GetConsoleWindow();
		SetWindowPos(console, HWND_BOTTOM, 0, 0, 1920 / 3, 1080 / 3, SWP_HIDEWINDOW);
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
public ulong hdStaptal() {
	return _hdStaptal;
}

@property
public Duration hdTijd() {
	return _hdTijd.peek();
}

public void hdStap() {
	_hdStaptal += 1;
	Duration deltaT = hdTijd();

	foreach (Venster venster; Venster.vensters.values)
		venster.verwerkInvoer();

	foreach (Wereld wereld; Wereld.werelden)
		wereld.denkStap(deltaT);

	foreach (Wereld wereld; Wereld.werelden)
		wereld.werkMatricesBij();

	foreach (Venster venster; Venster.vensters.values) {
		GLFWwindow* glfw_venster = venster.glfw_venster;
		if (glfwWindowShouldClose(venster.glfw_venster)) {
			glfwDestroyWindow(glfw_venster);
			Venster.vensters.remove(glfw_venster);
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
