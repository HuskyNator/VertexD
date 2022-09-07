module vertexd.shaders.shader;

import bindbc.opengl;
import vertexd.mesh.buffer;
import vertexd.core.mat;
import vertexd.shaders.subshader;
import std.array : replace;
import std.conv : to;
import std.regex;
import std.stdio;
import std.traits : isInstanceOf;

class ShaderException : Exception {
	this(string notification) {
		super("Error in Shader:\n" ~ notification);
	}
}

class Shader {
	public struct SourcePair {
		string vertShader, fragmentShader;
	}

	// static this() {
	// 	placeholders["precision"] = precision.stringof;
	// 	static if (is(precision == double)) {
	// 		static foreach (i; 2 .. 4) {
	// 			placeholders["vec" ~ i.stringof] = " dvec" ~ i.stringof;
	// 			placeholders["mat" ~ i.stringof] = " dmat" ~ i.stringof;
	// 		}
	// 	}
	// }

	static Shader standardShader() {
		return Shader.load(standardVertShader, standardFragShader);
	}

	// static string[string] placeholders; // see SubShader#this(file)
	static Shader[SourcePair] shaders;
	static Shader current = null;

	VertexShader vertShader;
	FragmentShader fragmentShader;
	protected uint id;

	final void use() {
		if (current is this)
			return;
		glUseProgram(id);
		current = this;
	}

	@disable this();

	private this(VertexShader vertShader, FragmentShader fragmentShader) {
		this.vertShader = vertShader;
		this.fragmentShader = fragmentShader;
		this.id = glCreateProgram();
		writeln(
			"Shader created: " ~ id.to!string ~ " (" ~ vertShader.id.to!string ~ "," ~ fragmentShader.id.to!string
				~ ")");

		glAttachShader(id, vertShader.id);
		glAttachShader(id, fragmentShader.id);
		glLinkProgram(id);

		int completed;
		glGetProgramiv(id, GL_LINK_STATUS, &completed);
		if (completed == 0)
			throw new ShaderException("Could not compose Shader " ~ id.to!string ~ ":\n_" ~ get_error_message());
	}

	~this() {
		import core.stdc.stdio : printf;

		glDeleteProgram(id);
		printf("Shader removed: %u ($u, $u)\n", id, vertShader.id, fragmentShader.id);
	}

	/// Replace placeholders
	// private static string replace(const string source, const string[string] placeholders = null) {
	// 	string source2 = source.dup;
	// 	if (placeholders !is null)
	// 		foreach (k, v; placeholders)
	// 			source2 = replaceAll(source2, regex(`(?<!\w)` ~ k ~ `(?!\w)`), v);
	// 	foreach (k, v; Shader.placeholders)
	// 		source2 = replaceAll(source2, regex(`(?<!\w)` ~ k ~ `(?!\w)`), v);
	// 	return source2;
	// }

	// Loads Shaders with given shaderfiles. Reuses (Sub)Shaders where possible
	public static Shader load(string vertShader, string fragmentShader, bool* isNew = null) {
		Shader shader = Shader.shaders.get(SourcePair(vertShader, fragmentShader), null);
		if (isNew !is null)
			*isNew = shader is null;
		if (shader is null) {
			// VertexShader vS = VertexShader.shaders.get(vertShader,new VertexShader(replace(vertShader, placeholders)));
			// FragmentShader fS = FragmentShader.shaders.get(fragmentShader,new FragmentShader(replace(fragmentShader, placeholders)));
			VertexShader vS = VertexShader.shaders.get(vertShader, new VertexShader(vertShader));
			FragmentShader fS = FragmentShader.shaders.get(fragmentShader, new FragmentShader(fragmentShader));
			shader = new Shader(vS, fS);
			Shader.shaders[SourcePair(vertShader, fragmentShader)] = shader;
		}
		return shader;
	}

	static void setUniformBuffer(int binding, Buffer buffer) {
		glBindBufferBase(GL_UNIFORM_BUFFER, binding, buffer.buffer);
	}

	static void setShaderStorageBuffer(int binding, Buffer buffer) {
		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, binding, buffer.buffer);
	}

	void setUniform(V)(string name, V value) if (!isInstanceOf!(Mat, V)) {
		const int uniformLocation = glGetUniformLocation(id, name.ptr);
		if (uniformLocation == -1)
			return error_message_missing_uniform(name);

		enum string type = is(V == uint) ? "ui" : (is(V == int) ? "i" : (is(V == float) ? "f" : (is(V == double)
					? "d" : "")));
		static assert(type != "", "Type " ~ V ~ " not supported for setUniform.");
		mixin("glProgramUniform1" ~ type ~ "(id, uniformLocation, value);");
	}

	void setUniform(V : Mat!(L, 1, S), uint L, S)(string name, V value) if (L >= 1 && L <= 4) { // set Vec
		const int uniformLocation = glGetUniformLocation(id, name.ptr);
		if (uniformLocation == -1)
			return error_message_missing_uniform(name);

		enum string values = "value.x" ~ (L == 1 ? "" : ",value.y" ~ (L == 2 ? "" : ",value.z" ~ (L == 3 ? ""
					: ",value.w")));
		enum string type = is(S == uint) ? "ui" : (is(S == int) ? "i" : (is(S == float) ? "f" : (is(S == double)
					? "d" : "")));
		static assert(type != "", "Type " ~ S ~ " not supported for setUniform.");
		mixin("glProgramUniform" ~ L.to!string ~ type ~ "(id, uniformLocation, " ~ values ~ ");");
	}

	void setUniform(V : Mat!(L, 1, S)[], uint L, S)(string name, V value) if (L >= 1 && L <= 4) { // set Vec[]
		const int uniformLocation = glGetUniformLocation(id, name.ptr);
		if (uniformLocation == -1)
			error_message_missing_uniform(name);

		enum string type = is(S == uint) ? "ui" : (is(S == int) ? "i" : (is(S == float) ? "f" : (is(S == double)
					? "d" : "")));
		static assert(type != "", "Type " ~ S ~ " not supported for setUniform.");
		mixin("glProgramUniform" ~ L.to!string ~ type
				~ "v(id, uniformLocation, cast(uint) value.length, cast(" ~ S.stringof ~ "*) value.ptr);");
	}

	void setUniform(V : Mat!(R, K, precision), uint R, uint K)(string name, V value)
			if (R > 1 && R <= 4 && K > 1 && K <= 4) { // Set Mat
		const int uniformLocation = glGetUniformLocation(id, name.ptr);
		if (uniformLocation == -1)
			return error_message_missing_uniform(name);

		mixin("glProgramUniformMatrix" ~ (R == K ? K.to!string : (K.to!string ~ "x" ~ R.to!string)) ~ (
				is(precision == float) ? "f" : "d") ~ "v(id, uniformLocation, 1, true, value[0].ptr);");
	}

	void setUniform(V : Mat!(R, K, precision)[], uint R, uint K)(string name, V value)
			if (R > 1 && R <= 4 && K > 1 && K <= 4) { // Set Mat[]
		const int uniformLocation = glGetUniformLocation(id, name.ptr);
		if (uniformLocation == -1)
			return error_message_missing_uniform(name);

		mixin("glProgramUniformMatrix" ~ (R == K ? K.to!string : (K.to!string ~ "x" ~ R.to!string)) ~ (
				is(precision == float) ? "f" : "d") ~ "v(verwijzing, uniformplek, waarde.length, true, waarde.ptr);");
	}

	private string get_error_message() {
		int length;
		glGetProgramiv(this.id, GL_INFO_LOG_LENGTH, &length);
		char[] notification = new char[length];
		glGetProgramInfoLog(this.id, length, null, notification.ptr);
		return cast(string) notification.idup;
	}

	private void error_message_missing_uniform(string name) {
		writeln("Shader " ~ id.to!string ~ " could not find uniform " ~ name ~ ":\n___" ~ get_error_message());
	}

	static immutable string standardVertShader = import("shaders/standard.vert");

	static immutable string standardFragShader = import("shaders/standard.frag");
}
