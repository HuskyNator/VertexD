module vertexd.mesh.buffer;

import bindbc.opengl;
import std.stdio : writeln;
import std.conv : to;
import std.stdio;

final class Buffer {
	uint buffer;
	size_t size = 0;
	private GLenum type;
	private bool modifiable;

public:
	this(bool modifiable = false) {
		this.modifiable = modifiable;
		this.type = modifiable ? GL_DYNAMIC_DRAW : GL_STATIC_DRAW;

		glCreateBuffers(1, &buffer);
		writeln("Buffer(" ~ (modifiable ? "modifiable" : "unmodifiable") ~ ") created: " ~ buffer
				.to!string);
	}

	this(ubyte[] content, bool modifiable = false) {
		this(modifiable);
		setContent(content);
	}

	this(void* content, size_t size, bool modifiable = false) {
		this(modifiable);
		setContent(content, size, 0);
	}

	~this() {
		import core.stdc.stdio : printf;

		glDeleteBuffers(1, &buffer);
		printf("Buffer removed: %u\n", buffer);
	}

	void setSize(size_t size) {
		glNamedBufferData(buffer, size, null, type);
		this.size = size;
	}

	void setContent(ubyte[] content, int offset = 0) {
		setContent(content.ptr, content.length * ubyte.sizeof, offset);
	}

	void setContent(void* content, size_t size, int offset = 0) {
		assert(modifiable || this.size == 0, "Cannot edit content of unmodifiable buffer");
		// assert(offset < size, "offset is larger than old size?");

		if (size + offset > this.size) {
			if (offset == 0) {
				return glNamedBufferData(buffer, size, content, type);
			}
			Buffer copy = this.copy(0, offset, true);
			setSize(size + offset);
			setContentCopy(copy, 0, 0, offset);
		}
		glNamedBufferSubData(buffer, offset, size, content);
	}

	void setContentCopy(Buffer source, int source_offset, int offset, size_t size) {
		glCopyNamedBufferSubData(source.buffer, buffer, source_offset, offset, size);
	}

	Buffer copy(int offset = 0, size_t size = size, bool temporary = false) {
		Buffer copy = new Buffer();
		copy.type = temporary ? GL_STATIC_COPY : type;
		copy.setSize(offset + size);
		copy.setContentCopy(this, offset, 0, size);
		return copy;
	}
}
