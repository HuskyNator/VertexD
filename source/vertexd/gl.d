module vertexd.gl;

import bindbc.opengl;

final abstract class GL {
static:
    void setFaceCulling(bool on){
        if(on)
            glEnable(GL_CULL_FACE);
        else
            glDisable(GL_CULL_FACE);
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
}
