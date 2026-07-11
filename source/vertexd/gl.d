module vertexd.gl;

import bindbc.opengl;

final abstract class GL {
static:
    void setFaceCulling(bool on) {
        if (on)
            glEnable(GL_CULL_FACE);
        else
            glDisable(GL_CULL_FACE);
    }

    void setDepthTest(bool on) {
        if (on)
            glEnable(GL_DEPTH_TEST);
        else
            glDisable(GL_DEPTH_TEST);
    }

    enum Type : uint {
        Bool = GL_BOOL,
        Byte = GL_BYTE,
        UByte = GL_UNSIGNED_BYTE,
        Short = GL_SHORT,
        UShort = GL_UNSIGNED_SHORT,
        Int = GL_INT,
        UInt = GL_UNSIGNED_INT,
        FixedPoint = GL_FIXED,
        HalfFloat = GL_HALF_FLOAT,
        Float = GL_FLOAT,
        Double = GL_DOUBLE
    }

    size_t getTypeSize(Type type) {
        final switch (type) {
            case Type.Bool:
                return 8; // Assumption
            case Type.Byte:
                return 8;
            case Type.UByte:
                return 8;
            case Type.Short:
                return 16;
            case Type.UShort:
                return 16;
            case Type.Int:
                return 32;
            case Type.UInt:
                return 32;
            case Type.FixedPoint:
                return 32;
            case Type.HalfFloat:
                return 16;
            case Type.Float:
                return 32;
            case Type.Double:
                return 64;
        }
    }

    enum Type getType(T) = _getType!T();
    private Type _getType(T)() {
        static if (is(T == bool))
            return Type.Bool;
        else static if (is(T == byte))
            return Type.Byte;
        else static if (is(T == ubyte))
            return Type.UByte;
        else static if (is(T == short))
            return Type.Short;
        else static if (is(T == ushort))
            return Type.UShort;
        else static if (is(T == int))
            return Type.Int;
        else static if (is(T == uint))
            return Type.UInt;
        else static if (is(T == float))
            return Type.Float;
        else static if (is(T == double))
            return Type.Double;
        else
            static assert(0, "Conversion to GL.Type not supported: " ~ T.stringof);
    }

    string glslTypeToString(GLenum typeEnum) {
        import std.stdio : stderr;
        import std.conv : to;

        switch (typeEnum) {
            case GL_FLOAT:
                return "float";
            case GL_FLOAT_VEC2:
                return "vec2";
            case GL_FLOAT_VEC3:
                return "vec3";
            case GL_FLOAT_VEC4:
                return "vec4";
            case GL_DOUBLE:
                return "double";
            case GL_DOUBLE_VEC2:
                return "dvec2";
            case GL_DOUBLE_VEC3:
                return "dvec3";
            case GL_DOUBLE_VEC4:
                return "dvec4";
            case GL_INT:
                return "int";
            case GL_INT_VEC2:
                return "ivec2";
            case GL_INT_VEC3:
                return "ivec3";
            case GL_INT_VEC4:
                return "ivec4";
            case GL_UNSIGNED_INT:
                return "unsigned_int";
            case GL_UNSIGNED_INT_VEC2:
                return "uvec2";
            case GL_UNSIGNED_INT_VEC3:
                return "uvec3";
            case GL_UNSIGNED_INT_VEC4:
                return "uvec4";
            case GL_BOOL:
                return "bool";
            case GL_BOOL_VEC2:
                return "bvec2";
            case GL_BOOL_VEC3:
                return "bvec3";
            case GL_BOOL_VEC4:
                return "bvec4";
            case GL_FLOAT_MAT2:
                return "mat2";
            case GL_FLOAT_MAT3:
                return "mat3";
            case GL_FLOAT_MAT4:
                return "mat4";
            case GL_FLOAT_MAT2x3:
                return "mat2x3";
            case GL_FLOAT_MAT2x4:
                return "mat2x4";
            case GL_FLOAT_MAT3x2:
                return "mat3x2";
            case GL_FLOAT_MAT3x4:
                return "mat3x4";
            case GL_FLOAT_MAT4x2:
                return "mat4x2";
            case GL_FLOAT_MAT4x3:
                return "mat4x3";
            case GL_DOUBLE_MAT2:
                return "dmat2";
            case GL_DOUBLE_MAT3:
                return "dmat3";
            case GL_DOUBLE_MAT4:
                return "dmat4";
            case GL_DOUBLE_MAT2x3:
                return "dmat2x3";
            case GL_DOUBLE_MAT2x4:
                return "dmat2x4";
            case GL_DOUBLE_MAT3x2:
                return "dmat3x2";
            case GL_DOUBLE_MAT3x4:
                return "dmat3x4";
            case GL_DOUBLE_MAT4x2:
                return "dmat4x2";
            case GL_DOUBLE_MAT4x3:
                return "dmat4x3";
            case GL_SAMPLER_1D:
                return "sampler1D";
            case GL_SAMPLER_2D:
                return "sampler2D";
            case GL_SAMPLER_3D:
                return "sampler3D";
            case GL_SAMPLER_CUBE:
                return "samplerCube";
            case GL_SAMPLER_1D_SHADOW:
                return "sampler1DShadow";
            case GL_SAMPLER_2D_SHADOW:
                return "sampler2DShadow";
            case GL_SAMPLER_1D_ARRAY:
                return "sampler1DArray";
            case GL_SAMPLER_2D_ARRAY:
                return "sampler2DArray";
            case GL_SAMPLER_1D_ARRAY_SHADOW:
                return "sampler1DArrayShadow";
            case GL_SAMPLER_2D_ARRAY_SHADOW:
                return "sampler2DArrayShadow";
            case GL_SAMPLER_2D_MULTISAMPLE:
                return "sampler2DMS";
            case GL_SAMPLER_2D_MULTISAMPLE_ARRAY:
                return "sampler2DMSArray";
            case GL_SAMPLER_CUBE_SHADOW:
                return "samplerCubeShadow";
            case GL_SAMPLER_BUFFER:
                return "samplerBuffer";
            case GL_SAMPLER_2D_RECT:
                return "sampler2DRect";
            case GL_SAMPLER_2D_RECT_SHADOW:
                return "sampler2DRectShadow";
            case GL_INT_SAMPLER_1D:
                return "isampler1D";
            case GL_INT_SAMPLER_2D:
                return "isampler2D";
            case GL_INT_SAMPLER_3D:
                return "isampler3D";
            case GL_INT_SAMPLER_CUBE:
                return "isamplerCube";
            case GL_INT_SAMPLER_1D_ARRAY:
                return "isampler1DArray";
            case GL_INT_SAMPLER_2D_ARRAY:
                return "isampler2DArray";
            case GL_INT_SAMPLER_2D_MULTISAMPLE:
                return "isampler2DMS";
            case GL_INT_SAMPLER_2D_MULTISAMPLE_ARRAY:
                return "isampler2DMSArray";
            case GL_INT_SAMPLER_BUFFER:
                return "isamplerBuffer";
            case GL_INT_SAMPLER_2D_RECT:
                return "isampler2DRect";
            case GL_UNSIGNED_INT_SAMPLER_1D:
                return "usampler1D";
            case GL_UNSIGNED_INT_SAMPLER_2D:
                return "usampler2D";
            case GL_UNSIGNED_INT_SAMPLER_3D:
                return "usampler3D";
            case GL_UNSIGNED_INT_SAMPLER_CUBE:
                return "usamplerCube";
            case GL_UNSIGNED_INT_SAMPLER_1D_ARRAY:
                return "usampler1DArray";
            case GL_UNSIGNED_INT_SAMPLER_2D_ARRAY:
                return "usampler2DArray";
            case GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE:
                return "usampler2DMS";
            case GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE_ARRAY:
                return "usampler2DMSArray";
            case GL_UNSIGNED_INT_SAMPLER_BUFFER:
                return "usamplerBuffer";
            case GL_UNSIGNED_INT_SAMPLER_2D_RECT:
                return "usampler2DRect";
            case GL_INT64_ARB:
                return "int64_t";
            case GL_INT64_VEC2_ARB:
                return "i64vec2";
            case GL_INT64_VEC3_ARB:
                return "i64vec3";
            case GL_INT64_VEC4_ARB:
                return "i64vec4";
            case GL_UNSIGNED_INT64_ARB:
                return "uint64_t";
            case GL_UNSIGNED_INT64_VEC2_ARB:
                return "u64vec2";
            case GL_UNSIGNED_INT64_VEC3_ARB:
                return "u64vec3";
            case GL_UNSIGNED_INT64_VEC4_ARB:
                return "u64vec4";
            default:
                stderr.writeln("Unknown type enum: ", typeEnum);
                return "unknown(" ~ typeEnum.to!string ~ ")";
        }
    }
}
