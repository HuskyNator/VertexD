module vertexd.gui.ui_block;

import vertexd.gui.ui_node;
import vdmath;
import vertexd.memory.buffer;
import vertexd.memory.texture;

class UiBlock : UiNode {
    Vec!4 color = Vec!4(0, 0, 0, 0);
    Texture texture;

    float radius = 0;
    bool radiusRelative; // % vs px (% of half of smallest side; 100% = 1.0 = max radius)

    this(float[4] color, float radius, bool radiusRelative, Texture texture = Texture.empty(
            Texture.Type.RGBA)) {
        this.color = color;
        this.texture = texture;
        this.radius = radius;
        this.radiusRelative = radiusRelative;
    }
}
