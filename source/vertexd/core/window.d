module vertexd.core.window;

import bindbc.glfw;
import bindbc.opengl;
import vertexd.core;
import vertexd.world;
import std.container.rbtree;
import std.conv : to;
import std.exception : enforce;
import bindbc.opengl.bind.arb.arb_01 : hasARBBindlessTexture;

struct KeyInput {
	int key, key_id, event, modifier;
}

struct MousebuttonInput {
	int button, event, modifier;
}

struct MousepositionInput {
	double x, y;
}

struct MousewheelInput {
	double x, y;
}

alias KeyCallback = void delegate(KeyInput input) nothrow;
alias MousebuttonCallback = void delegate(MousebuttonInput input) nothrow;
alias MousepositionCallback = void delegate(MousepositionInput input) nothrow;
alias MousewheelCallback = void delegate(MousewheelInput input) nothrow;

enum MouseType {
	NORMAL = GLFW_CURSOR_NORMAL,
	CAPTURED = GLFW_CURSOR_DISABLED,
	INVISIBLE = GLFW_CURSOR_HIDDEN
}

class Window {
	// Window Properties
	string name;
	int width;
	int height;
	// package GLFWwindow* glfw_window;
	GLFWwindow* glfw_window;
	static package Window[GLFWwindow* ] windows;

	// World
	World world;

	// Input
	KeyCallback[] keyCallbacks = [];
	MousebuttonCallback[] mousebuttonCallbacks = [];
	MousepositionCallback[] mousepositionCallbacks = [];
	MousewheelCallback[] mousewheelCallbacks = [];
	KeyInput[] keyInput = [];
	MousepositionInput[] mousepositionInput = [];
	MousebuttonInput[] mousebuttonInput = [];
	MousewheelInput[] mousewheelInput = [];

	static void setStandardVisible(bool visible) {
		glfwWindowHint(GLFW_VISIBLE, visible);
	}

	static void setStandardBorder(bool rand) {
		glfwWindowHint(GLFW_DECORATED, rand);
	}

	static void setStandardTransparency(bool transparent) {
		glfwWindowHint(GLFW_TRANSPARENT_FRAMEBUFFER, transparent);
	}

	void setBackgroundColor(Vec!(4, float) color) {
		glClearColor(color.x, color.y, color.z, color.w);
	}

	void setMouseType(MouseType type) {
		glfwSetInputMode(glfw_window, GLFW_CURSOR, type);
	}

	this(string name = "HoekjeD", int glfw_width = 960, int glfw_height = 540) {
		this.name = name;

		glfwWindowHint(GLFW_SAMPLES, 4); //TODO: instelbaar

		debug glfwWindowHint(GLFW_OPENGL_DEBUG_CONTEXT, true);
		this.glfw_window = glfwCreateWindow(glfw_width, glfw_height, name.ptr, null, null);
		assert(glfw_window !is null, "GLFW coult not create window");

		Window.windows[glfw_window] = this;
		glfwMakeContextCurrent(glfw_window); // TODO: Should still find a solution for multithreading & using multiple windows
		// glfwSwapInterval(0); Can use vsynch with 1

		glfwSetKeyCallback(glfw_window, &window_key_callback);
		glfwSetMouseButtonCallback(glfw_window, &window_mousebutton_callback);
		glfwSetCursorPosCallback(glfw_window, &window_mouseposition_callback);
		glfwSetScrollCallback(glfw_window, &windows_mousewheel_callback);
		// glfwSetWindowSizeCallback(glfw_window, &window_size_callback);
		glfwSetFramebufferSizeCallback(glfw_window, &windows_size_callback);

		glfwSetCursorPos(glfw_window, 0, 0);

		GLSupport opengl_version = loadOpenGL();
		enforce(opengl_version == GLSupport.gl46, "OpenGL not loading: " ~ opengl_version.to!string);
		enforce(hasARBBindlessTexture, "No support for bindless textures");

		debug {
			glEnable(GL_DEBUG_OUTPUT);
			glEnable(GL_DEBUG_OUTPUT_SYNCHRONOUS);
			glDebugMessageCallback(&gl_error_callback, null);
			glDebugMessageControl(GL_DONT_CARE, GL_DONT_CARE, GL_DEBUG_SEVERITY_NOTIFICATION, 0, null, false);
		}

		glEnable(GL_MULTISAMPLE); //TODO: instelbaar
		glEnable(GL_DEPTH_TEST);
		glEnable(GL_CULL_FACE);
	}

	void draw() {
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT); // Clean the screen
		world.draw();
		glfwSwapBuffers(glfw_window);
	}

	protected void reshape(int width, int height) nothrow {
		this.width = width;
		this.height = height;
		glViewport(0, 0, width, height);
	}

	void focus() {
		glfwFocusWindow(glfw_window);
	}

	void show() {
		glfwShowWindow(glfw_window);
		glClear(GL_COLOR_BUFFER_BIT);
		glfwSwapBuffers(glfw_window);
	}

	void hide() {
		glfwHideWindow(glfw_window);
	}

	void processInput() {
		// Retains order of input for all callbacks
		foreach (KeyInput input; keyInput)
			foreach (KeyCallback callback; keyCallbacks)
				callback(input);

		foreach (MousebuttonInput input; mousebuttonInput)
			foreach (MousebuttonCallback callback; mousebuttonCallbacks)
				callback(input);

		foreach (MousepositionInput input; mousepositionInput)
			foreach (MousepositionCallback callback; mousepositionCallbacks)
				callback(input);

		foreach (MousewheelInput input; mousewheelInput)
			foreach (MousewheelCallback callback; mousewheelCallbacks)
				callback(input);

		//WARNING: assumed independence of mouse & keyboard over small time intervals
	}

	//Warning: May need to test what the modifier is with absence or double modifier
	// Documentation unclear.
	public bool getKey(int key) {
		foreach (KeyInput t; this.keyInput)
			if (t.key == key && (t.event == GLFW_PRESS || t.event == GLFW_REPEAT))
				return true;
		return false;
	}

	void clearInput() {
		keyInput = [];
		mousebuttonInput = [];
		mousepositionInput = [];
		mousewheelInput = [];
	}

	unittest {
		import vertexd.core;

		vdInit();
		Window.setStandardTransparency(true);

		bool called = false;
		KeyCallback foo = (KeyInput input) { called = true; };
		Window window = new Window();
		window.keyCallbacks ~= foo;

		window_key_callback(window.glfw_window, 0, 0, 0, 0);
		window.processInput();

		assert(called);
	}
}

extern (C) void windows_size_callback(GLFWwindow* glfw_window, int width, int height) nothrow {
	Window.windows[glfw_window].reshape(width, height);
}

extern (C) void window_key_callback(GLFWwindow* glfw_window, int key, int key_code, int event, int modifier) nothrow {
	debug {
		import core.sys.windows.windows;

		if (key == GLFW_KEY_GRAVE_ACCENT) {
			ShowWindow(console, _console_visible ? SW_HIDE : SW_RESTORE);
			glfwFocusWindow(glfw_window);
			_console_visible = !_console_visible;
		}
	}
	if (key == GLFW_KEY_ESCAPE)
		glfwSetWindowShouldClose(glfw_window, true);

	Window window = Window.windows[glfw_window];
	KeyInput input = KeyInput(key, key_code, event, modifier);
	window.keyInput ~= input;
}

extern (C) void window_mousebutton_callback(GLFWwindow* glfw_window, int button, int event, int modifier) nothrow {
	Window window = Window.windows[glfw_window];
	MousebuttonInput input = MousebuttonInput(button, event, modifier);
	window.mousebuttonInput ~= input;
}

extern (C) void window_mouseposition_callback(GLFWwindow* glfw_window, double x, double y) nothrow {
	Window window = Window.windows[glfw_window];
	MousepositionInput input = MousepositionInput(x, y);
	window.mousepositionInput ~= input;
}

extern (C) void windows_mousewheel_callback(GLFWwindow* glfw_window, double x, double y) nothrow {
	Window window = Window.windows[glfw_window];
	MousewheelInput input = MousewheelInput(x, y);
	window.mousewheelInput ~= input;
}

debug {
	extern (System) void gl_error_callback(GLenum source, GLenum type, GLuint errorID, GLenum severity,
		GLsizei length, const GLchar* message, const void* userParam) nothrow {
		import std.stdio : write, writeln;
		import std.conv : to;
		import bindbc.opengl.bind.types;

		try {
			writeln("Opengl Exception #" ~ errorID.to!string);
			write("\tSource: ");
			switch (source) {
				case GL_DEBUG_SOURCE_API:
					writeln("OpenGL API");
					break;
				case GL_DEBUG_SOURCE_WINDOW_SYSTEM:
					writeln("Window System API");
					break;
				case GL_DEBUG_SOURCE_SHADER_COMPILER:
					writeln("Shader Compiler");
					break;
				case GL_DEBUG_SOURCE_THIRD_PARTY:
					writeln("Third Party");
					break;
				case GL_DEBUG_SOURCE_APPLICATION:
					writeln("Source Application");
					break;
				case GL_DEBUG_SOURCE_OTHER:
					writeln("Miscellaneous");
					break;
				default:
					assert(false);
			}

			write("\tType: ");
			switch (type) {
				case GL_DEBUG_TYPE_ERROR:
					writeln("Error ╮(. ❛ ᴗ ❛.)╭");
					break;
				case GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR:
					writeln("Deprecated usage");
					break;
				case GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR:
					writeln("Undefined behaviour");
					break;
				case GL_DEBUG_TYPE_PORTABILITY:
					writeln("System portability");
					break;
				case GL_DEBUG_TYPE_PERFORMANCE:
					writeln("Performance Issues");
					break;
				case GL_DEBUG_TYPE_MARKER:
					writeln("\"Command stream annotation\"");
					break;
				case GL_DEBUG_TYPE_PUSH_GROUP:
					writeln("\"Group pushing\"");
					break;
				case GL_DEBUG_TYPE_POP_GROUP:
					writeln("\"Group popping\"");
					break;
				case GL_DEBUG_TYPE_OTHER:
					writeln("Miscellaneous");
					break;
				default:
					assert(false);
			}

			write("\tSeverity: ");
			switch (severity) {
				case GL_DEBUG_SEVERITY_HIGH:
					writeln("High");
					break;
				case GL_DEBUG_SEVERITY_MEDIUM:
					writeln("Medium");
					break;
				case GL_DEBUG_SEVERITY_LOW:
					writeln("Low");
					break;
				case GL_DEBUG_SEVERITY_NOTIFICATION:
					writeln("Notification (Miscellaneous)");
					break;
				default:
					assert(false);
			}

			writeln("\tMessage: " ~ message.to!string);
		} catch (Exception e) {
		}
	}
}
