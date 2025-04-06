module vertexd.gui.text;

import std.exception : enforce;
import std.file;
import std.stdio : File, stderr;
import std.string : toStringz;

import bindbc.freetype;
import vertexd.gui.freetype;
import vertexd.memory.texture;

class FontException : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable nextInChain = null) {
        super(msg, file, line, nextInChain);
    }
}

class Font {
    FT_Face face;
    float maxGlyphWidth; // pixels
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

    void setSize(float height, uint dpi = 96) {
        uint fontHeight = cast(uint)(height * 64);
        FT_Error error = FT_Set_Char_Size(face, fontHeight, fontHeight, dpi, dpi);
        if (error != 0)
            throw new FontException("Could not set font to pixel size");

        this.maxGlyphWidth = getMaxGlyphPixelWidth();
        this.lineHeight = getLinePixelHeight();
    }

    private float getMaxGlyphPixelWidth() {
        return (cast(float)(cast(ulong) face.size.metrics.maxAdvance) * (
                cast(ulong) face.size.metrics.xScale))
            / (2 ^^ 26);
    }

    private float getLinePixelHeight() {
        return (cast(float)(cast(ulong) face.height) * (cast(ulong) face.size.metrics.yScale))
            / (2 ^^ 26);
    }

    private static int roundToPixelGrid(uint posFrac) {
        assert(posFrac <= uint.max - 32u);
        return cast(int)((posFrac + 32u) >> 6);
    }

    /// Params:
    ///   text = text to render
    ///   width = width of canvas (in units of maxGlyphWidth)
    ///   height = height of canvas (in units of lineHeight)
    /// Returns: Texture with rendered text
    Texture drawText(dstring text, uint width, uint height) {
        const uint xPosStart = cast(uint)((face.bbox.xMin < 0) ? -face.bbox.xMin : 0);
        const uint yPosStart = cast(uint)(
            (face.size.metrics.ascender * face.size.metrics.yScale) >> 22);

        uint xPos = xPosStart; // in 1/64th of pixel
        uint yPos = yPosStart; // in 1/64th of pixel

        ubyte[] pixels = new ubyte[width * height];

        foreach (dchar codepoint; text) {
            FT_Error error = FT_Load_Char(face, codepoint, FT_LOAD_RENDER);
            if (error != 0) {
                stderr.writeln(i"Failed to load & render codepoint \"$(codepoint)\"");
                continue;
            }

            // Draw to pixel buffer
            int xPosGrid = roundToPixelGrid(xPos) + face.glyph.bitmapLeft;
            int yPosGrid = roundToPixelGrid(yPos) + face.glyph.bitmapTop;
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

        return new Texture(width, height, cast(ubyte[1][]) pixels, false);
    }
}
