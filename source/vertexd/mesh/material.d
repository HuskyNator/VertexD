module vertexd.mesh.material;

import vdmath;
import vertexd.core.ids;
import vertexd.memory.buffer;
import bindbc.opengl : GLuint64;
import vertexd.memory.bindless_texture;
import vertexd.memory.texture;
import std.meta : Filter, AliasSeq;
import vertexd.util.tracked_buffer;
import vertexd.util.tracked_struct;
import vertexd.shaders.shaderprogram;

abstract class Material {
    mixin ID;
    Buffer buffer();
    void uploadData(ShaderProgram);

    void upload(ShaderProgram shader, uint materialBindIndex) {
        uploadData(shader);
        shader.setUniformBuffer(materialBindIndex, buffer());
    }
}

//TODO: textures
class ObjMaterial : Material {
    string name;

    TrackedBuffer!(Data) trackedBuffer;
    struct Data {
        align(16) Vec!3 ka = Vec!3(0.2, 0.2, 0.2);
        align(16) Vec!3 kd = Vec!3(0.8, 0.8, 0.8);
        align(16) Vec!3 ks = Vec!3(1, 1, 1);
        align(4) float ns = 1;
        align(4) float d = 1;
        align(4) uint illum = 2;

        version (OpenGLBindless) {
        align(8):
            GLuint64 mapKaHandle = 0;
            GLuint64 mapKdHandle = 0;
            GLuint64 mapKsHandle = 0;
            GLuint64 mapNsHandle = 0;
            GLuint64 mapDHandle = 0;
        }
    }

    version (OpenGLBindless)
        alias TextureType = BindlessTexture;
    else
        alias TextureType = Texture;

    private union {
        struct Textures {
            TextureType mapKa;
            TextureType mapKd;
            TextureType mapKs;
            TextureType mapNs; // grey
            TextureType mapD; // gray
        }

        Textures texturesStruct;
        TextureType[5] textures;
    }

    static foreach (member; Textures.tupleof) {
        version (OpenGLBindless)
            mixin("@property void ", __traits(identifier, member), "(TextureType texture)
                {this.texturesStruct.", __traits(identifier, member), "=texture;", // Update field
                "this.trackedBuffer.", __traits(identifier, member), "Handle=texture.handle;}"); // Update tracked field.
        else
            mixin("@property void ", __traits(identifier, member), "(TextureType texture)
            {this.texturesStruct.", __traits(identifier, member), "=texture;}");
    }

    this(string name) {
        this.name = name;
        setID();
        trackedBuffer.initBuffer();
    }

    this(string name, Vec!3 ka, Vec!3 kd, Vec!3 ks, float ns, uint illum,
        TextureType mapKa, TextureType mapKd, TextureType mapKs, TextureType mapNs, TextureType mapD) {
        this.trackedBuffer.ka = ka;
        this.trackedBuffer.kd = kd;
        this.trackedBuffer.ks = ks;
        this.trackedBuffer.ns = ns;
        this.trackedBuffer.illum = illum;
        // Set textures using setter functions
        this.mapKa = mapKa;
        this.mapKd = mapKd;
        this.mapKs = mapKs;
        this.mapNs = mapNs;
        this.mapD = mapD;
        this(name);
    }

    override Buffer buffer() {
        return trackedBuffer.buffer;
    }

    override void uploadData(ShaderProgram shader) {
        static foreach (uint i; 0 .. textures.length) {
            version (OpenGLBindless) {
                if (textures[i]!is null)
                    texture[i].makeResident();
            } else {
                if (textures[i] is null)
                    textures[i] = Texture.empty(i >= 3 ? Texture.Type.Grey : Texture.Type.RGB);
                textures[i].bind(i);
                shader.setUniform(__traits(identifier, texturesStruct.tupleof[i]), i);
            }
        }
        trackedBuffer.upload();
    }
}
