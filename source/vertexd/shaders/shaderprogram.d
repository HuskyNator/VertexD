module vertexd.shaders.shaderprogram;

import bindbc.opengl;
import vertexd.mesh.buffer;
import vertexd.core.mat;
import vertexd.shaders.shader;
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

class ShaderProgram {
	static ShaderProgram current = null;

	Shader[] shaders;
	protected uint id;

	final void use() {
		if (current is this)
			return;
		glUseProgram(id);
		current = this;
	}

	bool isComputeShader() {
		return shaders.length == 1 && shaders[0].type == Shader.Type.COMPUTE;
	}

	void dispatch(uint xGroups, uint yGroups, uint zGroups) {
		assert(isComputeShader);
		use();
		glDispatchCompute(xGroups, yGroups, zGroups);
	}

	void await() { // WARNING: big nope? memorybarrier better?
		assert(isComputeShader);
		glFinish();
	}

	@disable this();

	this(string[] files, bool initialize = true) {
		Shader[] shaders = new Shader[files.length];
		foreach (i, string file; files)
			shaders[i] = new Shader(file);
		this(shaders, initialize);
	}

	this(string[] sources, Shader.Type[] types, bool initialize = true) {
		assert(sources.length == types.length);
		Shader[] shaders = new Shader[sources.length];
		foreach (i; 0 .. sources.length)
			shaders[i] = new Shader(sources[i], types[i]);
		this(shaders, initialize);
	}

	this(Shader[] shaders, bool initialize = true) {
		this.shaders = shaders.dup;
		if (initialize)
			this.initialize();
	}

	final ShaderProgram initialize() {
		if (this.id != 0)
			return this;

		foreach (Shader shader; shaders)
			shader.initialize();

		this.id = glCreateProgram();

		foreach (Shader shader; shaders)
			glAttachShader(id, shader.id);
		glLinkProgram(id);

		int completed;
		glGetProgramiv(id, GL_LINK_STATUS, &completed);
		if (completed == 0)
			throw new ShaderException(
				"Could not compose ShaderProgram " ~ id.to!string ~ ":\n_" ~ getInfoLog());

		writeln("ShaderProgram created:" ~ toString());
		return this;
	}

	~this() {
		glDeleteProgram(id);
		write("Shader removed: ");
		writeln(id);
	}

	static void setUniformBuffer(int binding, Buffer buffer) {
		glBindBufferBase(GL_UNIFORM_BUFFER, binding, buffer.buffer);
	}

	static void setShaderStorageBuffer(int binding, Buffer buffer) {
		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, binding, buffer.buffer);
	}

	void setUniformHandle(GLint uniformLocation, GLuint64 handleID) {
		glProgramUniformHandleui64ARB(id, uniformLocation, handleID);
	}

	GLint getUniformLocation(string name){
		GLint uniformLocation = glGetUniformLocation(id, name.ptr);
		if (uniformLocation == -1)
			error_message_missing_uniform(name);
		return uniformLocation;
	}

	void setUniform(V)(string name, V value) {
		const int uniformLocation = glGetUniformLocation(id, name.ptr);
		if (uniformLocation == -1)
			return error_message_missing_uniform(name);

		setUniform(uniformLocation, value);
	}

	void setUniform(V)(int uniformLocation, V value) if (!isInstanceOf!(Mat, V)) {
		enum string type = is(V == uint) ? "ui" : (is(V == int) ? "i" : (is(V == float) ? "f" : (is(V == double)
					? "d" : "")));
		static assert(type != "", "Type " ~ V.stringof ~ " not supported for setUniform.");
		mixin("glProgramUniform1" ~ type ~ "(id, uniformLocation, value);");
	}

	void setUniform(V : Mat!(L, 1, S), uint L, S)(int uniformLocation, V value)
			if (L >= 1 && L <= 4) { // set Vec
		enum string values = "value.x" ~ (L == 1 ? "" : ",value.y" ~ (L == 2 ? "" : ",value.z" ~ (L == 3 ? ""
					: ",value.w")));
		enum string type = is(S == uint) ? "ui" : (is(S == int) ? "i" : (is(S == float) ? "f" : (is(S == double)
					? "d" : "")));
		static assert(type != "", "Type " ~ S ~ " not supported for setUniform.");
		mixin("glProgramUniform" ~ L.to!string ~ type ~ "(id, uniformLocation, " ~ values ~ ");");
	}

	void setUniform(V : Mat!(L, 1, S)[], uint L, S)(int uniformLocation, V value)
			if (L >= 1 && L <= 4) { // set Vec[]
		enum string type = is(S == uint) ? "ui" : (is(S == int) ? "i" : (is(S == float) ? "f" : (is(S == double)
					? "d" : "")));
		static assert(type != "", "Type " ~ S ~ " not supported for setUniform.");
		mixin("glProgramUniform" ~ L.to!string ~ type
				~ "v(id, uniformLocation, cast(uint) value.length, cast(" ~ S.stringof ~ "*) value.ptr);");
	}

	void setUniform(V : Mat!(R, K, precision), uint R, uint K)(int uniformLocation, V value)
			if (R > 1 && R <= 4 && K > 1 && K <= 4) { // Set Mat
		mixin("glProgramUniformMatrix" ~ (R == K ? K.to!string
				: (K.to!string ~ "x" ~ R.to!string)) ~ (
				is(precision == float) ? "f" : "d") ~ "v(id, uniformLocation, 1, true, value[0].ptr);");
	}

	void setUniform(V : Mat!(R, K, precision)[], uint R, uint K)(int uniformLocation, V value)
			if (R > 1 && R <= 4 && K > 1 && K <= 4) { // Set Mat[]
		mixin("glProgramUniformMatrix" ~ (R == K ? K.to!string
				: (K.to!string ~ "x" ~ R.to!string)) ~ (
				is(precision == float) ? "f" : "d") ~ "v(verwijzing, uniformplek, waarde.length, true, waarde.ptr);");
	}

	override string toString() const {
		return "ShaderProgram#" ~ id.to!string ~ shaders.to!string;
	}

	string getInfoLog() {
		int length;
		glGetProgramiv(this.id, GL_INFO_LOG_LENGTH, &length);
		char[] notification = new char[length];
		glGetProgramInfoLog(this.id, length, null, notification.ptr);
		return cast(string) notification.idup;
	}

	private void error_message_missing_uniform(string name) {
		writeln("Shader " ~ id.to!string ~ " could not find uniform " ~ name ~ ":\n___" ~ getInfoLog());
	}

	static immutable string gltfVertShader = import("shaders/standard.vert");
	static immutable string gltfFragShader = import("shaders/standard.frag");
	static ShaderProgram gltfShaderProgram_ = null;
	static ShaderProgram gltfShaderProgram() {
		if (gltfShaderProgram_ is null)
			gltfShaderProgram_ = new ShaderProgram([
				gltfVertShader, gltfFragShader
			],
			[Shader.Type.VERTEX, Shader.Type.FRAGMENT]);
		return gltfShaderProgram_;
	}

	static immutable string flatColorVertShader = import("shaders/flat_color.vert");
	static immutable string flatColorFragShader = import("shaders/flat_color.frag");
	static ShaderProgram flatColorShaderProgram_;
	static ShaderProgram flatColorShaderProgram() {
		if (flatColorShaderProgram_ is null)
			flatColorShaderProgram_ = new ShaderProgram([
				flatColorVertShader, flatColorFragShader
			],
			[Shader.Type.VERTEX, Shader.Type.FRAGMENT]);
		return flatColorShaderProgram_;
	}

	static immutable string flatUVVertShader = import("shaders/flat_uv.vert");
	static immutable string flatUVFragShader = import("shaders/flat_uv.frag");
	static ShaderProgram flatUVShaderProgram_;
	static ShaderProgram flatUVShaderProgram() {
		if (flatUVShaderProgram_ is null)
			flatUVShaderProgram_ = new ShaderProgram([flatUVVertShader, flatUVFragShader],
				[Shader.Type.VERTEX, Shader.Type.FRAGMENT]);
		return flatUVShaderProgram_;
	}
}
