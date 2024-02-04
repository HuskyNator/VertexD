module vertexd.core.window;

import bindbc.glfw;
import bindbc.opengl;
import bindbc.opengl.bind.arb.arb_01 : hasARBBindlessTexture;
import gamut;
import std.container.rbtree;
import std.conv : to;
import std.exception : enforce;
import std.stdio : write, writeln;
import vertexd.core;
import vertexd.misc;
import vertexd.world;

struct KeyInput {
	int key, key_id, event, modifier;
}

struct MouseButtonInput {
	int button, event, modifier;
}

alias MousePositionInput = Vec!(2, double);
alias MouseWheelInput = Vec!(2, double);
alias MouseEnterInput = bool;

alias KeyCallback = void delegate(KeyInput input);
alias MouseButtonCallback = void delegate(MouseButtonInput input);
alias MousePositionCallback = void delegate(MousePositionInput input);
alias MouseWheelCallback = void delegate(MouseWheelInput input);
alias MouseEnterCallback = void delegate(MouseEnterInput entered);

enum MouseType {
	NORMAL = GLFW_CURSOR_NORMAL,
	CAPTURED = GLFW_CURSOR_DISABLED,
	INVISIBLE = GLFW_CURSOR_HIDDEN
}

class Window {
public:
	string title;
	int width;
	int height;
	World world;

private:
	GLFWwindow* glfw_window;
	GLFWimage[] icons;

	// Input
	KeyCallback[] keyCallbacks = [];
	MouseButtonCallback[] mouseButtonCallbacks = [];
	MousePositionCallback[] mousePositionCallbacks = [];
	MouseWheelCallback[] mouseWheelCallbacks = [];
	MouseEnterCallback[] mouseEnterCallbacks = [];

	KeyInput[typeof(GLFW_KEY_LAST)] keyInput;
	MousePositionInput[] mousePositionInput = [];
	MouseButtonInput[typeof(GLFW_MOUSE_BUTTON_LAST)] mouseButtonInput;
	MouseWheelInput[] mouseWheelInput = [];
	MouseEnterInput[] mouseEnterInput = [];

	package static Window[] windows;

	static void setStandardVisible(bool visible) {
		glfwWindowHint(GLFW_VISIBLE, visible);
	}

	static void setStandardBorder(bool rand) {
		glfwWindowHint(GLFW_DECORATED, rand);
	}

	static void setStandardTransparency(bool transparent) {
		glfwWindowHint(GLFW_TRANSPARENT_FRAMEBUFFER, transparent);
	}

	this(string title = "VertexD", int glfw_width = 960, int glfw_height = 540) {
		if (windows.length == 0)
			vdInit();

		this.title = title;
		this.width = glfw_width;
		this.height = glfw_height;

		this.keyInput = new KeyInput[typeof(GLFW_KEY_LAST)];
		this.mouseButtonInput = new MouseButtonInput[typeof(GLFW_MOUSE_BUTTON_LAST)];

		glfwWindowHint(GLFW_SAMPLES, 4); //TODO: on/off multisampling

		glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
		glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 6);
		glfwWindowHint(GLFW_CENTER_CURSOR, false);

		debug glfwWindowHint(GLFW_OPENGL_DEBUG_CONTEXT, true);
		this.glfw_window = glfwCreateWindow(glfw_width, glfw_height, title.ptr, null, null);
		assert(glfw_window !is null, "GLFW coult not create a window.");
		glfwSetWindowUserPointer(glfw_window, cast(void*) this);
		windows ~= this;

		glfwMakeContextCurrent(glfw_window); // TODO: multithreading
		// glfwSwapInterval(0); Can use vsynch with 1

		glfwSetKeyCallback(glfw_window, &window_key_callback);
		glfwSetMouseButtonCallback(glfw_window, &window_mousebutton_callback);
		glfwSetCursorPosCallback(glfw_window, &window_mouseposition_callback);
		glfwSetScrollCallback(glfw_window, &windows_mousewheel_callback);
		glfwSetCursorEnterCallback(glfw_window, &windows_mouse_enter_callback);
		glfwSetFramebufferSizeCallback(glfw_window, &framebuffer_size_callback);

		// glfwSetCursorPos(glfw_window, 0, 0); //TODO: scrap?

		GLSupport opengl_version = loadOpenGL();
		enforce(opengl_version == GLSupport.gl46, "OpenGL not loading: " ~ opengl_version.to!string);
		enforce(hasARBBindlessTexture, "No support for bindless textures");

		debug {
			glEnable(GL_DEBUG_OUTPUT);
			glEnable(GL_DEBUG_OUTPUT_SYNCHRONOUS);
			glDebugMessageCallback(&gl_error_callback, null);
			glDebugMessageControl(GL_DONT_CARE, GL_DONT_CARE, GL_DEBUG_SEVERITY_NOTIFICATION, 0, null, false);
		}

		glEnable(GL_MULTISAMPLE); //TODO: on/off multisampling
		glEnable(GL_DEPTH_TEST);
		glEnable(GL_CULL_FACE);
	}

	~this() {
		glfwDestroyWindow(glfw_window);
		windows.remove(this);
		if (windows.length == 0)
			vdTerminate();
	}

	void setTitle(string title) {
		glfwSetWindowTitle(glfw_window, title.ptr);
		this.title = title;
	}

	void setSize(int width, int height) {
		glfwSetWindowSize(glfw_window, width, height);
		this.width = width;
		this.height = height;
	}

	/// Sets minimum & maximum size limits for window.
	///
	/// Note -1 disables individual limits.
	void setSizeLimit(int width_min, int height_min, int width_max, int height_max) {
		glfwSetWindowSizeLimits(glfw_window, width_min, height_min, width_max, height_max);
	}

	/// Locks ratio
	void lockAspectRatio(int width, int height) {
		glfwSetWindowAspectRatio(glfw_window, width, height);
	}

	/// Unlocks ratio
	void unlockAspectRatio() {
		glfwSetWindowAspectRatio(glfw_window, GLFW_DONT_CARE, GLFW_DONT_CARE);
	}

	/// Set top left coordinate of window.
	void setPosition(int x, int y) {
		glfwSetWindowPos(glfw_window, x, y);
	}

	/// Get top left coordinate of window.
	Vec!(2, int) getPosition() {
		Vec!(2, int) pos;
		glfwGetWindowPos(glfw_window, &pos.x, &pos.y);
		return pos;
	}

	void setBackgroundColor(Vec!(4, float) color) {
		glClearColor(color.x, color.y, color.z, color.w);
	}

	void setIcon(Image*[] images) { // RGBA8 images
		icons = new GLFWimage[images.length];
		foreach (i, Image* image; images)
			icons[i] = GLFWimage(image.width(), image.height(), image.allPixelsAtOnce().dup.ptr);

		glfwSetWindowIcon(glfw_window, cast(int) icons.length, icons.ptr);
	}

	void unsetIcon() {
		glfwSetWindowIcon(glfw_window, 0, null);
		icons = [];
	}

	void draw() {
		assert(world !is null, "No world set.");
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT); // Clean the screen
		world.draw();
		glfwSwapBuffers(glfw_window);
	}

	void focus() {
		glfwFocusWindow(glfw_window);
	}

	void show() {
		glfwShowWindow(glfw_window);

		// TODO: scrap :
		// glClear(GL_COLOR_BUFFER_BIT);
		// glfwSwapBuffers(glfw_window);
	}

	void hide() {
		glfwHideWindow(glfw_window);
	}

	/// Sets flag the window should be closed
	// Note actual closure happens upon the deconstructor being called
	void close() nothrow {
		glfwSetWindowShouldClose(glfw_window, true);
	}

	/// Signals the windows should actually not be closed.
	void dontClose() nothrow {
		glfwSetWindowShouldClose(glfw_window, false);
	}

	void setMouseType(MouseType type) {
		glfwSetInputMode(glfw_window, GLFW_CURSOR, type);
	}

	void processInput() {
		// Retains order of input for all callbacks
		foreach (KeyInput input; keyInput)
			foreach (KeyCallback callback; keyCallbacks)
				callback(input);
		foreach (MouseButtonInput input; mouseButtonInput)
			foreach (MouseButtonCallback callback; mouseButtonCallbacks)
				callback(input);
		foreach (MousePositionInput input; mousePositionInput)
			foreach (MousePositionCallback callback; mousePositionCallbacks)
				callback(input);
		foreach (MouseWheelInput input; mouseWheelInput)
			foreach (MouseWheelCallback callback; mouseWheelCallbacks)
				callback(input);
		foreach (MouseEnterInput input; mouseEnterInput)
			foreach (MouseEnterCallback callback; mouseEnterCallbacks)
				callback(input);
	}

	enum Event {
		NONE = 4,
		PRESS = GLFW_PRESS,
		RELEASE = GLFW_RELEASE,
		REPEAT = GLFW_REPEAT
	}

	// TODO: find better polling method
	// TODO: Check what the modifier is with absence or double modifier
	public Event getKey(int key) {
		foreach (KeyInput i; this.keyInput)
			if (i.key == key)
				return cast(Event) i.event;
		return Event.NONE;
	}

	public Event getButton(int button) {
		foreach (MouseButtonInput i; this.mouseButtonInput)
			if (i.button == button)
				return cast(Event) i.event;
		return Event.NONE;
	}

	void clearInput() {
		keyInput.clear();
		mouseButtonInput.clear();
		mousePositionInput.length = 0;
		mouseWheelInput.length = 0;
		mouseEnterInput.length = 0;
	}

	unittest {
		import vertexd.core;

		vdInit();
		Window.setStandardTransparency(true);
		Window window = new Window();
		window_key_callback(window.glfw_window, GLFW_KEY_A, 0, GLFW_PRESS, 0);
		window.processInput();
		assert(window.getKey(GLFW_KEY_A) == GLFW_PRESS);
	}
}

extern (C) void windows_size_callback(GLFWwindow* glfw_window, int width, int height) nothrow {
	Window* window = cast(Window*) glfwGetWindowUserPointer(glfw_window);
	window.width = width;
	window.height = height;
}

extern (C) void framebuffer_size_callback(GLFWwindow* window, int width, int height) nothrow {
	glViewport(0, 0, width, height);
}

extern (C) void window_key_callback(GLFWwindow* glfw_window, int key, int key_code, int event, int modifier) nothrow {
	debug {
		import core.sys.windows.windows;

		if (key == GLFW_KEY_GRAVE_ACCENT) {
			ShowWindow(console, console_visible ? SW_HIDE : SW_RESTORE);
			glfwFocusWindow(glfw_window);
			console_visible = !console_visible;
		}
	}
	Window* window = cast(Window*) glfwGetWindowUserPointer(glfw_window);
	KeyInput input = KeyInput(key, key_code, event, modifier);
	window.keyInput[key] = input;

	if (key == GLFW_KEY_ESCAPE)
		glfwSetWindowShouldClose(glfw_window, true);
}

extern (C) void window_mousebutton_callback(GLFWwindow* glfw_window, int button, int event, int modifier) nothrow {
	Window* window = cast(Window*) glfwGetWindowUserPointer(glfw_window);
	MouseButtonInput input = MouseButtonInput(button, event, modifier);
	window.mouseButtonInput[button] = input;
	import vertexd.misc : tryWriteln;

	tryWriteln(input);
}

extern (C) void window_mouseposition_callback(GLFWwindow* glfw_window, double x, double y) nothrow {
	Window* window = cast(Window*) glfwGetWindowUserPointer(glfw_window);
	MousePositionInput input = MousePositionInput(x, y);
	window.mousePositionInput ~= input;
}

extern (C) void windows_mousewheel_callback(GLFWwindow* glfw_window, double x, double y) nothrow {
	Window* window = cast(Window*) glfwGetWindowUserPointer(glfw_window);
	MouseWheelInput input = MouseWheelInput(x, y);
	window.mouseWheelInput ~= input;
}

extern (C) void windows_mouse_enter_callback(GLFWwindow* glfw_window, int entered) nothrow {
	Window* window = cast(Window*) glfwGetWindowUserPointer(glfw_window);
	window.mouseEnterInput ~= entered == GLFW_TRUE;
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
