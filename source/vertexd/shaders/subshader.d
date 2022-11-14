module vertexd.shaders.subshader;
import bindbc.opengl;
import vertexd.core.mat : precision;
import vertexd.shaders;
import std.regex;
import std.conv : to;
import std.stdio : writeln;

alias VertexShader = SubShader!GL_VERTEX_SHADER;
alias FragmentShader = SubShader!GL_FRAGMENT_SHADER;

class SubShader(uint type)
		if (type == GL_VERTEX_SHADER || type == GL_FRAGMENT_SHADER) {
	package uint id;

	static SubShader!(type)[string] shaders;

	private string get_error_message() {
		int length;
		glGetShaderiv(this.id, GL_INFO_LOG_LENGTH, &length);
		if (length == 0)
			return "";
		char[] notification = new char[length];
		glGetShaderInfoLog(this.id, length, null, &notification[0]);
		return cast(string) notification.idup;
	}

	this(string source) {
		this.id = glCreateShader(type);
		writeln("SubShader(" ~ (type == GL_VERTEX_SHADER ? "VertexShader" : "FragmentShader") ~
				") created: " ~ id.to!string);
		writeln(source);

		auto p = source.ptr;
		int l = cast(int) source.length;
		glShaderSource(id, 1, &p, &l);
		glCompileShader(id);

		int completed;
		glGetShaderiv(id, GL_COMPILE_STATUS, &completed);
		if (completed == 0)
			throw new ShaderException(
				"Could not build SubShader " ~ id.to!string ~ ":\n__" ~ get_error_message());
		else
			writeln("Completed, errormessage log: " ~ get_error_message());

		this.shaders[source] = this;
	}

	~this() {
		import core.stdc.stdio : printf;

		glDeleteShader(id);
		printf("SubShader removed: %u\n", id);
	}
}
