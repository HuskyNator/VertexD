module vertexd.files.mtl_reader;
static import std.file;
import vertexd.files.parser;
import vertexd.mesh.material;
import std.stdio : stderr;
import vdmath;

final abstract class MtlReader {
static:
	struct MtlParser {
		Parser parser;
		alias this = parser;

		this(string path) {
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
				const char[] keyword = parser.consumeWord!false();
				switch (keyword) {
				case "#":
					skipLine();
					break;
				case "newmtl":
					string name = cast(string) parser.consumeWord!true();
					if (name in materials)
						throw new Parser.ParseException(parser, "Material \"" ~ name ~ "\" was already defined.");
					ObjMaterial material = new ObjMaterial(name);
					currentMaterial = material;
					materials[name] = material;
					break;
				case "Ka":
					Vec!3 ka = Vec!3(parser.consumeList!(3, float, true));
					requireMaterial();
					currentMaterial._data.ka = ka;
					break;
				case "Kd":
					Vec!3 kd = Vec!3(parser.consumeList!(3, float, true));
					requireMaterial();
					currentMaterial._data.kd = kd;
					break;
				case "Ks":
					Vec!3 ks = Vec!3(parser.consumeList!(3, float, true));
					requireMaterial();
					currentMaterial._data.ks = ks;
					break;
				case "Ns":
					float ns = parser.consumeNumber!(float, true)();
					requireMaterial();
					currentMaterial._data.ns = ns;
					break;
				case "illum":
					uint illum = parser.consumeNumber!(uint, true)();
					requireMaterial();
					currentMaterial._data.illum = illum;
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
