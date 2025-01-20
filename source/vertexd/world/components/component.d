module vertexd.world.components.component;

public import vertexd.world.node;

abstract class Component {
    void physicsUpdate() {
    }

    //TODO: Create way of ensuring component has certain number of callers/owners.
    void update(Node caller) {
    }

    void postUpdate(Node caller) {
    }
}
