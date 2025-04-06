module vertexd.renderer.simple.render_queue;

import std.algorithm.sorting : sortArray = sort;
import vdmath;
import vertexd.core.window;
import vertexd.mesh.mesh;
import vertexd.world.node;

struct RenderQueue {
    struct Element {
        Node owner;
        Mesh mesh;
        ulong hash;

        this(Node owner, Mesh mesh) {
            this.owner = owner;
            this.mesh = mesh;
            this.hash = (cast(ulong) mesh.material.shader.shaderProgram) << 32 | mesh.material.id;
        }

        static bool less(Element a, Element b) {
            return a.hash < b.hash;
        }
    }

    Element[] queue;
    alias this = queue;

    void enqueue(Node owner, Mesh mesh) {
        queue ~= Element(owner, mesh);
    }

    void sort() {
        sortArray!(Element.less)(queue);
    }
}
