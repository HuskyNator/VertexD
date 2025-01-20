module vertexd.world.transform;

import vdmath;

struct Transform { // TODO: AOS
    Vec!3 position = Vec!3(0);
    Vec!3 size = Vec!3(1);
    Quat rotation = Quat();
}
