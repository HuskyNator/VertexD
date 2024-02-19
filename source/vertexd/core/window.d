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
import std.string : toStringz;
import vertexd.misc;
import vertexd.world;

enum MouseType {
	NORMAL = GLFW_CURSOR_NORMAL,
	INVISIBLE = GLFW_CURSOR_HIDDEN,
	CAPTURED = GLFW_CURSOR_DISABLED
}

class Window {
public:
	InputManager inputManager;
	string title;
	int width;
	int height;

	void bind(InputManager manager) {
		this.inputManager = inputManager;
		glfwSetKeyCallback(glfw_window, &inputManager.key_callback);
		glfwSetMouseButtonCallback(glfw_window, &inputManager.button_callback);
	}

	void unbind() {
		this.inputManager = null;
		glfwSetKeyCallback(glfw_window, null);
		glfwSetMouseButtonCallback(glfw_window, null);
	}

private:
	GLFWwindow* glfw_window;
	GLFWimage[] icons;

	Vec!(2, int) windowPos; // global (virtual)
	Vec!(2, double) mousePos; // on window
	Vec!(2, double) mouseWheel;
	bool mouseHover;

	static void setStandardVisible(bool visible) {
		glfwWindowHint(GLFW_VISIBLE, visible);
	}

	static void setStandardBorder(bool rand) {
		glfwWindowHint(GLFW_DECORATED, rand);
	}

	static void setStandardTransparency(bool transparent) {
		glfwWindowHint(GLFW_TRANSPARENT_FRAMEBUFFER, transparent);
	}

	void setWindowCallbacks() {
		glfwSetWindowPosCallback(glfw_window, &window_position_callback);
		glfwSetCursorPosCallback(glfw_window, &mouse_position_callback);
		glfwSetScrollCallback(glfw_window, &mouse_wheel_callback);
		glfwSetCursorEnterCallback(glfw_window, &mouse_enter_callback);

		glfwSetWindowSizeCallback(glfw_window, &window_size_callback);
		glfwSetFramebufferSizeCallback(glfw_window, &framebuffer_size_callback);
	}

	/// See_Also: Engine.createWindow
	package this(string title = "VertexD", int width = 960, int height = 540, Window share = null) {
		// C null terminated string:
		if (title is null || title.length == 0)
			title = "\0";
		else if (title.length > 0 && title[$] != '\0')
			title = title ~ '\0';
		this.title = title;
		this.width = width;
		this.height = height;

		this.keyInput = new KeyInput[typeof(GLFW_KEY_LAST)];
		this.mouseButtonInput = new MouseButtonInput[typeof(GLFW_MOUSE_BUTTON_LAST)];

		this.glfw_window = glfwCreateWindow(width, height, title.ptr, null, share.glfw_window);
		enforce(glfw_window !is null, "GLFW could not create a window.");
		glfwMakeContextCurrent(glfw_window); // TODO: multithreading
		glfwSetWindowUserPointer(glfw_window, cast(void*) this);

		// glfwSwapInterval(0); Can use vsynch with 1
		setWindowCallbacks(glfw_window);
	}

	~this() {
		glfwDestroyWindow(glfw_window);
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
		this.icons = new GLFWimage[images.length];
		foreach (i, Image* image; images)
			this.icons[i] = GLFWimage(image.width(), image.height(), image.allPixelsAtOnce().dup.ptr);

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

		// TODO: scrap? :
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
}

extern (C) void window_position_callback(GLFWwindow* glfw_window, int x, int y) {
	Window* window = cast(Window*) glfwGetWindowUserPointer(glfw_window);
	window.windowPos = Vec!(2, int)(x, y);
}

extern (C) void mouse_position_callback(GLFWwindow* glfw_window, double x, double y) {
	Window* window = cast(Window*) glfwGetWindowUserPointer(glfw_window);
	window.mousePos = Vec!(2, double)(x, y);
}

extern (C) void mouse_wheel_callback(GLFWwindow* glfw_window, double x, double y) {
	Window* window = cast(Window*) glfwGetWindowUserPointer(glfw_window);
	window.mouseWheel = Vec!(2, double)(x, y);
}

extern (C) void mouse_enter_callback(GLFWwindow* glfw_window, int entered) {
	Window* window = cast(Window*) glfwGetWindowUserPointer(glfw_window);
	window.mouseHover = entered;
}

extern (C) void window_size_callback(GLFWwindow* glfw_window, int width, int height) nothrow {
	Window* window = cast(Window*) glfwGetWindowUserPointer(glfw_window);
	window.width = width;
	window.height = height;
}

extern (C) void framebuffer_size_callback(GLFWwindow* window, int width, int height) nothrow {
	glViewport(0, 0, width, height);
}
