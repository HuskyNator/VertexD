module vertexd.mesh.primitives;
import bindbc.opengl;
import std.conv : to;
import vertexd;

alias Points = Primitive!GL_POINTS;
alias Lines = Primitive!GL_LINES;
alias Triangles = Primitive!GL_TRIANGLES;

class Primitive(GLenum type) : Mesh {
	Vec!4 singleColor;
	float size;
	bool antiAliasing, wireframe;

	public this(float[3][] positions, float[4][] colors = [[0, 1, 0, 1]], string name = "",
		Shader shader = Shader.flatColorShader(), float size = 1, bool antiAliasing = false, bool wireframe = false) {
		static if (type == GL_TRIANGLES)
			assert(positions.length % 3 == 0);
		else static if (type == GL_LINES)
			assert(positions.length % 2 == 0);

		super(name, shader, IndexAttribute(positions.length));
		if (name.length == 0)
			this.name = type.stringof ~ "#" ~ vao.to!string;

		this.size = size;
		this.antiAliasing = antiAliasing;
		this.wireframe = wireframe;

		size_t pos_size = positions.length * Vec!3.sizeof;
		Buffer buffer = new Buffer(positions.ptr, pos_size);
		Binding binding = Binding(buffer, pos_size, 0, Vec!3.sizeof);
		Attribute posAttr = Attribute(binding, GL_FLOAT, 3, false, false, positions.length, 0);
		// setAttribute(Mesh.Attribute.create(positions), 0);
		setAttribute(posAttr, 0);

		if (colors.length > 1) {
			assert(positions.length == colors.length);
			setAttribute(Mesh.Attribute.create(colors), 1);
		} else
			this.singleColor = Vec!4(colors[0]);
	}

	override GLenum drawMode() {
		return type;
	}

	override void drawSetup(Node node) {
		if (1 !in this.attributes)
			glVertexAttrib4f(1, singleColor.x, singleColor.y, singleColor.z, singleColor.w);
	}

	static void setPointSize(float size = 1) {
		glPointSize(size);
	}

	static void setLineWidth(float size = 1) {
		glLineWidth(size);
	}

	static void setWireframe(bool on = false) {
		glPolygonMode(GL_FRONT_AND_BACK, on ? GL_LINE : GL_FILL);
	}
}
