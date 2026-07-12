module vertexd.core.window;

import bindbc.glfw;
import bindbc.opengl;
import bindbc.opengl.bind.arb.arb_01 : hasARBBindlessTexture;
import std.container.rbtree;
import std.conv : to;
import std.exception : enforce;
import std.stdio : write, writeln;
import vertexd.core;
import vertexd.world;
import vertexd.gui2.ui_element;

// TODO: SEE IF CALLBACKS GET CALLED WHEN GLFW SETS SIZE (INSTEAD OF USER)

extern (C) void window_size_callback(GLFWwindow* glfw_window, int width, int height) nothrow {
	Window window = Window.windows[glfw_window];
	window.width = width;
	window.height = height;
	window.lastSizePosUpdateFrame = Time.frameID();
}

extern (C) void framebuffer_size_callback(GLFWwindow* glfw_window, int width, int height) nothrow {
	glViewport(0, 0, width, height);
	Window window = Window.windows[glfw_window];
	window.pixelWidth = width;
	window.pixelHeight = height;
	window.lastSizePosUpdateFrame = Time.frameID();

	if (!(window.resizeDraw is null))
		window.resizeDraw(window);
}

extern (C) void window_position_callback(GLFWwindow* glfw_window, int xPos, int yPos) nothrow {
	Window window = Window.windows[glfw_window];
	window.windowPosition = Vec!(2, int)(xPos, yPos);
	window.lastSizePosUpdateFrame = Time.frameID();
}

enum MouseType {
	NORMAL = GLFW_CURSOR_NORMAL,
	CAPTURED = GLFW_CURSOR_DISABLED,
	INVISIBLE = GLFW_CURSOR_HIDDEN
}

class Window {
	static package Window[GLFWwindow* ] windows;
	mixin ID;
	string name;
	GLFWwindow* glfw_window;
	void delegate(Window) nothrow resizeDraw;
	UiElement root;

	union {
		struct {
			int width;
			int height;
		}

		Vec!(2, int) size;
	}

	union {
		struct {
			int pixelWidth;
			int pixelHeight;
		}

		Vec!(2, int) pixelSize;
	}

	float aspectRatio() const {
		return (cast(float) pixelWidth) / pixelHeight;
	}

	Vec!(2, int) windowPosition;
	Vec!(2, double) mousePosition;
	ulong lastSizePosUpdateFrame = 0;

	struct Hints {
		bool resizable = true; // resizable by user, ignored for fullscreen or undecorated
		bool visible = true; // initialy visible, ignored for fullscreen
		bool decorated = true; // window decorates (border, close widget etc.)
		bool focused = true; // input focus on creation
		bool auto_iconify = true; // automatically iconify (minimize) & restore video mode in fullscreen on focus loss
		bool floating = false; // always floating on top
		bool maximized = false; // maximized when created
		bool center_cursor = true; // cursor should be centered on new window
		bool transparent_framebuffer = false; // transparent window framebuffer if supported
		bool focus_on_show = true; // window gets input focus on `glfwShowWindow` is called
		bool scale_to_monitor = false; // resize window content area based on `content scale` changes (eg. monitors), affects platforms with 1:1 screen coordinate:pixel mappings like Windows
		bool scale_framebuffer = true; // resize framebuffer based on `content scale` changes (eg. monitors), affects platforms with scalable screen coordinate:pixel mappings like maxOS
		bool mouse_passthrough = false; // pass on mouse input to any window behind the window in question, decorated behavior differs by platform
		int position_x = anyPosition; // initial window x position
		int position_y = anyPosition; // initial window y position
		/// desired bit depths of default framebuffer:
		int red_bits = 8;
		int green_bits = 8;
		int blue_bits = 8;
		int alpha_bits = 8;
		int depth_bits = 2;
		int stencil_bits = 8;
		int samples = 0; // number of samples for multisampling
		int refresh_rate = dontCare; // refresh rate for fullscreen (dontCare = highest)
		bool stereo = false; // OpenGL stereoscopic rendering
		bool srgb_capable = false; // srgb capable framebuffer
		bool double_buffer = true; // double buffered framebuffer

		static enum int anyPosition = GLFW_ANY_POSITION;
		static enum int dontCare = GLFW_DONT_CARE;

		static enum int[] glfwMapping = [
			GLFW_RESIZABLE,
			GLFW_VISIBLE,
			GLFW_DECORATED,
			GLFW_FOCUSED,
			GLFW_AUTO_ICONIFY,
			GLFW_FLOATING,
			GLFW_MAXIMIZED,
			GLFW_CENTER_CURSOR,
			GLFW_TRANSPARENT_FRAMEBUFFER,
			GLFW_FOCUS_ON_SHOW,
			GLFW_SCALE_TO_MONITOR,
			GLFW_SCALE_FRAMEBUFFER,
			GLFW_MOUSE_PASSTHROUGH,
			GLFW_POSITION_X,
			GLFW_POSITION_Y,
			GLFW_RED_BITS,
			GLFW_GREEN_BITS,
			GLFW_BLUE_BITS,
			GLFW_ALPHA_BITS,
			GLFW_DEPTH_BITS,
			GLFW_STENCIL_BITS,
			GLFW_SAMPLES,
			GLFW_REFRESH_RATE,
			GLFW_STEREO,
			GLFW_SRGB_CAPABLE,
			GLFW_DOUBLEBUFFER
		];
	}

	this(string name = "VertexD", int width = 960, int height = 540, bool vsynch = true,
		Hints hints = Hints(), void delegate(Window) nothrow resizeDraw = null) {
		setID();
		this.name = name;
		this.width = width;
		this.height = height;
		this.resizeDraw = resizeDraw;

		glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
		glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 6);
		debug glfwWindowHint(GLFW_OPENGL_DEBUG_CONTEXT, true);

		static foreach (i; 0 .. hints.tupleof.length)
			glfwWindowHint(hints.glfwMapping[i], hints.tupleof[i]);

		this.glfw_window = glfwCreateWindow(width, height, name.ptr, null, null);
		enforce(glfw_window !is null, "GLFW could not create a window.");

		Window.windows[glfw_window] = this;
		glfwMakeContextCurrent(glfw_window); // TODO: multithreading
		glfwSwapInterval(vsynch);

		InputManager.register(this);
		glfwSetInputMode(glfw_window, GLFW_LOCK_KEY_MODS, GLFW_TRUE);
		glfwSetWindowSizeCallback(glfw_window, &window_size_callback);
		glfwSetFramebufferSizeCallback(glfw_window, &framebuffer_size_callback);
		glfwSetWindowPosCallback(glfw_window, &window_position_callback);

		GLSupport opengl_version = loadOpenGL();
		enforce(opengl_version == GLSupport.gl46, "OpenGL version 4.6 required, got: " ~ opengl_version
				.to!string);
		version (OpenGLBindless)
			enforce(hasARBBindlessTexture, "No support for bindless textures");

		// debug {
		glEnable(GL_DEBUG_OUTPUT);
		glEnable(GL_DEBUG_OUTPUT_SYNCHRONOUS);
		glDebugMessageCallback(&gl_error_callback, null);
		glDebugMessageControl(GL_DONT_CARE, GL_DONT_CARE, GL_DEBUG_SEVERITY_NOTIFICATION, 0, null, false);
		// }

		glEnable(GL_MULTISAMPLE);
		glEnable(GL_DEPTH_TEST);
		glEnable(GL_CULL_FACE);

		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

		glfwGetFramebufferSize(glfw_window, &pixelWidth, &pixelHeight);
	}

	void updateBoundsTree() {
		if (root !is null)
			root.updateBoundsTree(this);
	}

	~this() {
		Window.windows.remove(glfw_window);
		glfwDestroyWindow(glfw_window);
		writeln(i"Window#$(glfw_window) removed.");
	}

	void close(bool close = true) nothrow {
		glfwSetWindowShouldClose(glfw_window, close);
	}

	bool shouldClose() {
		return glfwWindowShouldClose(glfw_window) >= 1;
	}

	static bool testShouldClose() {
		Window[] closeArr;
		foreach (glfw_window, window; Window.windows)
			if (window.shouldClose())
				closeArr ~= window;
		foreach (window; closeArr)
			destroy(window);
		return Window.windows.length == 0;
	}

	void swapBuffers() {
		glfwSwapBuffers(glfw_window);
	}

	void clearColorBuffer() {
		glClear(GL_COLOR_BUFFER_BIT);
	}

	void clearDepthBuffer() {
		glClear(GL_DEPTH_BUFFER_BIT);
	}

	void clearBuffers() { // TODO: multiple windows
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	}

	static void setBackgroundColor(float[4] rgba...) {
		glClearColor(rgba[0], rgba[1], rgba[2], rgba[3]);
	}

	void focus() {
		glfwFocusWindow(glfw_window);
	}

	void show() {
		glfwShowWindow(glfw_window);
	}

	void hide() {
		glfwHideWindow(glfw_window);
	}

	void setFloating(bool floating) {
		glfwSetWindowAttrib(glfw_window, GLFW_FLOATING, floating);
	}

	/// See_Also: setAspectRatio, setSize, setSizeLimit
	void setResizable(bool resizable) {
		glfwSetWindowAttrib(glfw_window, GLFW_RESIZABLE, resizable);
	}

	void setDecorated(bool decorated) {
		glfwSetWindowAttrib(glfw_window, GLFW_DECORATED, decorated);
	}

	void setMouseMode(MouseType type) {
		glfwSetInputMode(glfw_window, GLFW_CURSOR, type);
	}

	void setMouseModeRaw(bool on) {
		// TODO: bugfix in bindbc
		// if (!glfwRawMouseMotionSupported())
		// 	writeln("Raw mouse movement not supported on this device.");
		// else
		glfwSetInputMode(glfw_window, GLFW_RAW_MOUSE_MOTION, on);
	}

	void setAspectRatio(int[2] aspect...) {
		glfwSetWindowAspectRatio(glfw_window, aspect[0], aspect[1]);
	}

	void unsetAspectRatio() {
		glfwSetWindowAspectRatio(glfw_window, GLFW_DONT_CARE, GLFW_DONT_CARE);
	}

	void setSize(int[2] size...) {
		glfwSetWindowSize(glfw_window, size[0], size[1]);
	}

	/// Sets minimum & maximum size limits for window.
	/// Note -1 disables individual limits.
	void setSizeLimit(int width_min, int height_min, int width_max, int height_max) {
		glfwSetWindowSizeLimits(glfw_window, width_min, height_min, width_max, height_max);
	}

	/// Set top left coordinate of window.
	void setPosition(int[2] pos...) {
		glfwSetWindowPos(glfw_window, pos[0], pos[1]);
	}

	/// Get top left coordinate of window.
	Vec!(2, int) getPosition() {
		Vec!(2, int) pos;
		glfwGetWindowPos(glfw_window, &pos.x, &pos.y);
		return pos;
	}

	void setTitle(string title) {
		debug writeln(i"Renaming window \"$(this.name)\" to \"$(name)\"");
		this.name = title;
		glfwSetWindowTitle(glfw_window, name.ptr);
	}

	import gamut;

	void setIcon(Image*[] images) {
		GLFWimage[] glfw_images = new GLFWimage[images.length];
		foreach (i, Image* image; images)
			glfw_images[i] = GLFWimage(image.width(), image.height(), image.allPixelsAtOnce().ptr);

		glfwSetWindowIcon(glfw_window, cast(int) glfw_images.length, glfw_images.ptr);
	}

	void unsetIcon() {
		glfwSetWindowIcon(glfw_window, 0, null);
	}
}

// debug {
extern (System) void gl_error_callback(GLenum source, GLenum type, GLuint errorID, GLenum severity,
	GLsizei length, const GLchar* message, const void* userParam) nothrow {
	import std.stdio : write, writeln;
	import std.conv : to;
	import bindbc.opengl.bind.types;

	try {
		if (severity == GL_DEBUG_SEVERITY_NOTIFICATION)
			writeln("Opengl Notification #", errorID.to!string);
		else
			writeln("Opengl Exception #", errorID.to!string);
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

		writeln("\tMessage: ", message.to!string);
	} catch (Exception e) {
	}
}
// }
