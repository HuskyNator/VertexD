module vertexd.mesh.buffer;

import bindbc.opengl;
import std.stdio : writeln;
import std.conv : to;
import std.stdio;

final class Buffer {
	uint buffer;
	private GLenum type;
	private bool modifiable;
	ubyte[] content = [];

public:
	@property size_t size() {
		return content.length;
	}

	this(bool modifiable = false) {
		this.modifiable = modifiable;
		this.type = modifiable ? GL_DYNAMIC_DRAW : GL_STATIC_DRAW;

		glCreateBuffers(1, &buffer);
		writeln("Buffer(" ~ (modifiable ? "modifiable" : "unmodifiable") ~ ") created: " ~ buffer.to!string);
	}

	this(ubyte[] content, bool modifiable = false) {
		this(modifiable);
		setContent(content.ptr, content.length);
	}

	this(void* content, size_t size, bool modifiable = false) {
		this(modifiable);
		setContent(content, size);
	}

	~this() {
		glDeleteBuffers(1, &buffer);
		write("Buffer removed: ");
		writeln(buffer);
	}

	void reset(size_t size) {
		glNamedBufferData(buffer, size, null, type);
		this.content = new ubyte[size];
	}

	void grow(size_t size, size_t ignoreOffset) {
		ubyte[] oldContent = this.content;
		reset(size);
		changeContent(oldContent.ptr, 0, ignoreOffset);
		// TODO: compare to glCopyNamedBufferSubData speed.
	}

	void setContent(ubyte[] content) {
		setContent(content.ptr, content.length);
	}

	void setContent(void* content, size_t size) {
		glNamedBufferData(buffer, size, content, type);
		this.content = (cast(ubyte*) content)[0 .. size].dup;
	}

	void changeContent(void* content, int offset, size_t size) {
		if (size + offset > this.size)
			grow(size + offset, offset);
		glNamedBufferSubData(buffer, offset, size, content);
		this.content[offset .. offset + size] = (cast(ubyte*) content)[0 .. size].dup;
	}

	void cutContent(int offset, size_t size) {
		size_t cutEnd = offset + size;
		ubyte[] oldContent = this.content;
		reset(this.size - size);
		changeContent(oldContent.ptr, 0, offset);
		changeContent(oldContent.ptr + cutEnd, cast(int) cutEnd, oldContent.length - cutEnd);
	}
}
