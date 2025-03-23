module vertexd.shaders.shader;

import bindbc.opengl;
import std.conv : to;
import std.file : exists, readText;
import std.path : extension;
import std.stdio : write, writeln;
import vertexd.shaders;

class Shader {
	Type type;
	uint shader;
	string source;

	enum Type {
		COMPUTE = GL_COMPUTE_SHADER,
		VERTEX = GL_VERTEX_SHADER,
		TESS_CONTROL = GL_TESS_CONTROL_SHADER,
		TESS_EVALUATION = GL_TESS_EVALUATION_SHADER,
		GEOMETRY = GL_GEOMETRY_SHADER,
		FRAGMENT = GL_FRAGMENT_SHADER
	}

	private static Type extensionToType(string extension) {
		switch (extension) {
			case ".vert":
				return Type.VERTEX;
			case ".tesc":
				return Type.TESS_CONTROL;
			case ".tese":
				return Type.TESS_EVALUATION;
			case ".geom":
				return Type.GEOMETRY;
			case ".frag":
				return Type.FRAGMENT;
			case ".comp":
				return Type.COMPUTE;
			default:
				throw new ShaderException("file extension does not match shader type: " ~ extension);
		}
	}

	final string getInfoLog() {
		int length;
		glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &length);
		if (length == 0)
			return "";
		char[] notification = new char[length];
		glGetShaderInfoLog(shader, length, null, &notification[0]);
		return cast(string) notification.idup;
	}

	final void assertCompiled() {
		int completed;
		glGetShaderiv(shader, GL_COMPILE_STATUS, &completed);
		string infoLog = getInfoLog();

		if (completed == 0)
			throw new ShaderException(
				"Could not compile SubShader " ~ shader.to!string ~ ":\n__" ~ infoLog);

		if (infoLog.length > 0)
			writeln("SubShader compilation completed, infolog: " ~ infoLog);
		else
			writeln("SubShader compilation completed, infolog empty");
	}

	this(string file) {
		string ext = extension(file);
		Type type = extensionToType(ext);
		assert(exists(file), "Could not find file: " ~ file);
		this(readText(file), type);
	}

	this(string source, Type type) {
		this.source = source;
		this.type = type;
	}

	void initialize() {
		if (this.shader != 0)
			return;
		this.shader = glCreateShader(type);
		writeln("SubShader(" ~ type.to!string ~ ") created: " ~ shader.to!string);

		auto p = source.ptr;
		int l = cast(int) source.length;
		glShaderSource(shader, 1, &p, &l);
		glCompileShader(shader);
		assertCompiled();
	}

	~this() {
		glDeleteShader(shader);
		write("SubShader removed: ", shader);
	}

	override string toString() const {
		return type.to!string ~ '#' ~ shader.to!string;
	}
}
