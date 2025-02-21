module vertexd.world.components.light;

import vertexd.world.components.component;
import vertexd.util.ids;
import vdmath;

class Light : Component {
    mixin ID;
    Vec!3 worldPosition;

    this() {
        setID();
    }

    override void update(Node caller) {
    }

    override void postUpdate(Node caller) {
        worldPosition = caller.worldPosition();
    }
}
