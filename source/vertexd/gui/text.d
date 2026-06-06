module vertexd.gui.text;

import std.exception : enforce;
import std.file;
import std.stdio : File, stderr;
import std.string : toStringz;

import bindbc.freetype;
import vertexd.gui.freetype;
import bindbc.opengl : GL_R8;
import vertexd.memory;

class FontException : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable nextInChain = null) {
        super(msg, file, line, nextInChain);
    }
}

class Font {
    FT_Face face;
    float maxAdvanceWidth; // pixels
    float lineHeight; // pixels

    this(string path) {
        FT_Error error = FT_New_Face(_FreeTypeLib, path.toStringz, 0, &face);
        if (error != 0)
            throw new FontException("Could not create font from path: " ~ path);
        if (!FT_IS_SCALABLE(face))
            throw new FontException("Provided font is unsupported (not scalable): " ~ path);
    }

    ~this() {
        if (_FreeTypeLib !is null) // library still valid
            FT_Done_Face(face);
    }

    void setSize(uint height) { // see: https://stackoverflow.com/a/65706983
        FT_Error error = FT_Set_Pixel_Sizes(face, 0, height);
        if (error != 0)
            throw new FontException("Could not set font to pixel size");

        this.maxAdvanceWidth = getMaxAdvancePixelWidth();
        this.lineHeight = getLinePixelHeight();
    }

    private float getMaxAdvancePixelWidth() {
        return (cast(float) face.size.metrics.maxAdvance) / (2 ^^ 6);
    }

    private float getLinePixelHeight() {
        return (cast(float) face.height) / (2 ^^ 6);
    }

    private static int round16Fractional(uint frac) {
        assert(frac <= uint.max - 2 ^^ 15);
        return cast(int)((frac + 2 ^^ 15) >> 16);
    }

    private static int round6Fractional(uint frac) {
        assert(frac <= uint.max - 2 ^^ 5);
        return cast(int)((frac + 2 ^^ 5) >> 6);
    }

    private static uint ceil6Fractional(uint frac) { // TODO: doublecheck
        assert(frac <= uint.max - 2 ^^ 6 - 1);
        return (frac + 2 ^^ 6 - 1) >> 6;
    }

    // TODO: Add colored glyph support (FT_LOAD_COLOR)

    /// Params:
    ///   text = text to render
    ///   width = width of canvas (in units of maxGlyphWidth)
    ///   height = height of canvas (in units of lineHeight)
    ///   pixels = buffer to store rendered text in
    void drawText(dstring text, uint width, uint height, ubyte[] pixels) {
        assert(pixels !is null);
        assert(pixels.length == width * height);
        pixels[] = 0; // initialize

        uint xPosStart = (face.bbox.xMin < 0) ? round16Fractional(
            (cast(uint)-face.bbox.xMin) * face.size.metrics.xScale) : 0;
        uint yPosStart = cast(uint)((face.bbox.yMin < 0) ? round16Fractional(
                (cast(uint)-face.bbox.yMin) * face.size.metrics.yScale) : 0);

        uint xPos = xPosStart; // .6 fixed point fractional pixel
        uint yPos = yPosStart; // .6 fixed point fractional pixel

        foreach (dchar codepoint; text) {
            FT_Error error = FT_Load_Char(face, codepoint, FT_LOAD_RENDER);
            if (error != 0) {
                stderr.writeln(i"Failed to load & render codepoint \"$(codepoint)\"");
                continue;
            }

            // Draw to pixel buffer
            int xPosGrid = round6Fractional(xPos) + face.glyph.bitmapLeft;
            int yPosGrid = round6Fractional(yPos) + face.glyph.bitmapTop;
            foreach (uint x; 0 .. face.glyph.bitmap.width) {
                foreach (uint y; 0 .. face.glyph.bitmap.rows) {

                    long xInd = xPosGrid + x;
                    long yInd = yPosGrid - y;

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
    }

    uint calculateWidth(dstring text) {
        uint width = 0; // .6 fixedpoint fractional pixels
        foreach (dchar codepoint; text) {
            FT_Error error = FT_Load_Char(face, codepoint, FT_LOAD_NO_BITMAP);
            if (error != 0) {
                stderr.writeln(i"Failed to load codepoint \"$(codepoint)\"");
                continue;
            }
            width += face.glyph.advance.x;
        }
        return ceil6Fractional(width);
    }
}

alias TextHandle = TextHandleT!(DefaultTexture);
struct TextHandleT(TextureType) {
    dstring text;
    ubyte[] pixels;
    TextureType texture;

    this(uint width, uint height) {
        this.pixels = new ubyte[width * height];
        this.texture = new TextureType(width, height, GL_R8);
    }

    void setText(dstring text, Font font) {
        font.drawText(text, texture.width, texture.height, this.pixels);
        this.text = text;
        texture.uploadData(0, 0, 0, texture.width, texture.height, cast(ubyte[1][]) this.pixels);
    }

}
