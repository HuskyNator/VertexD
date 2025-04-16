module vertexd.gui.bounds;

import vdmath;

struct UiBound {
    double min;
    double max;

    double size() const {
        return max - min;
    }

    static UiBound combine(UiBound a, UiBound b) {
        UiBound result;
        result.min = (a.min <= b.min) ? a.min : b.min;
        result.max = (a.max >= b.max) ? a.max : b.max;
        return result;
    }
}

struct UiBounds {
    Vec!(2, double) topLeft;
    Vec!(2, double) bottemRight;
    alias tl = topLeft;
    alias br = bottemRight;
    alias anchor = topLeft;
    Vec!(2, double) size() const {
        return bottemRight - topLeft;
    }

    static UiBounds combine(UiBounds a, UiBounds b) {
        UiBounds maxBounds;
        maxBounds.topLeft.x = (a.tl.x <= b.tl.x) ? a.tl.x : b.tl.x;
        maxBounds.topLeft.y = (a.tl.y <= b.tl.y) ? a.tl.y : b.tl.y;
        maxBounds.bottemRight.x = (a.br.x >= b.br.x) ? a.br.x : b.br.x;
        maxBounds.bottemRight.y = (a.br.y >= b.br.y) ? a.br.y : b.br.y;
        return maxBounds;
    }
}
