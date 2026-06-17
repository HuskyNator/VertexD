///
module vertexd.core.core;

import bindbc.freetype;
import bindbc.glfw;
import vertexd.core;
import vertexd.core.time;
import vertexd.gui.freetype;
import vertexd.renderer.renderer;
import vertexd.world;

import std.conv : to;
import std.datetime.stopwatch;
import std.stdio;
import std.stdio : File, stderr, writefln;

private extern (C) void glfw_error_callback(int type, const char* description) nothrow {
	try {
		stderr.writefln("GLFW Exception %d: %s", type, description.to!string);
	} catch (Exception e) {
	}
}

version (Windows) {
	import core.sys.windows.windows;

	package HWND console = null;
	package bool _console_visible = false;

	void vdShowConsole(bool visible) {
		ShowWindow(console, visible ? SW_SHOW : SW_HIDE);
		_console_visible = visible;
	}
}

bool vdInit(bool showConsole = false) {
	version (Windows) {
		if (showConsole) {
			console = GetConsoleWindow();
			SetWindowPos(console, HWND_BOTTOM, 0, 0, 640, 360, 0);
		} else {
			FreeConsole();
		}
	}

	// auto ret = loadGLFW();
	// if (ret != GLFWSupport.glfw34) {
	// 	stderr.writeln("Could not load glfw-3.4. Loading result: ", ret);
	// 	return false;
	// }

	// auto retFT = loadFreeType();
	// if (retFT != FTSupport.v2_13) {
	// 	stderr.writeln("Could not load freetype-2.13. Loading result: ", retFT);
	// 	return false;
	// }

	glfwSetErrorCallback(&glfw_error_callback);
	glfwInit();
	_initFreeType();

	Time.start();
	return true;
}

void vdTerminate() {
	glfwTerminate();
	_terminateFreeType();
}

void vdSimpleLoop(ref Window window, ref Renderer renderer, ref Node root) {
	while (!window.shouldClose()) {
		// Get Input
		InputManager.pollInput();

		// Start new frame
		Time.nextFrame();

		// Update state
		InputManager.runCallbacks();
		root.runUpdates();

		// Render
		window.clearBuffers();
		renderer.render(window, root);
		window.swapBuffers();
	}
}

