module vertexd.gui.canvas;

import std.math.algebraic : sqrt;

import vertexd.world.node;
import vertexd.world.components.component;
import vertexd.core.window;
import vertexd.core.time;
import vertexd.gui.ui_node;
import vdmath;

/// Canvas for in-world ui
deprecated("Not yet implemented") class Canvas : Component {
    UiNode ui;

    // Window window = null;
    Vec!(2, double) size;
    bool constantScale;

    // this(UiNode ui, Window window) {
    //     this.ui = ui;
    //     this.window = window;
    // }

    this(UiNode ui, Vec!(2, double) size, bool constantScale) {
        this.ui = ui;
        this.size = size;
        this.constantScale = constantScale;
    }

    override void postUpdate(Node caller) {
        if (caller.lastUpdateFrame == Time.frameID()) {
            Vec!(2, double) size = this.size;
            if (!constantScale) {
                size *= sqrt(
                    caller.modelMatrix[0][0] ^^ 2
                        + caller.modelMatrix[1][1] ^^ 2
                        + caller.modelMatrix[2][2] ^^ 2);
            }
        }
        // if (window is null) {}
        // if (caller.lastUpdateFrame == Time.frameID()
        //     || window.lastPositionSizeUpdateFrame == Time.frameID()) {
        //     UiBound windowBound = UiBound(window.windowPosition,
        //         window.windowPosition + window.bounds__);
        //     ui.updateBoundsTree(windowBound);
        // }
    }
}
