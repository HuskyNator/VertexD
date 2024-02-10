module vertexd.core.engine;
import app;
import bindbc.glfw;
import std.stdio;
import std.conv : to;
import bindbc.opengl;

final abstract class Engine {
static private:
	public void run(App app) {
		app.update();

		//... ?

		// ??
		// if (key == GLFW_KEY_GRAVE_ACCENT) {
		// 	ShowWindow(console, console_visible ? SW_HIDE : SW_RESTORE);
		// 	glfwFocusWindow(glfw_window);
		// 	console_visible = !console_visible;
		// }

		glfwPollEvents();
	}

	// TODO: run(App[] apps...) ? (multiplex)

	void initialize() {
		glfwSetErrorCallback(&glfw_error_callback);
		glfwInit();
	}

	void destroy() {
		glfwTerminate();
	}

	void initializeOpenGL() {
		GLSupport opengl_version = loadOpenGL();
		enforce(opengl_version == GLSupport.gl46, "OpenGL not loading: " ~ opengl_version
				.to!string);
		enforce(hasARBBindlessTexture(), "No support for bindless textures");

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

}

extern (C) void glfw_error_callback(int type, const char* description) nothrow {
	try
		writefln("GLFW Exception %d: %s", type, description.to!string);
	catch (Exception e) {
	}
}

extern (System) void gl_error_callback(GLenum source, GLenum type, GLuint errorID, GLenum severity,
	GLsizei length, const GLchar* message, const void* userParam) nothrow {
	try {
		const string[uint] sources = {
			GL_DEBUG_SOURCE_API: "OpenGL API",
			GL_DEBUG_SOURCE_WINDOW_SYSTEM: "Window System API",
			GL_DEBUG_SOURCE_SHADER_COMPILER: "Shader Compiler",
			GL_DEBUG_SOURCE_THIRD_PARTY: "Third Party",
			GL_DEBUG_SOURCE_APPLICATION: "Source Application",
			GL_DEBUG_SOURCE_OTHER: "Miscellaneous"
		};
		const string[uint] types = {
			GL_DEBUG_TYPE_ERROR: "Error ╮(. ❛ ᴗ ❛.)╭",
			GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR: "Deprecated usage",
			GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR: "Undefined behaviour",
			GL_DEBUG_TYPE_PORTABILITY: "System portability",
			GL_DEBUG_TYPE_PERFORMANCE: "Performance Issues",
			GL_DEBUG_TYPE_MARKER: "\"Command stream annotation\"",
			GL_DEBUG_TYPE_PUSH_GROUP: "\"Group pushing\"",
			GL_DEBUG_TYPE_POP_GROUP: "\"Group popping\"",
			GL_DEBUG_TYPE_OTHER: "Miscellaneous"
		};
		const string[uint] severities = {
			GL_DEBUG_SEVERITY_HIGH: "High",
			GL_DEBUG_SEVERITY_MEDIUM: "Medium",
			GL_DEBUG_SEVERITY_LOW: "Low",
			GL_DEBUG_SEVERITY_NOTIFICATION: "Notification (Miscellaneous)"
		};

		writeln("Opengl Exception #", errorID);
		if (source !in sources || type !in types || severity !in severities)
			assert(0);
		writeln("\tSource: ", sources[source]);
		writeln("\tType: ", types[types]);
		writeln("\tSeverity: ", severities[severity]);
		writeln("\tMessage: ", message);
	} catch (Exception e) {
		try
			writeln(e);
		catch (Exception e) {
		}
	}
}
