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
        if (_FreeTypeLib !is null) // library still valid
            FT_Done_Face(face);
    }

    void setSize(uint height) {
        FT_Error error = FT_Set_Pixel_Sizes(face, 0, height);
        if (error != 0)
            throw new FontException("Could not set font to pixel size");
    }

    Texture drawText(dstring text, uint width, uint height) {
        uint xPos = 0; // in 1/64th of pixel
        uint yPos = 0; // in 1/64th of pixel

        ubyte[] pixels = new ubyte[width * height];

        foreach (dchar codepoint; text) {
            FT_Error error = FT_Load_Char(face, codepoint, FT_LOAD_RENDER);
            if (error != 0)
                stderr.writeln(i"Failed to load & render codepoint \"$(codepoint)\"");

            // Draw to pixel buffer
            foreach (x; 0 .. face.glyph.bitmap.width) {
                foreach (y; 0 .. face.glyph.bitmap.rows) {
                    int xInd = xPos / 64 + x + face.glyph.bitmapLeft;
                    int yInd = yPos / 64 + (face.glyph.bitmap.rows-y) + face.glyph.bitmapTop;

                    if (xInd < 0 || xInd >= width)
                        continue;
                    if (yInd < 0 || yInd >= height)
                        continue;

                    ubyte oldVal = pixels[xInd + yInd * width];
                    ubyte newVal = face.glyph.bitmap.buffer[x + y * face
                            .glyph.bitmap.width];
                    if (newVal > oldVal) // write only max value
                        pixels[xInd + yInd * width] = newVal;
                }
            }

            // Advance position
            xPos += face.glyph.advance.x;
            yPos += face.glyph.advance.y;
        }

        return new Texture(width, height, cast(ubyte[1][]) pixels, false);
    }
}
