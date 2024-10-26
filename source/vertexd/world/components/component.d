module vertexd.world.components.component;

public import vertexd.world.node;

interface Component {
    void update(Node owner);
    void postUpdate(Node owner);
}
