module vertexd.files.obj_reader;

import vdmath;
import vertexd.files.mtl_reader;
import vertexd.files.parser;
import vertexd.gl;
import vertexd.memory.buffer;
import vertexd.mesh.material;
import vertexd.mesh.mesh;
import vertexd.shaders.shaderprogram;

import std.ascii : isWhite;
import std.conv : ConvException, to;
import std.stdio;
import std.path;

final abstract class ObjReader {
static:
    private ShaderProgram _shader;
    private ObjMaterial _defaultMaterial;
    ShaderProgram shader() {
        if (_shader is null)
            _shader = new ShaderProgram("./obj.vert", "./obj.frag");
        return _shader;
    }

    ObjMaterial defaultMaterial() {
        if (_defaultMaterial is null)
            _defaultMaterial = new ObjMaterial("_default");
        return _defaultMaterial;
    }

    struct ObjParser {
        Parser parser;
        alias this = parser;
        string root;

        this(string path) {
            this.parser = Parser(path);
            this.root = dirName(path);
        }

        size_t objLine = 0; // logical line (no fake line breaks) <= line

        ObjMaterial[string] materials;
        size_t[] meshStartIndices;
        ObjMaterial[] meshMaterials;

        // As read from file
        float[3][] rawVertices;
        float[2][] rawUvs;
        float[3][] rawNormals;

        // Aggregated actually useful buffer data
        float[3][] vertexData;
        float[2][] uvData;
        float[3][] normalData;
        uint[3][] indices;

        // Aggregation tools
        struct Vertex {
            union {
                struct {
                    uint vertexIndex;
                    uint uvIndex;
                    uint normalIndex;
                }

                uint[3] attributes;
            }
        }

        uint[Vertex] vertexHashmap;
        debug size_t verticesReused = 0;

        void addNewVertex(Vertex vertex) {
            vertexData ~= rawVertices[vertex.vertexIndex];
            if (useUV)
                uvData ~= rawUvs[vertex.uvIndex];
            // if (useNormal) (normals are calculated on the fly)
            normalData ~= rawNormals[vertex.normalIndex];
        }

        // Attribute format contract
        bool firstFace = true;
        int faceSlashCount = 0;
        union {
            struct {
                const bool useVertex = true;
                bool useUV = false;
                bool useNormal = false;
            }

            bool[3] useAttribute;
        }

        // Parser
        bool peekFakeNewline() {
            return index < data.length && data[index] == '\\' && (peek("\n") || peek("\r\n"));
        }

        bool peekSkipFakeNewline() {
            assert(index < data.length);
            if (data[index] != '\\')
                return false;
            if (peek("\n")) {
                index += 2;
                line += 1;
                return true;
            }
            if (peek("\r\n")) {
                index += 3;
                line += 1;
                return true;
            }
            return false; // not a fake newline
        }

        void skipWhitespace() {
            while (index < data.length) {
                if (data[index].isWhite()) {
                    if (data[index] == '\n') {
                        line += 1;
                        objLine += 1;
                    }
                    index += 1;
                    continue;
                }
                if (peekSkipFakeNewline())
                    continue;
                break;
            }
        }

        void skipLine() {
            while (index < data.length) {
                if (data[index] == '\n') {
                    objLine += 1;
                    line += 1;
                    index += 1;
                    break;
                }
                if (peekSkipFakeNewline())
                    continue;
                index += 1;
            }
        }

        private enum string _assertNewlineMixin =
            `size_t _oldObjLine = objLine;
            scope (success)
                if (objLine == _oldObjLine)
                    throw new Parser.ParseException(this, "Expected end of line at index " ~ index.to!string);`;

        const(char[]) consumeWord(bool expectNewline)() {
            static if (expectNewline)
                mixin(_assertNewlineMixin);
            const(char[]) word = parser.consumeWord!false(&skipWhitespace);
            return word;
        }

        const(char[]) consumeWordSlash() {
            assert(index < data.length && data[index] != '/');
            size_t startIndex = index;
            while (index < data.length) {
                if (data[index] == '/') {
                    index += 1;
                    return data[startIndex .. index - 1];
                } else if (data[index].isWhite())
                    throw new Parser.ParseException(parser, "Expected '/' not whitespace.");
                index += 1;
            }
            throw new Parser.ParseException(parser, "Expected '/' but reached end of file.");
        }

        T consumeNumber(T, bool expectNewline = false)() {
            static if (expectNewline)
                mixin(_assertNewlineMixin);
            string word = cast(string) parser.consumeWord!(false)(&skipWhitespace);
            return parser.parseNumber!T(word);
        }

        T consumeNumberSlash(T)() {
            string word = cast(string) consumeWordSlash();
            return parser.parseNumber!T(word);
        }

        auto consumeList(size_t number, Type, bool expectNewline, bool seperator = false)() {
            Type[number] result;
            static if (expectNewline)
                mixin(_assertNewlineMixin);
            size_t listLine = objLine;
            foreach (i; 0 .. number) {
                if (objLine != listLine || index == data.length)
                    throw new Parser.ParseException(this,
                        "List of length " ~ number.to!string ~ " expected but reached end of line/file after element #" ~ i
                            .to!string);
                result[i] = consumeNumber!Type();
                static if (seperator) {
                    if (i == number = 1)
                        continue;
                    if (index == data.length || data[index] != ',')
                        throw new Parser.ParseException(this, "List expected with ',' seperator after element #" ~ (
                                i + 1)
                                .to!string);
                }
            }
            return result;
        }

        int[3][] consumeFace() {
            // Determine attribute format.
            if (firstFace) {
                firstFace = false;

                // Save parser state
                const size_t old_index = index;
                const size_t old_line = line;
                const size_t old_fileLine = objLine;

                int firstSlashIndex = 0;
                string word = cast(string) consumeWord!false();

                foreach (i, char c; word) {
                    if (c == '/') {
                        faceSlashCount += 1;
                        if (faceSlashCount == 1) {
                            firstSlashIndex = cast(int) i;
                            useUV = true;
                        } else if (faceSlashCount == 2) {
                            useUV = (cast(int) i > firstSlashIndex + 1);
                            useNormal = true;
                        } else
                            throw new Parser.ParseException(parser,
                                "Face elements cannot be split by more than 2 '/'s.");
                    }
                }
                // Rewind parser.
                index = old_index;
                line = old_line;
                objLine = old_fileLine;
            }

            // Consume face data
            int[3][] results;
            size_t listLine = objLine;
            while (index < data.length && listLine == objLine) {
                int[3] face;
                if (faceSlashCount == 0) {
                    face[0] = consumeNumber!int();
                } else {
                    face[0] = consumeNumberSlash!int();
                    if (!useUV) { // !useUV && useNormal
                        if (data[index] != '/')
                            throw new Parser.ParseException(parser,
                                "Expected face definition with '//' seperator.");
                        index += 1;
                        face[2] = consumeNumber!int();
                    } else if (!useNormal) { // useUV && !useNormal
                        face[1] = consumeNumber!int();
                        continue;
                    } else { // useUV && useNormal
                        face[1] = consumeNumberSlash!int();
                        face[2] = consumeNumber!int();
                    }
                }
                results ~= face;
            }
            return results;
        }

        Mesh[] convertToMeshes() {
            assert(meshMaterials.length == meshStartIndices.length);
            if (indices.length == 0)
                return [];
            if (meshStartIndices.length == 0) { // No materials used -> use default
                meshStartIndices = [0];
                meshMaterials = [defaultMaterial()];
            }

            Buffer indexBuffer = new Buffer(cast(ubyte[]) indices, Buffer.StaticStorage);
            Mesh[] meshes;
            meshes.reserve(meshStartIndices.length);
            foreach (i, start; meshStartIndices) {
                ObjMaterial material = meshMaterials[i];
                Mesh mesh = new Mesh(material, ObjReader.shader());

                mesh.setAttribute(vertexData, 0u, 0u);
                if (useUV)
                    mesh.setAttribute(uvData, 1u, 1u); // if (useNormal) normals are calculated
                mesh.setAttribute(normalData, 2u, 2u);

                size_t end = (i + 1 == meshStartIndices.length) ? indices.length
                    : meshStartIndices[i + 1];
                mesh.setIndices(indexBuffer, cast(int)(end - start) * 3, start * 3 * uint.sizeof, GL
                        .getType!uint);
                meshes ~= mesh;
            }
            return meshes;
        }

        void parseFile() {
            skipWhitespace();
            while (index < data.length) {
                size_t startLine = objLine;
                const char[] keyword = consumeWord!false();
                switch (keyword) {
                case "#":
                    if (objLine == startLine) // prevent skipping next line.
                        skipLine();
                    break;
                case "v":
                    float[3] vertex = consumeList!(3, float, true)();
                    rawVertices ~= vertex;
                    break;
                case "vt":
                    size_t currentObjLine = objLine;
                    float[2] uv = consumeList!(2, float, false)();
                    rawUvs ~= uv;
                    if (objLine == currentObjLine)
                        consumeList!(1, float, true)(); // uvw coordinates not supported
                    break;
                case "vn":
                    float[3] normal = consumeList!(3, float, true)();
                    rawNormals ~= normal;
                    break;
                    // case "p": // Point
                    // case "l": // line
                case "f": // Face
                    int[3][] rawFaceIndices = consumeFace();
                    if (rawFaceIndices.length < 3)
                        throw new Parser.ParseException(parser,
                            "Face requires at least 3 vertices, found " ~ rawFaceIndices
                                .length.to!string ~ '.');
                    Vertex[] rawFaces;
                    // Set indices of vertices to positive starting from 0
                    foreach (rawVertexIndex, int[3] rawVertex; rawFaceIndices) {
                        Vertex vertex;
                        foreach (typeIndex, i; rawVertex) {
                            if (i == 0) {
                                if (!useAttribute[typeIndex])
                                    continue;
                                throw new Parser.ParseException(parser,
                                    "Face vertex indices cannot be 0 (count starting from 1).");
                            } else if (i < 0) {
                                if (typeIndex == 0)
                                    vertex.vertexIndex = cast(uint)(
                                        rawVertices.length - i);
                                else if (
                                    typeIndex == 1)
                                    vertex.uvIndex = cast(uint)(rawUvs.length - i);
                                else // typeIndex == 2
                                    vertex.normalIndex = cast(uint)(
                                        rawNormals.length - i);
                            } else
                                vertex.attributes[typeIndex] = cast(uint) i - 1;
                        }
                        rawFaces ~= vertex;
                    }

                    //Transform triangle fan to triangles
                    Vertex[3][] faces;
                    for (size_t second = 1; second + 1 < rawFaces.length; second += 1) {
                        faces ~= [
                            rawFaces[0], rawFaces[second],
                            rawFaces[second + 1]
                        ];
                    }

                    // TODO: ensure generating normals does not cause every vertex to be seperate.
                    // might be difficult.
                    if (!useNormal) { // calculate normals
                        foreach (ref Vertex[3] face; faces) {
                            Vec!3 v1 = Vec!3(
                                rawVertices[face[1].vertexIndex]) - Vec!3(
                                rawVertices[face[0].vertexIndex]);
                            Vec!3 v2 = Vec!3(
                                rawVertices[face[2].vertexIndex]) - Vec!3(
                                rawVertices[face[0].vertexIndex]);
                            Vec!3 normal = v1.cross(v2).normalize();
                            rawNormals ~= normal;
                            foreach (i; 0 .. 3)
                                face[i].normalIndex = cast(
                                    uint) rawNormals.length - 1;
                        }
                    }

                    foreach (Vertex[3] face; faces) {
                        uint[3] vertexIndices;
                        foreach (i, Vertex vertex; face) {
                            debug verticesReused += 1;
                            vertexIndices[i] = vertexHashmap.require(vertex, {
                                assert(vertexHashmap.length != 0);
                                debug verticesReused -= 1;
                                uint newIndex = cast(uint) vertexHashmap.length - 1; // hashmap length already incremented inside lambda.
                                addNewVertex(vertex);
                                return cast(uint) newIndex;
                            }());
                        }
                        assert(vertexData.length == vertexHashmap
                                .length);
                        indices ~= vertexIndices;
                    }
                    break;
                case "mtllib":
                    string path = root ~ dirSeparator ~ cast(string) consumeWord!true();
                    ObjMaterial[string] newMaterials = MtlReader.read(path);
                    foreach (element; newMaterials.byKeyValue()) {
                        if (element.key in materials)
                            throw new Parser.ParseException(parser, "Found duplicate material in mtl file \"" ~ path ~ "\", \"" ~ element
                                    .key ~ "\" was already defined.");
                        materials[element.key] = element.value;
                    }
                    break;
                case "usemtl":
                    string name = cast(string) consumeWord!true();
                    ObjMaterial* material = name in materials;
                    if (material is null)
                        throw new Parser.ParseException(parser, "Unknown material used; \"" ~ name ~ "\".");

                    if (meshStartIndices.length == 0 && indices.length > 0) { // Insert default
                        meshStartIndices ~= 0;
                        meshMaterials ~= defaultMaterial();
                    }

                    meshStartIndices ~= indices.length;
                    meshMaterials ~= *material;
                    break;
                default:
                    stderr.writeln(
                        "Keyword \"" ~ keyword ~ "\" unsupported, skipping line.");
                    skipLine();
                }
                skipWhitespace();
            }
        }

        Mesh[] read() {
            parseFile();
            return convertToMeshes();
        }
    }

    Mesh[] read(string path) {
        return ObjParser(path).read();
    }
}
