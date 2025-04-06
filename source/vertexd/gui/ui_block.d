module vertexd.gui.ui_block;

import vertexd.gui.ui_node;
import vdmath;
import vertexd.memory.buffer;

class UiBlock : UiNode {
    Vec!4 color; // todo: color/texture
    float radius = 0;
    bool radiusRelative; // % vs px (% of half of smallest side; 100% = 1.0 = max radius)

    this(float[4] color, float radius, bool radiusRelative) {
        this.color = color;
        this.radius = radius;
        this.radiusRelative = radiusRelative;
    }
}
