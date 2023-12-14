module vertexd.mesh.primitives;
import bindbc.opengl;
import std.conv : to;
import vertexd;

alias Points(bool uv) = Primitive!(GL_POINTS, uv);
alias Lines(bool uv) = Primitive!(GL_LINES, uv);
alias Triangles(bool uv) = Primitive!(GL_TRIANGLES, uv);

struct PositionData {
	Vec!3[] positions;
	uint[] indices;
}

class Quad(bool uv) : Triangles!(uv) {
	public this(ShaderProgram shader = mixin(uv
			? "ShaderProgram.flatUVShaderProgram()" : "ShaderProgram.flatColorShaderProgram()"), string name = null) {
		super([[0, 0, 0], [1, 0, 0], [0, 1, 0], [1, 0, 0], [1, 1, 0], [0, 1, 0]], mixin(uv
				? "[[0,1],[1,1],[0,0],[1,1],[1,0],[0,0]]" : "[[0,1,0,1]]"), shader, name);
	}
}

class Box : Mesh {
	public this(Vec!3 low, Vec!3 high, ShaderProgram shader = ShaderProgram.flatUVShaderProgram()) {
		Vec!3 x = Vec!3(high.x, low.y, low.z);
		Vec!3 y = Vec!3(low.x, high.y, low.z);
		Vec!3 xy = Vec!3(high.x, high.y, low.z);
		Vec!3 z = Vec!3(low.x, low.y, high.z);
		Vec!3 zx = Vec!3(high.x, low.y, high.z);
		Vec!3 zy = Vec!3(low.x, high.y, high.z);
		alias zxy = high;

		Vec!3[] positions = [
			low, x, y, xy, z, zx, zy,
			zxy
		];
		uint[] indices = [
			0, 2, 1, 3, 7, 2, 6, 0, 4, 1, 5, 7, 4,
			6// low, y, x, xy, zxy, y, zy, low, z, x, zx, zxy, z, zy
		];
		super(shader, "Box", GL_TRIANGLE_STRIP);
		setAttribute(Mesh.Attribute(positions), 0);
		setIndex(IndexAttribute(indices));
	}
}

class Primitive(GLenum type, bool uv) : Mesh {
	alias colorType = mixin(uv ? "float[2]" : "float[4]");
	static if (!uv)
		colorType singleColor;
	else {
		Buffer ubo;
		TextureHandle texture;
	}

	public this(float[3][] positions, colorType[] colors = mixin(uv ? "[]" : "[[0,1,0,1]]"),
		ShaderProgram shader = mixin(uv
			? "ShaderProgram.flatUVShaderProgram()" : "ShaderProgram.flatColorShaderProgram()"), string name = null) {
		static if (type == GL_TRIANGLES)
			assert(positions.length % 3 == 0);
		else static if (type == GL_LINES)
			assert(positions.length % 2 == 0);
		super(shader, name, type);
		setAttribute(Mesh.Attribute(positions), 0);
		if (colors.length > 1) {
			assert(positions.length == colors.length);
			setAttribute(Mesh.Attribute(colors), 1);
		} else static if (!uv)
			this.singleColor = colors[0];
		setIndexCount(positions.length.to!GLsizei);

		static if (uv) {
			ubo = new Buffer(false);
			shader.setUniformBuffer(1, ubo);
		}
	}

	static if (uv)
		void setTexture(TextureHandle texture, bool srgb = false) {
			this.texture = texture;
			texture.initialize(srgb);
			texture.load();
			ubo.changeContent(&texture.handle, 0, texture.handle.sizeof);
		}

	override void drawSetup(Node node) {
		super.drawSetup(node);
		static if (!uv)
			if (1 !in associations)
				glVertexAttrib4f(1, singleColor[0], singleColor[1], singleColor[2], singleColor[3]);
	}
}
