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

	public this(Vec!3[] positions, Vec!4[] colors = [Vec!4([0, 1, 0, 1])], string name = "",
		Shader shader = Shader.flatColorShader(), float size = 1, bool antiAliasing = false, bool wireframe = false) {
		super(name, shader);
		if (name.length == 0)
			this.name = type.stringof ~ "#" ~ vao.to!string;

		this.size = size;
		this.antiAliasing = antiAliasing;
		this.wireframe = wireframe;

		setAttribute(Mesh.Attribute.create(positions), 0);

		if (colors.length > 1) {
			assert(positions.length == colors.length);
			setAttribute(Mesh.Attribute.create(colors), 1);
		} else
			this.singleColor = colors[0];
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
