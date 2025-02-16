///
module vertexd.core.core;

import bindbc.glfw;
import core.sys.windows.windows;
import vertexd.core;
import vertexd.world;
import std.conv : to;
import std.datetime.stopwatch;
import std.stdio : stderr, File;
import std.stdio;
import vertexd.core.time;

private extern (C) void glfw_error_callback(int type, const char* description) nothrow {
	try {
		stderr.writefln("GLFW Exception %d: %s", type, description.to!string);
	} catch (Exception e) {
	}
}

debug {
	package HWND console = null;
	package bool _console_visible = false;
}

debug void vdShowConsole(bool visible) {
	ShowWindow(console, visible ? SW_SHOW : SW_HIDE);
	_console_visible = visible;
}

void vdInit() {
	debug {
		console = GetConsoleWindow();
		SetWindowPos(console, HWND_BOTTOM, 0, 0, 640, 360, 0);
	} else {
		FreeConsole();
	}

	glfwSetErrorCallback(&glfw_error_callback);
	glfwInit();
	Time.start();
}

void vdTerminate() {
	glfwTerminate();
}
