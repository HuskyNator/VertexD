module vertexd.core.core;
import bindbc.glfw;
import core.sys.windows.windows;
import vertexd.core;
import vertexd.world;
import std.conv : to;
import std.datetime.stopwatch;
import core.atomic;
import std.stdio;
import core.sync.mutex;

private:
extern (C) void glfw_error_callback(int type, const char* description) nothrow {
	try {
		writefln("GLFW Exception %d: %s", type, description.to!string);
	} catch (Exception e) {
	}
}

debug {
	package HWND console = null;
	public bool console_visible = false;

	public void vdShowConsole(bool visible) {
		ShowWindow(console, visible ? SW_SHOW : SW_HIDE);
		console_visible = visible;
	}
}

public void vdInit() {
	debug {
		console = GetConsoleWindow();
		SetWindowPos(console, HWND_BOTTOM, 0, 0, 1920 / 3, 1080 / 3, SWP_HIDEWINDOW);
	} else {
		FreeConsole();
	}

	glfwSetErrorCallback(&glfw_error_callback);
	glfwInit();

	_vdStepCount = 0;
	_vdTime = StopWatch(AutoStart.yes);
	_vdDeltaT = _vdDeltaT.zero();
}

public void vdTerminate() {
	glfwTerminate();
}

ulong _vdStepCount;
StopWatch _vdTime;
Duration _vdDeltaT;

@property public ulong vdStepCount() {
	return _vdStepCount;
}

@property public Duration vdTime() {
	return _vdTime.peek();
}

public Duration vdDeltaT() {
	return _vdDeltaT;
}

public float vdFps() {
	return 1_000_000.0f / vdDeltaT().total!"usecs";
}

public void vdStep() {
	_vdStepCount += 1;
	static Duration oldT = Duration.zero();
	Duration newT = vdTime();
	_vdDeltaT = newT - oldT;
	oldT = newT;

	// foreach (Window window; Window.windows.values) {
	// 	window.processInput();
	// 	if (glfwWindowShouldClose(window.glfw_window))
	// 		destroy(window);
	// }

	// foreach (World world; World.worlds)
	// 	world.update();

	// foreach (Window window; Window.windows.values)
	// 	window.draw();

	// foreach (Window window; Window.windows.values)
	// 	window.clearInput();

	glfwPollEvents();
}

bool vdShouldClose() {
	return Window.windows.length == 0;
}

public void vdLoop() {
	while (!vdShouldClose())
		vdStep();
	writeln("\nLast window removed. Halting loop.\n");
}
