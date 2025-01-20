module vertexd.files.obj_reader;

import vertexd.mesh.mesh;
import std.file : exists, readData = read;
import std.ascii : isWhite, isAlphaNum;
import std.exception : enforce;
import std.encoding;
import std.conv : parse, ConvException, to;
import vertexd.shaders.shaderprogram;
import std.typecons : Flag, Yes, No;
import std.stdio;

final abstract class ObjReader {
static:
    private ShaderProgram _shader;
    ShaderProgram shader() {
        if (_shader is null)
            _shader = new ShaderProgram("./obj.vert", "./obj.frag");
        return _shader;
    }

    Mesh read(string path) {
        size_t index = 0;
        size_t line = 0; // functional line
        size_t fileLine = 0; // line in file
        enforce(exists(path), "File does not exist: " ~ path);
        const char[] data = cast(const char[]) readData(path);
        float[3][] vertices;
        float[2][] uvs;
        float[3][] normals;
        uint[3][] indices;

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
            this(string msg) {
                super(msg ~ "\nfile:" ~ path ~ " line(" ~ fileLine.to!string ~ "):" ~ currentLine());
            }

            this(string msg, Throwable nexInChain) {
                super(msg ~ "\nfile:" ~ path ~ " line(" ~ fileLine.to!string ~ "):" ~ currentLine(), nexInChain);
            }
        }

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

        // bool expect(Args...)(Args args) {
        //     if (index == data.length)
        //         return false;
        //     static foreach (arg; args) {
        //         static if (is(typeof(arg) == char)) {
        //             if (data[index] == arg)
        //                 return true;
        //         } else {
        //             if (arg(data[index]))
        //                 return true;
        //         }
        //     }
        //     return false;
        // }

        T consumeNumber(T)() {
            string word = cast(string) consumeWord();
            try {
                auto result = parse!(T, string, Yes.doCount)(word);
                if (result.count != word.length)
                    throw new ParseException("Number parse length incorrect");
                return result.data;
            } catch (ConvException c) {
                throw new ParseException("Number parse failed.", c);
            }
        }

        Type[] consumeFullList(Type)() {
            Type[] result;
            size_t listLine = line;
            while (index < data.length && listLine == line) {
                result ~= consumeNumber!Type();
            }
            return result;
        }

        auto consumeList(size_t number, Type, bool strict)() {
            Type[number] result;
            size_t listLine = line;
            foreach (i; 0 .. number) {
                if (line != listLine || index == data.length)
                    throw new ParseException(
                        "List of length " ~ number.to!string ~ " expected but reached end of line/file at element #" ~ i
                            .to!string);
                result[i] = consumeNumber!Type();
            }
            static if (strict) {
                if (line == listLine)
                    throw new ParseException("Expected end of line at index " ~ index.to!string);
            }
            return result;
        }

        Mesh convertToMesh() {
            Mesh mesh = new Mesh();
            mesh.setAttribute(vertices, 0u, 0u);
            mesh.setAttribute(normals, 1u, 1u);
            mesh.setAttribute(uvs, 2u, 2u);
            mesh.setIndices(cast(uint[]) indices);
            mesh.shader = ObjReader.shader();
            return mesh;
        }

        // TODO: add mtl
        Mesh parseFile() {
            skipWhitespace();
            while (index < data.length) {
                const char[] keyword = consumeWord();
                switch (keyword) {
                    case "#":
                        skipLine();
                        break;
                    case "v":
                        float[3] vertex = consumeList!(3, float, true)();
                        vertices ~= vertex;
                        break;
                    case "vt":
                        size_t currentLine = line;
                        float[2] uv = consumeList!(2, float, false)();
                        uvs ~= uv;
                        if (line == currentLine)
                            consumeList!(1, float, true)(); // uvw coordinates not supported
                        break;
                    case "vn":
                        float[3] normal = consumeList!(3, float, true)();
                        normals ~= normal;
                        break;
                        // case "p": // Point
                        // case "l": // Line
                    case "f": // Face
                        int[] faceIndices = consumeFullList!int();
                        if (indices.length < 3)
                            throw new ParseException(
                                "Face requires at least 3 vertices, found " ~ faceIndices
                                    .length.to!string);

                        // Set indices of vertices to positive start from 0
                        foreach (ref i; faceIndices) {
                            assert(i != 0); // start from 1
                            if (i < 0)
                                i = cast(int)(vertices.length - i);
                            else
                                i = i - 1;
                        }

                        // Transform triangle fan to triangles
                        for (size_t second = 1; second + 1 < faceIndices.length; second += 1) {
                            indices ~= [
                                faceIndices[0], faceIndices[second],
                                faceIndices[second + 1]
                            ];
                        }
                        break;
                    case "usemtl":
                        assert(0, "Not yet implemented."); // TODO
                    default:
                        stderr.writeln(keyword ~ " unsupported, skipping line");
                        skipLine();
                }
                skipWhitespace();
            }
            return convertToMesh();
        }

        return parseFile();
    }
}
