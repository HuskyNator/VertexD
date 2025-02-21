module vertexd.io.obj.mtl_reader;

import gamut;
import vdmath;
import vertexd.io.obj.material;
import vertexd.io.parser;
import vertexd.memory.bindless_texture;
import vertexd.memory.texture;

import std.path : dirName, dirSeparator;
import std.stdio : stderr;

final abstract class MtlReader {
static:
	struct MtlParser {
		Parser parser;
		string root;
		alias this = parser;

		this(string path) {
			this.root = dirName(path);
			this.parser = Parser(path);
		}

		ObjMaterial[string] materials;
		ObjMaterial currentMaterial;
		void requireMaterial() {
			if (currentMaterial is null)
				new Parser.ParseException(parser, "Material declaration 'newmtl <name>' required before declaring properties.");
		}

		void parseFile() {
			skipWhitespace();
			while (index < data.length) {
				if (data[index] == '#') {
					index += 1;
					skipLine();
					skipWhitespace();
					continue;
				}
				string keyword = parser.consumeWord!false();
				switch (keyword) {
					case "newmtl":
						string name = parser.consumeWord!true();
						if (name in materials)
							throw new Parser.ParseException(parser, "Material \"" ~ name ~ "\" was already defined.");
						ObjMaterial material = new ObjMaterial(name);
						currentMaterial = material;
						materials[name] = material;
						break;
					case "Ka":
						requireMaterial();
						Vec!3 ka = Vec!3(parser.consumeList!(3, float, true));
						currentMaterial.trackedBuffer.ka = ka;
						break;
					case "Kd":
						requireMaterial();
						Vec!3 kd = Vec!3(parser.consumeList!(3, float, true));
						currentMaterial.trackedBuffer.kd = kd;
						break;
					case "Ks":
						requireMaterial();
						Vec!3 ks = Vec!3(parser.consumeList!(3, float, true));
						currentMaterial.trackedBuffer.ks = ks;
						break;
					case "Ns":
						requireMaterial();
						float ns = parser.consumeNumber!(float, true)();
						currentMaterial.trackedBuffer.ns = ns;
						break;
					case "Tr":
						requireMaterial();
						float d = 1 - parser.consumeNumber!(float, true)();
						currentMaterial.trackedBuffer.d = d;
						break;
					case "d":
						requireMaterial();
						float d = parser.consumeNumber!(float, true)();
						currentMaterial.trackedBuffer.d = d;
						break;
					case "illum":
						requireMaterial();
						uint illum = parser.consumeNumber!(uint, true)();
						currentMaterial.trackedBuffer.illum = illum;
						break;
					case "map_Ka":
						string file = parser.consumeWord!true();
						string path = root ~ dirSeparator ~ file;
						Texture texture = new Texture(path, Texture.Type.RGBA);
						version (OpenGLBindless) {
							BindlessTexture bTexture = new BindlessTexture(texture);
							currentMaterial.mapKa = bTexture;
						} else
							currentMaterial.mapKa = texture;
						break;
					case "map_Kd":
						requireMaterial();
						string file = parser.consumeWord!true();
						string path = root ~ dirSeparator ~ file;
						Texture texture = new Texture(path, Texture.Type.RGBA);
						version (OpenGLBindless) {
							BindlessTexture bTexture = new BindlessTexture(texture);
							currentMaterial.mapKd = bTexture;
						} else
							currentMaterial.mapKd = texture;
						break;
					case "map_Ks":
						requireMaterial();
						string file = parser.consumeWord!true();
						string path = root ~ dirSeparator ~ file;
						Texture texture = new Texture(path, Texture.Type.RGBA);
						version (OpenGLBindless) {
							BindlessTexture bTexture = new BindlessTexture(texture);
							currentMaterial.mapKs = bTexture;
						} else
							currentMaterial.mapKs = texture;
						break;
					case "map_Ns":
						requireMaterial();
						string file = parser.consumeWord!true();
						string path = root ~ dirSeparator ~ file;
						Texture texture = new Texture(path, Texture.Type.Grey);
						version (OpenGLBindless) {
							BindlessTexture bTexture = new BindlessTexture(texture);
							currentMaterial.mapNs = bTexture;
						} else
							currentMaterial.mapNs = texture;
						break;
					case "map_D":
						requireMaterial();
						string file = parser.consumeWord!true();
						string path = root ~ dirSeparator ~ file;
						Texture texture = new Texture(path, Texture.Type.Grey);
						version (OpenGLBindless) {
							BindlessTexture bTexture = new BindlessTexture(texture);
							currentMaterial.mapD = bTexture;
						} else
							currentMaterial.mapD = texture;
						break;
					default:
						stderr.writeln("Keyword \"" ~ keyword ~ "\" unsupported, skipping line.");
						skipLine();
				}
				skipWhitespace();
			}
		}

		ObjMaterial[string] read() {
			parseFile();
			return materials;
		}
	}

	ObjMaterial[string] read(string path) {
		return MtlParser(path).read();
	}
}
