module vertexd.core.core;
import bindbc.glfw;
import core.sys.windows.windows;
import vertexd.core;
import vertexd.world;
import std.conv : to;
import std.datetime.stopwatch;
import std.stdio : writefln;
import std.stdio;

private extern (C) void glfw_error_callback(int type, const char* description) nothrow {
	try {
		writefln("GLFW Exception %d: %s", type, description.to!string);
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
		SetWindowPos(console, HWND_BOTTOM, 0, 0, 1920 / 3, 1080 / 3, SWP_HIDEWINDOW);
	} else {
		FreeConsole();
	}

	glfwSetErrorCallback(&glfw_error_callback);
	glfwInit();
	_vdTime = StopWatch(AutoStart.yes); // Restores to 0 once vdLoop is called
}

ulong[ClassInfo] _vdClassCounts;

string vdName(C)() if (is(C == class)) {
	return vdName(C.classinfo);
}

string vdName(ClassInfo cinfo) {
	ulong newCount = 1uL;
	if (cinfo in _vdClassCounts)
		newCount = _vdClassCounts[cinfo] + 1; // wraps around to 0
	_vdClassCounts[cinfo] = newCount;
	return cinfo.name ~ '#' ~ newCount.to!string;
}

private ulong _vdStepCount = 0;
private StopWatch _vdTime;

@property public ulong vdStepcount() {
	return _vdStepCount;
}

@property public Duration vdTime() {
	return _vdTime.peek();
}

public void vdStep() {
	static Duration oldT = Duration.zero();
	_vdStepCount += 1;
	Duration newT = vdTime();
	Duration deltaT = newT - oldT;
	oldT = newT;

	foreach (Window window; Window.windows.values)
		window.processInput();

	foreach (World world; World.worlds)
		world.logicStep(deltaT);

	foreach (World world; World.worlds)
		world.update();

	foreach (Window window; Window.windows.values) {
		GLFWwindow* glfw_window = window.glfw_window;
		if (glfwWindowShouldClose(window.glfw_window))
			window.close();
		else
			window.draw();
	}

	foreach (Window window; Window.windows.values)
		window.clearInput();

	glfwPollEvents();
}

public void vdLoop() {
	_vdTime.reset();
	while (Window.windows.length > 0)
		vdStep();
	writeln("\nLast window removed. Halting loop.\n");
}
