module vertexd.gui.font;

import bindbc.freetype;
import bindbc.opengl : GL_R8;
import std.conv : text, to;
import std.exception : enforce;
import std.file;
import std.stdio : File, stderr;
import std.string : toStringz;
import std.typecons : Nullable;
import vdmath;
import vertexd.gui.freetype;
import vertexd.memory;
import std.uni : isWhite;

class FontException : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable nextInChain = null) {
        super(msg, file, line, nextInChain);
    }
}

struct Glyph {
    uint ftIndex; /// index in freetype
    int advance; /// 26.6 fractional pixels
    int xOffset; /// 26.6 fractional pixels
    int yOffset; /// 26.6 fractional pixels
    BindlessTexture texture;

    bool exists() {
        return texture !is null;
    }
}

class Font {
    FT_Face face;
    Glyph[dchar] glyphAtlas; // TODO: for non 1:1 mapping, use HarfBuzz
    // int bboxWidth;
    // int bboxHeight;
    int lineHeight; // 26.6 fractional pixels

    this(string path) {
        import std.stdio;

        path.writeln;
        std.file.exists(path).writeln;
        FT_Error error = FT_New_Face(_FreeTypeLib, path.toStringz, 0, &face);
        if (error != 0)
            throw new FontException(
                "Font error(" ~ error.to!string ~ "). Could not create font from path: " ~ path);
        if (!FT_IS_SCALABLE(face))
            throw new FontException(
                "Font error(" ~ error.to!string ~ "). Provided font is unsupported (not scalable): " ~ path);

        setSize(16); // sets default size & generates atlas
    }

    private Glyph loadNewGlyph(dchar codepoint) {
        FT_Error error = FT_Load_Char(face, codepoint, FT_LOAD_RENDER);
        if (error != 0) {
            stderr.writeln(i"Failed to load & render codepoint \"$(codepoint)\"");
            return Glyph(0, 0, 0, 0, null);
        }

        Glyph glyph;
        glyph.ftIndex = face.glyph.glyphIndex;
        glyph.advance = face.glyph.advance.x;
        glyph.xOffset = face.glyph.metrics.horiBearingX;
        glyph.yOffset = 0;
        int stride = face.glyph.bitmap.pitch;
        int bitmapSize = face.glyph.bitmap.rows * stride;
        if (bitmapSize > 0) {
            ubyte[1][] pixels = cast(ubyte[1][]) face.glyph.bitmap.buffer[0 .. bitmapSize];
            glyph.texture = new BindlessTexture(face.glyph.bitmap.width, face.glyph.bitmap.rows, pixels, false, stride);
            glyph.yOffset = (face.glyph.bitmap.rows << 6) - face.glyph.metrics.horiBearingY;
        }
        glyphAtlas[codepoint] = glyph;
        return glyph;
    }

    void generateDefaultAtlas() {
        glyphAtlas.clear();

        // this.bboxWidth = (face.bbox.xMax - face.bbox.xMin + 63) / 64;
        // this.bboxHeight = (face.bbox.yMax - face.bbox.yMin + 63) / 64;

        for (dchar c = ' '; c <= '~'; c += 1) { // Basic Lattin Unicode block
            glyphAtlas[c] = loadGlyph(c);
        }
    }

    ~this() {
        if (_FreeTypeLib !is null) // library still valid
            FT_Done_Face(face);
    }

    final public void setSize(uint height) { // see: https://stackoverflow.com/a/65706983
        FT_Error error = FT_Set_Pixel_Sizes(face, 0, height);
        if (error != 0)
            throw new FontException("Could not set font to pixel size");

        this.lineHeight = face.size.metrics.height;
        generateDefaultAtlas();
    }

    Glyph loadGlyph(dchar codepoint) {
        return glyphAtlas.require(codepoint, loadNewGlyph(codepoint));
    }

    /// Split text into lines.
    /// Params:
    ///   lineWidth = pixel width of layout
    ///   offset = offset to add to layout placements
    ///   lineHeight = height of lines in 26.6 fractional pixels
    /// Returns: bottom-left pixel positions of text glyphs.
    Vec!(2, int)[] layout(dstring text, int lineWidth, Vec!(2, int) offset, bool useKerning, int lineHeight = 0) {
        useKerning &= FT_HAS_KERNING(face);
        if (lineHeight == 0)
            lineHeight = this.lineHeight;

        Vec!(2, int)[] placements = new Vec!(2, int)[text.length];
        int[] cursorRecord = new int[text.length];
        int cursor = 0; // 26.6 fractional pixels
        int line = 0;
        int lastSpace = 0;
        uint lastGlyphIndex;
        bool firstOnLine = true;
        for (int i = 0; i < text.length; i++) {
            dchar c = text[i];
            Glyph glyph = this.loadGlyph(c);
            placements[i] = Vec!(2, int)(cursor + glyph.xOffset, (line + 1) * lineHeight + glyph
                    .yOffset);
            cursorRecord[i] = cursor;

            if (c == '\n') {
                line += 1;
                cursor = 0;
                lastSpace = 0;
                firstOnLine = true;
                continue;
            }

            int advance = glyph.advance;
            if (!firstOnLine && useKerning) {
                FT_Vector kerning;
                int error = FT_Get_Kerning(face, lastGlyphIndex, glyph.ftIndex, 0, &kerning);
                if (error != 0)
                    throw new FontException(
                        i"Could not load kerning of \"$(text[i - 1])$(c)\"".text);
                advance += kerning.x;
            }
            cursor += advance;
            if ((cursor >> 6) > lineWidth && !firstOnLine && !isWhite(c)) { // break
                uint linebreakIndex = (lastSpace > 0) ? lastSpace : i - 1;
                int breakStart = cursorRecord[linebreakIndex + 1];
                int breakEnd = cursor;

                for (int breakIndex = linebreakIndex + 1; breakIndex <= i; breakIndex++) {
                    placements[breakIndex].x -= breakStart;
                    placements[breakIndex].y += lineHeight;
                }

                cursor = breakEnd - breakStart;
                line += 1;
                lastSpace = 0;
                firstOnLine = true;
                continue;
            }
            firstOnLine = false;
            lastGlyphIndex = glyph.ftIndex;
            if (isWhite(c))
                lastSpace = i;
        }

        foreach (ref p; placements)
            p = (p >> 6) + offset;
        return placements;
    }

    // private float getMaxAdvancePixelWidth() {
    //     return (cast(float) face.size.metrics.maxAdvance) / (2 ^^ 6);
    // }

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

            int stride = face.glyph.bitmap.pitch;
            int bitmapSize = face.glyph.bitmap.rows * stride;

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
        this.texture = new TextureType(width, height, GL_R8, Texture.maxMipmapLevels(width, height));
    }

    void setText(dstring text, Font font) {
        font.drawText(text, texture.width, texture.height, this.pixels);
        this.text = text;
        texture.uploadData(0, 0, 0, texture.width, texture.height, cast(ubyte[1][]) this.pixels);
        texture.updateMipMap();
    }

}
