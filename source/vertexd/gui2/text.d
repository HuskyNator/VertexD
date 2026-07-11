module vertexd.gui2.text;

import std.math.rounding : floor;
import vdmath;
import vertexd.gui.font;
import vertexd.gui2;

class Text : UiElement {
    dstring text;
    Font font;
    bool useKerning;
    Vec!(2, int)[] placements;

    this(dstring text, Font font, bool useKerning = true) {
        this.text = text;
        this.font = font;
        this.useKerning = useKerning;
        this.placements = [];
        foreach (c; text)
            font.loadGlyph(c);
    }

    override void updateChildBounds() {
        Vec!(2, int) topLeft = cast(Vec!(2, int)) Vec!2(floor(this.bounds.left), floor(
                this.bounds.top));
        Vec!(2, int) textStart = topLeft + Vec!(2, int)(5, 0);
        this.placements = this.font.layout(this.text, cast(int) this.bounds.width(), textStart, this
                .useKerning);
    }
}
