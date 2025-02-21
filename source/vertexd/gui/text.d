module vertexd.gui.text;
import bindbc.freetype;
import vertexd.gui.freetype;
import std.string : toStringz;
import std.exception : enforce;
import std.file;
import vertexd.memory.texture;
import std.stdio : stderr, File;

class FontException : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable nextInChain = null) {
        super(msg, file, line, nextInChain);
    }
}

class Font {
    FT_Face face;

    this(string path) {
        FT_Error error = FT_New_Face(_FreeTypeLib, path.toStringz, 0, &face);
        if (error != 0)
            throw new FontException("Could not create font from path: " ~ path);
    }

    ~this() {
        FT_Face_Done(face);
    }

    void setSize(uint height) {
        FT_Error error = FT_Set_Pixel_Sizes(face, 0, height);
        if (error != 0)
            throw new FontException("Could not set font to pixel size");
    }


    Texture drawText(dstring text, uint width, uint height) {
        assert(map.length == width * height);
        uint xPos = 0;
        uint yPos = 0;

        foreach (dchar codepoint; text) {
            FT_Error error = FT_Load_Char(face, codepoint, FT_LOAD_RENDER);
            if (error != 0)
                stderr.writeln(i"Failed to loadi & render codepoint \"$(codepoint)\"");

            
        }
    }

    Texture drawText( )
}
