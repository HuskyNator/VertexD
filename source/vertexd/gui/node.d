module vertexd.gui.node;

import vertexd.core.window;
import vdmath;
import vertexd.gui.constraints;
import vertexd.memory.texture;
import vertexd.gui.bounds;
import vertexd.gui.constraint_set;
import vertexd.gui.value;

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
    UiBounds boundsInsidePadding;
    float zDepth = 0;
    bool applyScissorTest = true;

    UiConstraintSet xConstraints;
    UiConstraintSet yConstraints;
    UiValue radius;
    UiNodeStyle style;
    bool renderNodeStyle = false;

    UiValue[4] padding;
    void setPadding(UiValue padding) {
        this.padding[] = padding;
    }

    double[4] paddingToAbsVirtual(const Vec!(2, double) parentSize, const double pixelToVirtual) const {
        double[4] pixelPadding;
        pixelPadding[0] = padding[0].toAbsoluteVirtual(parentSize.y, pixelToVirtual).value;
        pixelPadding[1] = padding[1].toAbsoluteVirtual(parentSize.x, pixelToVirtual).value;
        pixelPadding[2] = padding[2].toAbsoluteVirtual(parentSize.y, pixelToVirtual).value;
        pixelPadding[3] = padding[3].toAbsoluteVirtual(parentSize.x, pixelToVirtual).value;
        return pixelPadding;
    }

    static UiBounds joinPadding(UiBounds original, const double[4] padding) {
        original.topLeft = original.topLeft - Vec!(2, double)(padding[3], padding[0]);
        original.bottemRight = original.bottemRight + Vec!(2, double)(padding[1], padding[2]);
        return original;
    }

    static UiBounds subtractPadding(UiBounds original, const double[4] padding) {
        original.topLeft = original.topLeft + Vec!(2, double)(padding[3], padding[0]);
        original.bottemRight = original.bottemRight - Vec!(2, double)(padding[1], padding[2]);
        return original;
    }

    this() {
    }

    void setRadius(UiValue radius) {
        this.radius = radius;
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

    void updateBounds(const UiBounds parentBounds, const double pixelToVirtual) {
        UiBound xBound = UiBound(parentBounds.topLeft.x, parentBounds.bottemRight.x);
        UiBound yBound = UiBound(parentBounds.topLeft.y, parentBounds.bottemRight.y);
        Vec!(2, double) parentSize = parentBounds.size();

        Vec!(2, double) referenceFitSize = bounds.size;
        const(UiValue)* xRefSize = xConstraints.getFitReferenceValue();
        const(UiValue)* yRefSize = yConstraints.getFitReferenceValue();
        if (xRefSize !is null)
            referenceFitSize.x = xRefSize.toAbsoluteVirtual(parentSize.x, pixelToVirtual).value;
        if (yRefSize !is null)
            referenceFitSize.y = yRefSize.toAbsoluteVirtual(parentSize.y, pixelToVirtual).value;

        double[4] paddingAbsVirtual = paddingToAbsVirtual(parentSize, pixelToVirtual);
        Vec!(2, double) paddingSize = Vec!(2, double)(paddingAbsVirtual[1] + paddingAbsVirtual[3], paddingAbsVirtual[0] + paddingAbsVirtual[2]);
        referenceFitSize -= paddingSize;
        Vec!(2, double) fitSize = getFitSize(referenceFitSize, pixelToVirtual) + paddingSize;

        UiBound xSolved = xConstraints.solve(xBound, pixelToVirtual, fitSize.x);
        UiBound ySolved = yConstraints.solve(yBound, pixelToVirtual, fitSize.y);
        this.bounds.topLeft = Vec!(2, double)(xSolved.min, ySolved.min);
        this.bounds.bottemRight = Vec!(2, double)(xSolved.max, ySolved.max);
        this.boundsInsidePadding = subtractPadding(this.bounds, paddingAbsVirtual);
    }

    /// Return current combined children bounds
    UiBounds getChildrenBounds() const {
        if (children.length == 0)
            return UiBounds();
        UiBounds combinedBounds = children[0].bounds;
        foreach (child; children[1 .. $])
            combinedBounds = UiBounds.combine(combinedBounds, child.bounds);
        return combinedBounds;
    }

    Vec!(2, double) getFitSize(const Vec!(2, double) referenceFitSize, const double pixelToVirtual) const {
        return getChildrenBounds().size();
    }

    UiBounds getChildrenTargetBounds() const {
        return this.boundsInsidePadding;
    }

    /// Additional content to render
    UiNode[] getContent() {
        return [];
    }

    void updateBoundsTree(const UiBounds parentBounds, const double pixelToVirtual) {
        updateBounds(parentBounds, pixelToVirtual);
        UiBounds contentBounds = getChildrenTargetBounds();
        foreach (child; children)
            child.updateBoundsTree(contentBounds, pixelToVirtual);

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
