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

extern (C) void window_size_callback(GLFWwindow* glfw_window, int width, int height) nothrow {
	Window window = Window.windows[glfw_window];
	window.width = width;
	window.height = height;
}

extern (C) void framebuffer_size_callback(GLFWwindow* window, int width, int height) nothrow {
	glViewport(0, 0, width, height);
}

enum MouseType {
	NORMAL = GLFW_CURSOR_NORMAL,
	CAPTURED = GLFW_CURSOR_DISABLED,
	INVISIBLE = GLFW_CURSOR_HIDDEN
}

class Window {
	// mixin ID!true;
	string name;
	union {
		Vec!(2, int) bounds;
		struct {
			int width;
			int height;
		}
	}

	GLFWwindow* glfw_window;
	static package Window[GLFWwindow* ] windows;

	struct Hints {
		static immutable int[] glfwMapping = [GLFW_RESIZABLE, GLFW_VISIBLE, GLFW_DECORATED, GLFW_FOCUSED, GLFW_AUTO_ICONIFY, GLFW_FLOATING, GLFW_MAXIMIZED, GLFW_CENTER_CURSOR, GLFW_TRANSPARENT_FRAMEBUFFER, GLFW_FOCUS_ON_SHOW, GLFW_SCALE_TO_MONITOR];
		bool resizable = true;
		bool visible = true;
		bool decorated = true;
		bool focused = true;
		bool auto_iconify = true;
		bool floating = false;
		bool maximized = false;
		bool center_cursor = true;
		bool transparent_framebuffer = false;
		bool focus_on_show = true;
		bool scale_to_monitor = false;
	}

	this(string name = "VertexD", int glfw_width = 960, int glfw_height = 540, Hints hints = Hints()) {
		this.name = name;
		this.width = glfw_width;
		this.height = glfw_height;

		glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
		glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 6);
		debug glfwWindowHint(GLFW_OPENGL_DEBUG_CONTEXT, true);

		static foreach(i; 0..hints.tupleof.length)
			glfwWindowHint(hints.glfwMapping[i], hints.tupleof[i]);

		this.glfw_window = glfwCreateWindow(glfw_width, glfw_height, name.ptr, null, null);
		enforce(glfw_window !is null, "GLFW could not create a window.");

		Window.windows[glfw_window] = this;
		glfwMakeContextCurrent(glfw_window); // TODO: multithreading
		// glfwSwapInterval(0); Can use vsynch with 1

		InputManager.register(this);
		glfwSetInputMode(glfw_window, GLFW_LOCK_KEY_MODS, GLFW_TRUE);
		glfwSetWindowSizeCallback(glfw_window, &window_size_callback);
		glfwSetFramebufferSizeCallback(glfw_window, &framebuffer_size_callback);

		GLSupport opengl_version = loadOpenGL();
		enforce(opengl_version == GLSupport.gl46, "OpenGL not loading: " ~ opengl_version
				.to!string);
		enforce(hasARBBindlessTexture, "No support for bindless textures");

		debug {
			glEnable(GL_DEBUG_OUTPUT);
			glEnable(GL_DEBUG_OUTPUT_SYNCHRONOUS);
			glDebugMessageCallback(&gl_error_callback, null);
			glDebugMessageControl(GL_DONT_CARE, GL_DONT_CARE, GL_DEBUG_SEVERITY_NOTIFICATION, 0, null, false);
		}

		glEnable(GL_MULTISAMPLE);
		glEnable(GL_DEPTH_TEST);
		glEnable(GL_CULL_FACE);
	}

	~this() {
		Window.windows.remove(glfw_window);
		glfwDestroyWindow(glfw_window);
		writeln(i"Window#${glfw_window} removed.");
	}

	void close(bool close = true) nothrow {
		glfwSetWindowShouldClose(glfw_window, close);
	}

	// TODO
	// void draw() {
	// 	assert(world !is null, "No world set.");
	// 	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT); // Clean the screen
	// 	glfwSwapBuffers(glfw_window);
	// }

	void focus() {
		glfwFocusWindow(glfw_window);
	}

	void show() {
		glfwShowWindow(glfw_window);
	}

	void hide() {
		glfwHideWindow(glfw_window);
	}

	void setFloating(bool floating){
		glfwSetWindowAttrib(glfw_window, GLFW_FLOATING, floating);
	}

	/// See_Also: setAspectRatio, setSize, setSizeLimit
	void setResizable(bool resizable){
		glfwSetWindowAttrib(glfw_window, GLFW_RESIZABLE, resizable);
	}

	void setDecorated(bool decorated){
		glfwSetWindowAttrib(glfw_window, GLFW_DECORATED, decorated);
	}

	void setBackgroundColor(float[4] rgba...) {
		glClearColor(rgba[0], rgba[1], rgba[2], rgba[3]);
	}

	void setMouseType(MouseType type) {
		glfwSetInputMode(glfw_window, GLFW_CURSOR, type);
	}

	void setAspectRatio(int[2] aspect ...) {
		glfwSetWindowAspectRatio(glfw_window, aspect[0], aspect[1]);
	}

	void unsetAspectRatio() {
		glfwSetWindowAspectRatio(glfw_window, GLFW_DONT_CARE, GLFW_DONT_CARE);
	}

	void setSize(int[2] size ...) {
		glfwSetWindowSize(glfw_window, size[0], size[1]);
	}

	/// Sets minimum & maximum size limits for window.
	/// Note -1 disables individual limits.
	void setSizeLimit(int width_min, int height_min, int width_max, int height_max) {
		glfwSetWindowSizeLimits(glfw_window, width_min, height_min, width_max, height_max);
	}

	/// Set top left coordinate of window.
	void setPosition(int[2] pos ...) {
		glfwSetWindowPos(glfw_window, pos[0], pos[1]);
	}

	/// Get top left coordinate of window.
	Vec!(2, int) getPosition() {
		Vec!(2, int) pos;
		glfwGetWindowPos(glfw_window, &pos.x, &pos.y);
		return pos;
	}

	void setName(string name) {
		debug writeln(i"Renaming window \"${this.name}\" to \"${name}\"");
		this.name = name;
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
