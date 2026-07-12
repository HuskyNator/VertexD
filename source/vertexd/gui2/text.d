module vertexd.gui2.text;

import std.math.rounding : floor;
import vdmath;
import vertexd.gui.font;
import vertexd.gui2;

class TextBox : UiElement {
    dstring text;
    Font font;
    bool useKerning;
    Vec!(2, int) offset;
    Vec!(2, int) scroll;
    bool scrollable;

    Vec!(2, int)[] layout;
    Vec!(2, int) layoutSize;
    // TODO : text direction
    // TODO: wrapping types

    this(dstring text, Font font, bool scrollable = true, bool useKerning = true, Vec!(2, int) offset = Vec!(2, int)(8, 0)) {
        this.text = text;
        this.font = font;
        this.scrollable = scrollable;
        this.useKerning = useKerning;
        this.layout = [];
        this.offset = offset;
        foreach (c; text)
            font.loadGlyph(c);
    }

    override void updateChildBounds() {
        Vec!(2, int) textStart = Vec!(2, int)(cast(int) floor(this.bounds.left),
            cast(int) floor(this.bounds.top))
            + this.offset;
        if (this.scrollable)
            textStart += this.scroll;
        this.layout =
            this.font.layout(this.text, cast(int) this.bounds.width(), textStart, this.useKerning);
        this.layoutSize = layout[$ - 1] - this.offset;
        if (this.scrollable)
            this.layoutSize - this.scroll;
    }
}
