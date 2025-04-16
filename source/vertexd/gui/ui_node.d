module vertexd.gui.ui_node;

import vertexd.core.window;
import vdmath;
import vertexd.gui.constraints;
import vertexd.memory.texture;
import vertexd.gui.bounds;
import vertexd.gui.constraint_set;

struct UiNodeStyle {
    Vec!4 color = Vec!4(0, 0, 0, 0);
    Texture texture;

    this(float[4] color, Texture texture = Texture.empty(Texture.Type.RGBA)) {
        this.color = Vec!4(color);
        this.texture = texture;
    }
}

class UiNode {
    UiNode[] children;
    UiBounds bounds;
    float zDepth = 0;
    bool applyScissorTest = true;

    UiConstraintSet xConstraints;
    UiConstraintSet yConstraints;

    float radius = 0;
    bool radiusRelative; // % vs px (% of half of smallest side; 100% = 1.0 = max radius)

    UiNodeStyle style;
    bool renderNodeStyle = false;

    this(float radius, bool radiusRelative, float zDepth) {
        this.radius = radius;
        this.radiusRelative = radiusRelative;
        this.zDepth = zDepth;
    }

    void setStyle(UiNodeStyle style) {
        assert(style.texture !is null);
        this.style = style;
        this.renderNodeStyle = true;
    }

    void setStyle(float[4] color, Texture texture = Texture.empty(Texture.Type.RGBA)) {
        this.style.color = Vec!4(color);
        this.style.texture = texture;
        this.renderNodeStyle = true;
    }

    void clearStyle() {
        this.style.color = Vec!4(0, 0, 0, 0);
        this.style.texture = null;
        this.renderNodeStyle = false;
    }

    // private alias CType = UiConstraint.Type;
    // UiConstraint shrinkToAlign(UiBound parentBound, UiConstraint constraint, bool vertical) {
    //     UiConstraint nonShrink = constraint;
    //     if (constraint.type == CType.StartShrink) {
    //         nonShrink.type = CType.StartAlign;
    //         this._startShrink[vertical] = true;
    //     } else if (constraint.type == CType.EndShrink) {
    //         nonShrink.type = CType.EndAlign;
    //         this._endShrink[vertical] = true;
    //     }
    //     return nonShrink;
    // }
    // void applyShrink(UiBound parentBound, UiBound childrenBound) {
    //     static foreach (bool vertical; [false, true]) {
    //         if (_startShrink[vertical]) {
    //             if (clampParent && childrenBound.tl[vertical] < parentBound.tl[vertical])
    //                 globalBound.tl[vertical] = parentBound.tl[vertical];
    //             else
    //                 globalBound.tl[vertical] = childrenBound.tl[vertical];
    //         }
    //         if (_endShrink[vertical]) {
    //             if (clampParent && childrenBound.br[vertical] > parentBound.br[vertical])
    //                 globalBound.br[vertical] = parentBound.br[vertical];
    //             else
    //                 globalBound.br[vertical] = childrenBound.br[vertical];
    //         }
    //     }
    // }

    void updateBounds(const UiBounds parentBounds, const double pixelToValue) {
        UiBound xBound = UiBound(parentBounds.topLeft.x, parentBounds.bottemRight.x);
        UiBound yBound = UiBound(parentBounds.topLeft.y, parentBounds.bottemRight.y);
        UiBound xSolved = xConstraints.solve(xBound, pixelToValue);
        UiBound ySolved = yConstraints.solve(yBound, pixelToValue);
        bounds.topLeft = Vec!(2, double)(xSolved.min, ySolved.min);
        bounds.bottemRight = Vec!(2, double)(xSolved.max, ySolved.max);
    }

    void updateBoundsTree(const UiBounds parentBounds, const double pixelToVirtual) {
        updateBounds(parentBounds, pixelToVirtual);
        foreach (child; children)
            child.updateBoundsTree(this.bounds, pixelToVirtual);

        // if (children.length > 0) {
        //     UiBounds fullBounds = this.globalBounds; // minimum bounds
        //     foreach (child; children)
        //         fullBounds = UiBounds.combine(fullBounds, child.globalBounds);
        // applyShrink(parentBounds, fullBounds);
        // }
    }

    void updateBoundsTree(const Window window) {
        UiBounds windowBounds = UiBounds(
            cast(Vec!(2, double))(window.windowPosition),
            cast(Vec!(2, double))(window.windowPosition + window.size));

        double pixelToVirtual = window.width / window.pixelWidth;
        updateBoundsTree(windowBounds, pixelToVirtual);
    }

    bool isMouseOver(const Window window) const {
        Vec!(2, double) mousePos = window.mousePosition;
        return mousePos.x >= bounds.tl.x && mousePos.x <= bounds.br.x
            && mousePos.y >= bounds.tl.y && mousePos.y <= bounds.br.y;
    }
}
