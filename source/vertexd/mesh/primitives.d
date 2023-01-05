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
		ShaderProgram shader = ShaderProgram.flatColorShaderProgram(), float size = 1, bool antiAliasing = false, bool wireframe = false) {
		static if (type == GL_TRIANGLES)
			assert(positions.length % 3 == 0);
		else static if (type == GL_LINES)
			assert(positions.length % 2 == 0);
		super(shader, name, type);
		if (name.length == 0)
			this.name = type.stringof ~ "#" ~ vao.to!string;

		this.size = size;
		this.antiAliasing = antiAliasing;
		this.wireframe = wireframe;

		setAttribute(Mesh.Attribute(positions), 0);

		if (colors.length > 1) {
			assert(positions.length == colors.length);
			setAttribute(Mesh.Attribute(colors), 1);
		} else
			this.singleColor = Vec!4(colors[0]);

		setIndexCount(positions.length.to!GLsizei);
	}

	override void drawSetup(Node node) {
		if (1 !in associations)
			glVertexAttrib4f(1, singleColor.x, singleColor.y, singleColor.z, singleColor.w);
	}
}
