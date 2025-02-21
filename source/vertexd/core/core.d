///
module vertexd.core.core;

import bindbc.freetype;
import bindbc.glfw;
import vertexd.core;
import vertexd.core.time;
import vertexd.world;
import vertexd.gui.freetype;

import core.sys.windows.windows;
import std.conv : to;
import std.datetime.stopwatch;
import std.stdio : writefln;

private extern (C) void glfw_error_callback(int type, const char* description) nothrow {
	try {
		writefln("GLFW Exception %d: %s", type, description.to!string);
	} catch (Exception e) {
	}
}

debug {
	package HWND console = null;
	package bool _console_visible = false;

	void vdShowConsole(bool visible) {
		ShowWindow(console, visible ? SW_SHOW : SW_HIDE);
		_console_visible = visible;
	}
}

void vdInit() {
	debug {
		console = GetConsoleWindow();
		SetWindowPos(console, HWND_BOTTOM, 0, 0, 1920 / 3, 1080 / 3, 0);
	}
	//  else {
	// 	FreeConsole();
	// }

	glfwSetErrorCallback(&glfw_error_callback);
	glfwInit();
	_initFreeType();

	Time.start();
}

void vdTerminate() {
	glfwTerminate();
	_terminateFreeType();
}
