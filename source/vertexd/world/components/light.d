module vertexd.world.components.light;

import vertexd.world.components.component;
import vertexd.core.ids;
import vdmath;
import vertexd.renderer.renderable;

class Light : Component {
    mixin ID;
    Vec!3 worldPosition;

    override void update(Node owner) {
    }

    override void postUpdate(Node owner) {
        worldPosition = owner.worldPosition();
    }
}
