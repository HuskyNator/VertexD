module vertexd.files.obj_reader;

import std.ascii : isAlphaNum, isWhite;
import std.conv : ConvException, parse, to;
import std.encoding;
import std.stdio;
import std.typecons : Flag, No, Yes;
import vertexd.mesh.material;
import vertexd.mesh.mesh;
import vertexd.shaders.shaderprogram;
import vdmath;

static import std.file;

final abstract class ObjReader {
static:
    private ShaderProgram _shader;
    private Material _material;
    ShaderProgram shader() {
        if (_shader is null)
            _shader = new ShaderProgram("./obj.vert", "./obj.frag");
        return _shader;
    }

    Material material() {
        if (_material is null)
            _material = new Material(Vec!4(0.5, 0.5, 0.5, 1));
        return _material;
    }

    struct Reader {
        string path;
        size_t index = 0;
        size_t line = 0; // functional line
        size_t fileLine = 0; // line in file
        char[] data;

        this(string path) {
            this.path = path;
            data = cast(char[]) std.file.read(path);
        }

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

        // Debugging tools
        string currentLine() {
            size_t start = index;
            size_t end = index;
            if (data.length == 0)
                return "";
            while (start > 0) {
                if (data[start - 1] == '\n')
                    break;
                start -= 1;
            }
            while (end < data.length) {
                if (data[end] == '\n')
                    break;
                end += 1;
            }
            return cast(string) data[start .. end];
        }

        class ParseException : Exception {
            this(ref Reader reader, string msg) {
                super(
                    msg ~ "\nfile:" ~ reader.path ~ " line(" ~ reader.fileLine.to!string ~ "):" ~ reader.currentLine());
            }

            this(ref Reader reader, string msg, Throwable nexInChain) {
                super(msg ~ "\nfile:" ~ reader.path ~ " line(" ~ reader.fileLine.to!string ~ "):" ~ reader.currentLine(), nexInChain);
            }
        }

        // Parser
        bool peek(const char[] expect) {
            if (index + expect.length >= data.length)
                return false;
            return data[index + 1 .. index + expect.length + 1] == expect;
        }

        bool peekFakeNewline() {
            return index < data.length && data[index] == '\\' && (peek("\n") || peek("\r\n"));
        }

        bool peekSkipFakeNewline() {
            assert(index < data.length);
            if (data[index] != '\\')
                return false;
            if (peek("\n")) {
                index += 2;
                fileLine += 1;
                return true;
            }
            if (peek("\r\n")) {
                index += 3;
                fileLine += 1;
                return true;
            }
            return false; // not a fake newline
        }

        void skipWhitespace() {
            while (index < data.length) {
                if (data[index].isWhite()) {
                    if (data[index] == '\n') {
                        line += 1;
                        fileLine += 1;
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
                    fileLine += 1;
                    line += 1;
                    index += 1;
                    break;
                }
                if (peekSkipFakeNewline())
                    continue;
                index += 1;
            }
        }

        const(char[]) consumeWordSlash() {
            assert(index < data.length && data[index] != '/');
            size_t startIndex = index;
            while (index < data.length) {
                if (data[index] == '/') {
                    index += 1;
                    return data[startIndex .. index - 1];
                } else if (data[index].isWhite())
                    throw new ParseException(this, "Expected '/' not whitespace.");
                index += 1;
            }
            throw new ParseException(this, "Expected '/' but reached end of file.");
        }

        const(char[]) consumeWord() {
            assert(index < data.length && !data[index].isWhite());
            size_t startIndex = index;
            while (index < data.length) {
                if (data[index].isWhite())
                    break;
                index += 1;
            }
            size_t end = index;
            skipWhitespace();
            return data[startIndex .. end];
        }

        T consumeNumber(T, bool expectSlash = false)() {
            static if (expectSlash)
                string word = cast(string) consumeWordSlash();
            else
                string word = cast(string) consumeWord();
            try {
                size_t wordLength = word.length; // parse consumes word.
                auto result = parse!(T, string, Yes.doCount)(word);
                if (result.count != wordLength)
                    throw new ParseException(this, "Number parse length incorrect " ~ result.count.to!string ~ " instead of " ~ word
                            .length.to!string);
                return result.data;
            } catch (ConvException c) {
                throw new ParseException(this, "Number parse failed.", c);
            }
        }

        int[3][] consumeFace() {
            // Determine attribute format.
            if (firstFace) {
                firstFace = false;

                // Save parser state
                const size_t old_index = index;
                const size_t old_line = line;
                const size_t old_fileLine = fileLine;

                int firstSlashIndex = 0;
                string word = cast(string) consumeWord();

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
                            throw new ParseException(this,
                                "Face elements cannot be split by more than 2 '/'s");
                    }
                }
                // Rewind parser.
                index = old_index;
                line = old_line;
                fileLine = old_fileLine;
            }

            // Consume face data
            int[3][] results;
            size_t listLine = line;
            while (index < data.length && listLine == line) {
                int[3] face;
                if (faceSlashCount == 0) {
                    face[0] = consumeNumber!(int, false)();
                } else {
                    face[0] = consumeNumber!(int, true)();
                    if (!useUV) { // !useUV && useNormal
                        if (data[index] != '/')
                            throw new ParseException(this,
                                "Expected face definition with '//' seperator.");
                        index += 1;
                        face[2] = consumeNumber!(int, false)();
                    } else if (!useNormal) { // useUV && !useNormal
                        face[1] = consumeNumber!(int, false)();
                        continue;
                    } else { // useUV && useNormal
                        face[1] = consumeNumber!(int, true)();
                        face[2] = consumeNumber!(int, false)();
                    }
                }
                results ~= face;
            }
            return results;
        }

        auto consumeList(size_t number, Type, bool strict)() {
            Type[number] result;
            size_t listLine = line;
            foreach (i; 0 .. number) {
                if (line != listLine || index == data.length)
                    throw new ParseException(this,
                        "List of length " ~ number.to!string ~ " expected but reached end of line/file at element #" ~ i
                            .to!string);
                result[i] = consumeNumber!Type();
            }
            static if (strict) {
                if (line == listLine)
                    throw new ParseException(this, "Expected end of line at index " ~ index
                            .to!string);
            }
            return result;
        }

        Mesh convertToMesh() {
            Mesh mesh = new Mesh(ObjReader.material, ObjReader.shader());
            mesh.setAttribute(vertexData, 0u, 0u);
            if (useUV)
                mesh.setAttribute(uvData, 1u, 1u);
            // if (useNormal) normals are calculated
                mesh.setAttribute(normalData, 2u, 2u);
            mesh.setIndices(cast(uint[]) indices);
            return mesh;
        }

        // TODO: add mtl
        void parseFile() {
            skipWhitespace();
            while (index < data.length) {
                const char[] keyword = consumeWord();
                switch (keyword) {
                    case "#":
                        skipLine();
                        break;
                    case "v":
                        float[3] vertex = consumeList!(3, float, true)();
                        rawVertices ~= vertex;
                        break;
                    case "vt":
                        size_t currentLine = line;
                        float[2] uv = consumeList!(2, float, false)();
                        rawUvs ~= uv;
                        if (line == currentLine)
                            consumeList!(1, float, true)(); // uvw coordinates not supported
                        break;
                    case "vn":
                        float[3] normal = consumeList!(3, float, true)();
                        rawNormals ~= normal;
                        break;
                        // case "p": // Point
                        // case "l": // Line
                    case "f": // Face
                        int[3][] rawFaceIndices = consumeFace();
                        if (rawFaceIndices.length < 3)
                            throw new ParseException(this,
                                "Face requires at least 3 vertices, found " ~ rawFaceIndices
                                    .length.to!string);

                        Vertex[] rawFaces;
                        // Set indices of vertices to positive starting from 0
                        foreach (rawVertexIndex, int[3] rawVertex; rawFaceIndices) {
                            Vertex vertex;
                            foreach (typeIndex, i; rawVertex) {
                                if (i == 0) {
                                    if (!useAttribute[typeIndex])
                                        continue;
                                    throw new ParseException(this,
                                        "Face vertex indices cannot be 0 (count starting from 1)");
                                } else if (i < 0) {
                                    if (typeIndex == 0)
                                        vertex.vertexIndex = cast(uint)(rawVertices.length - i);
                                    else if (typeIndex == 1)
                                        vertex.uvIndex = cast(uint)(rawUvs.length - i);
                                    else // typeIndex == 2
                                        vertex.normalIndex = cast(uint)(rawNormals.length - i);
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
                                Vec!3 v1 = Vec!3(rawVertices[face[1].vertexIndex]) - Vec!3(
                                    rawVertices[face[0].vertexIndex]);
                                Vec!3 v2 = Vec!3(rawVertices[face[2].vertexIndex]) - Vec!3(
                                    rawVertices[face[0].vertexIndex]);
                                Vec!3 normal = v1.cross(v2).normalize();
                                rawNormals ~= normal;
                                foreach (i; 0 .. 3)
                                    face[i].normalIndex = cast(uint) rawNormals.length - 1;
                            }
                        }

                        foreach (Vertex[3] face; faces) {
                            uint[3] vertexIndices;
                            foreach (i, Vertex vertex; face) {
                                vertexIndices[i] = vertexHashmap.require(vertex, {
                                    assert(vertexHashmap.length != 0);
                                    uint newIndex = cast(uint) vertexHashmap.length - 1; // hashmap length already incremented inside lambda.
                                    addNewVertex(vertex);
                                    return cast(uint) newIndex;
                                }());
                            }
                            assert(vertexData.length == vertexHashmap.length);
                            indices ~= vertexIndices;
                        }
                        break;
                        // case "usemtl":
                        //     assert(0, "Not yet implemented."); // TODO
                    default:
                        stderr.writeln(keyword ~ " unsupported, skipping line");
                        skipLine();
                }
                skipWhitespace();
            }
        }

        Mesh read() {
            parseFile();
            return convertToMesh();
        }
    }

    Mesh read(string path) {
        return new Reader(path).read();
    }
}
