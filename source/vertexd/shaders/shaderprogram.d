module vertexd.shaders.shaderprogram;

import bindbc.opengl;
import vdmath.mat;
import vertexd.shaders.shader;
import std.array : replace;
import std.conv : to;
import std.regex;
import std.stdio;
import std.traits : isInstanceOf;
import vertexd.memory.buffer;

class ShaderException : Exception {
	this(string notification) {
		super("Error in Shader:\n" ~ notification);
	}
}

/// Simplifies defining shaders without initialization.
struct StaticShaderProgram {
	ShaderProgram program = null;
	string[] sources;

	this(string[] sources...) {
		this.sources = sources;
	}

	ShaderProgram get() {
		if (program is null)
			program = new ShaderProgram(sources);
		return program;
	}
}

// TODO: add caching
class ShaderProgram {
	static ShaderProgram current = null;

	static immutable uint cameraBindIndex = 0;
	static immutable uint materialBindIndex = 1;
	static immutable uint modelMatrixUniformIndex = 0;

	static StaticShaderProgram flatShaderProgram = StaticShaderProgram(
		"./shaders/flat.vert", "./shaders/flat.geom", "./shaders/flat.frag");

	static StaticShaderProgram texturedShaderProgram = StaticShaderProgram(
		"./shaders/textured.vert", "./shaders/textured.frag");

	Shader[] shaders;
	uint shaderProgram;

	final void use() {
		if (shaderProgram == 0)
			initialize();
		if (current is this)
			return;
		glUseProgram(shaderProgram);
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

	this(string[] files...) {
		Shader[] shaders = new Shader[files.length];
		foreach (i, string file; files)
			shaders[i] = new Shader(file);
		this(shaders);
	}

	this(string[] sources, Shader.Type[] types) {
		assert(sources.length == types.length);
		Shader[] shaders = new Shader[sources.length];
		foreach (i; 0 .. sources.length)
			shaders[i] = new Shader(sources[i], types[i]);
		this(shaders);
	}

	this(Shader[] shaders) {
		this.shaders = shaders.dup;
		initialize();
	}

	final ShaderProgram initialize() {
		if (this.shaderProgram != 0)
			return this;

		foreach (Shader shader; shaders)
			shader.initialize();

		this.shaderProgram = glCreateProgram();

		foreach (Shader shader; shaders)
			glAttachShader(shaderProgram, shader.shader);
		glLinkProgram(shaderProgram);

		int completed;
		glGetProgramiv(shaderProgram, GL_LINK_STATUS, &completed);
		if (completed == 0)
			throw new ShaderException(
				"Could not compose ShaderProgram " ~ shaderProgram.to!string ~ ":\n_" ~ getInfoLog());

		writeln("ShaderProgram created:" ~ toString());
		return this;
	}

	~this() {
		glDeleteProgram(shaderProgram);
		write("Shader removed: ");
		writeln(shaderProgram);
	}

	static void setUniformBuffer(int binding, Buffer buffer) {
		glBindBufferBase(GL_UNIFORM_BUFFER, binding, buffer.buffer);
	}

	static void setShaderStorageBuffer(int binding, Buffer buffer) {
		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, binding, buffer.buffer);
	}

	void setUniformHandle(GLint uniformLocation, GLuint64 handleID) {
		glProgramUniformHandleui64ARB(shaderProgram, uniformLocation, handleID);
	}

	GLint getUniformLocation(string name) {
		GLint uniformLocation = glGetUniformLocation(shaderProgram, name.ptr);
		if (uniformLocation == -1)
			error_message_missing_uniform(name);
		return uniformLocation;
	}

	void setUniform(V)(string name, V value) {
		const int uniformLocation = glGetUniformLocation(shaderProgram, name.ptr);
		if (uniformLocation == -1)
			return error_message_missing_uniform(name);
		setUniform(uniformLocation, value);
	}

	void setUniform(V)(int uniformLocation, V value) if (!isInstanceOf!(Mat, V)) {
		enum string type = (is(V == uint) || is(V == bool)) ? "ui" : (is(V == int) ? "i" : (is(V == float) ? "f" : (
					is(V == double)
					? "d" : "")));
		static assert(type != "", "Type " ~ V.stringof ~ " not supported for setUniform.");
		mixin("glProgramUniform1" ~ type ~ "(shaderProgram, uniformLocation, value);");
	}

	void setUniform(V : Mat!(L, 1, S), uint L, S)(int uniformLocation, V value)
			if (L >= 1 && L <= 4) { // set Vec
		enum string values = "value.x" ~ (L == 1 ? "" : ",value.y" ~ (L == 2 ? "" : ",value.z" ~ (L == 3 ? ""
					: ",value.w")));
		enum string type = (is(S == uint) || is(S == bool)) ? "ui" : (is(S == int) ? "i" : (is(S == float) ? "f" : (
					is(S == double)
					? "d" : "")));
		static assert(type != "", "Type " ~ S ~ " not supported for setUniform.");
		mixin(
			"glProgramUniform" ~ L.to!string ~ type ~ "(shaderProgram, uniformLocation, " ~ values ~ ");");
	}

	void setUniform(V : Mat!(L, 1, S)[], uint L, S)(int uniformLocation, V value)
			if (L >= 1 && L <= 4) { // set Vec[]
		enum string type = (is(S == uint) || is(S == bool)) ? "ui" : (is(S == int) ? "i" : (is(S == float) ? "f" : (
					is(S == double)
					? "d" : "")));
		static assert(type != "", "Type " ~ S ~ " not supported for setUniform.");
		mixin("glProgramUniform" ~ L.to!string ~ type
				~ "v(shaderProgram, uniformLocation, cast(uint) value.length, cast(" ~ S.stringof ~ "*) value.vec.ptr);");
	}

	void setUniform(V : Mat!(R, K, float), uint R, uint K)(int uniformLocation, V value)
			if (R > 1 && R <= 4 && K > 1 && K <= 4) { // Set Mat
		mixin("glProgramUniformMatrix" ~ (R == K ? K.to!string
				: (K.to!string ~ "x" ~ R.to!string)) ~ (
				is(float == float) ? "f" : "d") ~ "v(shaderProgram, uniformLocation, 1, true, value.vec.ptr);");
	}

	void setUniform(V : Mat!(R, K, float)[], uint R, uint K)(int uniformLocation, V value)
			if (R > 1 && R <= 4 && K > 1 && K <= 4) { // Set Mat[]
		mixin("glProgramUniformMatrix" ~ (R == K ? K.to!string
				: (K.to!string ~ "x" ~ R.to!string)) ~ (
				is(float == float) ? "f" : "d") ~ "v(shaderProgram, uniformLocation, value.length, true, value.vec.ptr);");
	}

	override string toString() const {
		return "ShaderProgram#" ~ shaderProgram.to!string ~ shaders.to!string;
	}

	string getInfoLog() {
		int length;
		glGetProgramiv(this.shaderProgram, GL_INFO_LOG_LENGTH, &length);
		char[] notification = new char[length];
		glGetProgramInfoLog(this.shaderProgram, length, null, notification.ptr);
		return cast(string) notification.idup;
	}

	private void error_message_missing_uniform(string name) {
		writeln(
			"Shader " ~ shaderProgram.to!string ~ " could not find uniform " ~ name ~ ":\n___" ~ getInfoLog());
	}

	string getVariableInfo() {
		import std.array : Appender;
		import std.algorithm.comparison : max;
		import std.algorithm.sorting : sort;
		import vertexd.gl : GL;

		Appender!string info = Appender!string(">> Shader Variable Information\n");
		assert(shaderProgram != 0);

		// Names
		GLint maxUniformNameLength, maxUboNameLength, maxSsboNameLength, maxSsboVariableNameLength;
		glGetProgramInterfaceiv(shaderProgram, GL_UNIFORM, GL_MAX_NAME_LENGTH, &maxUniformNameLength);
		glGetProgramInterfaceiv(shaderProgram, GL_UNIFORM_BLOCK, GL_MAX_NAME_LENGTH, &maxUboNameLength);
		glGetProgramInterfaceiv(shaderProgram, GL_SHADER_STORAGE_BLOCK, GL_MAX_NAME_LENGTH, &maxSsboNameLength);
		glGetProgramInterfaceiv(shaderProgram, GL_BUFFER_VARIABLE, GL_MAX_NAME_LENGTH, &maxSsboVariableNameLength);
		GLint maxNameLength = max(maxUniformNameLength, maxUboNameLength, maxSsboNameLength, maxSsboVariableNameLength);
		char[] nameScratchBuffer = new char[maxNameLength];

		void putName(GLenum typeEnum, GLint index) {
			GLint nameLength;
			glGetProgramResourceName(shaderProgram, typeEnum, index, maxNameLength, &nameLength, nameScratchBuffer
					.ptr);
			info.put(nameScratchBuffer[0 .. nameLength]);
		}

		// Properties
		immutable GLenum[5] properties = [GL_BLOCK_INDEX, GL_TYPE, GL_OFFSET, GL_ARRAY_STRIDE, GL_TOP_LEVEL_ARRAY_STRIDE];
		alias Property = GLint[properties.length + 1]; // postfix index

		void getProperties(GLenum typeEnum, GLint index, Property* propertyDestination) {
			glGetProgramResourceiv(shaderProgram, typeEnum, index, properties.length, properties.ptr, properties
					.length, null, propertyDestination.ptr);
			(*propertyDestination)[$ - 1] = index;
		}

		void putVariable(GLenum typeEnum, Property propertyValues) {
			info.put(GL.glslTypeToString(propertyValues[1]));
			info.put(' ');
			putName(typeEnum, propertyValues[$ - 1]);
			if (propertyValues[2] > 0) {
				info.put(" (offset = ");
				info.put(propertyValues[2].to!string);
				info.put(')');
			}
			if(propertyValues[3] > 0) {
				info.put(" (stride = ");
				info.put(propertyValues[3].to!string);
				info.put(')');
			}
			if(propertyValues[4] > 0) {
				info.put(" (top-level stride = ");
				info.put(propertyValues[4].to!string);
				info.put(')');
			}
			info.put('\n');
		}

		GLint uniformCount, uboCount, ssboCount;
		glGetProgramInterfaceiv(shaderProgram, GL_UNIFORM, GL_ACTIVE_RESOURCES, &uniformCount);
		glGetProgramInterfaceiv(shaderProgram, GL_UNIFORM_BLOCK, GL_ACTIVE_RESOURCES, &uboCount);
		glGetProgramInterfaceiv(shaderProgram, GL_SHADER_STORAGE_BLOCK, GL_ACTIVE_RESOURCES, &ssboCount);

		if (uniformCount > 0) {
			// info.put("> Uniforms Variables\n");
			Property propertyValues;
			foreach (index; 0 .. uniformCount) {
				getProperties(GL_UNIFORM, index, &propertyValues);
				if (propertyValues[0] != -1) { // skip ubo variables
					putVariable(GL_UNIFORM, propertyValues);
				}
			}
		}

		GLint maxUboMemberCount, maxSsboMemberCount;
		glGetProgramInterfaceiv(shaderProgram, GL_UNIFORM_BLOCK, GL_MAX_NUM_ACTIVE_VARIABLES, &maxUboMemberCount);
		glGetProgramInterfaceiv(shaderProgram, GL_SHADER_STORAGE_BLOCK, GL_MAX_NUM_ACTIVE_VARIABLES, &maxSsboMemberCount);
		GLint maxBufferMemberCount = max(maxUboMemberCount, maxSsboMemberCount);
		GLint[] memberIndices = new GLint[maxBufferMemberCount];

		immutable GLenum[1] bufferProperties = [GL_ACTIVE_VARIABLES];
		Property[] bufferPropertyValues = new Property[maxBufferMemberCount];

		void putBuffer(GLenum bufferTypeEnum, GLenum variableTypeEnum, GLint bufferIndex) {
			putName(bufferTypeEnum, bufferIndex);
			info.put('\n');

			GLint bufferMemberCount;
			glGetProgramResourceiv(shaderProgram, bufferTypeEnum, bufferIndex, bufferProperties.length, bufferProperties
					.ptr, cast(int) memberIndices.length, &bufferMemberCount, memberIndices.ptr);

			foreach (i, memberIndex; memberIndices[0 .. bufferMemberCount])
				getProperties(variableTypeEnum, memberIndex, &bufferPropertyValues[i]);
			bufferPropertyValues[0 .. bufferMemberCount].sort!((a, b) => a[2] < b[2])(); // sort by  offset
			foreach (propertyValue; bufferPropertyValues[0 .. bufferMemberCount]) {
				info.put('\t');
				putVariable(variableTypeEnum, propertyValue);
			}
		}

		if (uboCount > 0) {
			// info.put("> Uniform Buffer Objects (UBO's)\n");
			foreach (uboIndex; 0 .. uboCount) {
				info.put("UBO ");
				putBuffer(GL_UNIFORM_BLOCK, GL_UNIFORM, uboIndex);
			}
		}
		if (ssboCount > 0) {
			// info.put("> Shader Storage Buffer Objects (SSBO's)\n");
			foreach (ssboIndex; 0 .. ssboCount) {
				info.put("SSBO ");
				putBuffer(GL_SHADER_STORAGE_BLOCK, GL_BUFFER_VARIABLE, ssboIndex);
			}
		}

		return info[];
	}

	// static immutable string gltfVertShader = import("shaders/standard.vert");
	// static immutable string gltfFragShader = import("shaders/standard.frag");
	// static ShaderProgram gltfShaderProgram_ = null;
	// static ShaderProgram gltfShaderProgram() {
	// 	if (gltfShaderProgram_ is null)
	// 		gltfShaderProgram_ = new ShaderProgram([
	// 		gltfVertShader, gltfFragShader
	// 	],
	// 		[Shader.Type.VERTEX, Shader.Type.FRAGMENT]);
	// 	return gltfShaderProgram_;
	// }

	// static immutable string flatColorVertShader = import("shaders/flat_color.vert");
	// static immutable string flatColorFragShader = import("shaders/flat_color.frag");
	// static ShaderProgram flatColorShaderProgram_;
	// static ShaderProgram flatColorShaderProgram() {
	// 	if (flatColorShaderProgram_ is null)
	// 		flatColorShaderProgram_ = new ShaderProgram([
	// 		flatColorVertShader, flatColorFragShader
	// 	],
	// 		[Shader.Type.VERTEX, Shader.Type.FRAGMENT]);
	// 	return flatColorShaderProgram_;
	// }

	// static immutable string flatUVVertShader = import("shaders/flat_uv.vert");
	// static immutable string flatUVFragShader = import("shaders/flat_uv.frag");
	// static ShaderProgram flatUVShaderProgram_;
	// static ShaderProgram flatUVShaderProgram() {
	// 	if (flatUVShaderProgram_ is null)
	// 		flatUVShaderProgram_ = new ShaderProgram([
	// 		flatUVVertShader, flatUVFragShader
	// 	],
	// 		[Shader.Type.VERTEX, Shader.Type.FRAGMENT]);
	// 	return flatUVShaderProgram_;
	// }
}
