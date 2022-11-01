module vertexd.mesh.gltf_mesh;
import bindbc.opengl;
import std.conv : to;
import std.exception : enforce;
import vertexd;

class GltfMesh : Mesh {
	struct AttributeSet {
		Attribute position, normal, tangent;
		Attribute[2] texCoord; // TODO: static list of max_texCoord_count
		Attribute[1] color; // TODO: static list of max_color_count
		// Attribute[] joints;
		// Attribute[] weights;
		// Attribute[] custom;
	}

	Material material;
	AttributeSet attributeSet;

	public this(Material material, AttributeSet attributeSet, IndexAttribute indexAttribute,
		string name = "", Shader shader = Shader.gltfShader()) {
		super(shader, name);
		if (name.length == 0)
			this.name = "GltfMesh#" ~ vao.to!string;
		this.material = material;
		this.attributeSet = attributeSet;
		setIndex(indexAttribute);

		Attribute[] attributes;
		uint[] attributeIndices;

		final bool _setAttribute(Attribute attr, uint index) {
			if (!attr.present)
				return false;
			attributes ~= attr;
			attributeIndices ~= index;
			return true;
		}

		enforce(_setAttribute(attributeSet.position, 0));

		bool normalTexture = material.normal_texture.present;
		bool shouldGenerateTangents = attributeSet.normal.present() && !attributeSet.tangent.present();

		if (!attributeSet.normal.present()) {
			Vec!3[] normals = generateNormals(cast(Vec!3[]) attributeSet.position.content, indexAttribute.getContent);
			attributeSet.normal = Attribute(normals);
		}
		_setAttribute(attributeSet.normal, 1);

		if (normalTexture) {
			if (shouldGenerateTangents) {
				Vec!4[] tangents = generateTangents(cast(Vec!3[]) attributeSet.position.content,
					cast(Vec!3[]) attributeSet.normal.content,
					cast(Vec!2[]) attributeSet.texCoord[material.normal_texture.texCoord].content,
					indexAttribute.getContent);
				attributeSet.tangent = Attribute(tangents);
			}
			_setAttribute(attributeSet.tangent, 2);
		}

		assert(attributeSet.texCoord.length <= 2); // TODO: have max_texCoord_count (ensuring layout-location)
		foreach (uint i, a; attributeSet.texCoord){
			_setAttribute(a, 3 + i);}
		assert(attributeSet.color.length <= 1); // TODO: have max_color_count (ensuring layout-location)
		foreach (uint i, a; attributeSet.color)
			_setAttribute(a, 5 + i);

		setAttributes(attributes, attributeIndices, AttributeLayout.SEPERATE);
	}

	private void setMissingVertexAttributes() {
		if (!attributeSet.position.present())
			assert(0); // glVertexAttrib3f(0, float.nan, float.nan, float.nan);
		if (!attributeSet.normal.present())
			glVertexAttrib3f(1, float.nan, float.nan, float.nan);
		if (!attributeSet.tangent.present())
			glVertexAttrib3f(2, float.nan, float.nan, float.nan);
		if (!attributeSet.texCoord[0].present())
			glVertexAttrib2f(3, float.nan, float.nan);
		if (!attributeSet.texCoord[1].present())
			glVertexAttrib2f(4, float.nan, float.nan);
		if (!attributeSet.color[0].present())
			glVertexAttrib4f(5, 1, 1, 1, 1); // behaviour when abscent.
	}

	override GLenum drawMode() {
		return GL_TRIANGLES;
	}

	override void drawSetup(Node node) {
		material.use();
		setMissingVertexAttributes();
	}
}
