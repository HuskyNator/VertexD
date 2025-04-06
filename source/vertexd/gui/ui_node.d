module vertexd.gui.ui_node;

import vertexd.core.window;
import vdmath;

struct UiBound {
    Vec!(2, double) topLeft;
    Vec!(2, double) bottemRight;
    alias tl = topLeft;
    alias br = bottemRight;

    alias anchor = topLeft;
    Vec!(2, double) size() const {
        return bottemRight - topLeft;
    }
}

struct UiConstraint {
    Type type;
    double value;
    bool relative; // % vs px

    // Type enum is ordered to simplify constraint set evaluation.
    enum Type : ubyte {
        StartAlign,
        EndAlign,
        Size,
        Centered
    }

    static foreach (T; __traits(allMembers, UiConstraint.Type)) {
        mixin("static UiConstraint ", T, "(double value=0,bool relative=true)
        {return UiConstraint(UiConstraint.Type.", T, ",value,relative);}");
    }

    UiConstraint toAbsoluteVirtual(double parentSize, double pixelToVirtual) const {
        UiConstraint absolute;
        absolute.type = this.type;
        absolute.value = (relative ? this.value * parentSize : this.value * pixelToVirtual);
        absolute.relative = false;
        return absolute;
    }
}

class UiNode {
    UiNode[] children;
    UiBound globalBound;
    UiBound localBound;
    float zDepth = 0;

    // Valid constraint sets:
    // alignL + alignR
    // align + size
    // align + center
    // size + center

    UiConstraint[2] xConstraints = [
        UiConstraint.StartAlign(0),
        UiConstraint.EndAlign(0)
    ];
    UiConstraint[2] yConstraints = [
        UiConstraint.StartAlign(0),
        UiConstraint.EndAlign(0)
    ];

    void sortConstraints() {
        if (xConstraints[0].type > xConstraints[1].type) {
            UiConstraint temp = xConstraints[0];
            xConstraints[0] = xConstraints[1];
            xConstraints[1] = temp;
        }
        if (yConstraints[0].type > yConstraints[1].type) {
            UiConstraint temp = yConstraints[0];
            yConstraints[0] = yConstraints[1];
            yConstraints[1] = temp;
        }
    }

    void updateBounds(UiBound parentBound, const double pixelToVirtual) {
        alias CType = UiConstraint.Type;
        Vec!(2, double) parentSize = parentBound.size();
        sortConstraints();

        // Calculate new local bounds.
        UiBound newLocalBound;
        UiConstraint first, second;
        static foreach (bool vertical; [false, true]) {
            // Simplify by converting to absolute values.
            first = vertical ? yConstraints[0] : xConstraints[0];
            second = vertical ? yConstraints[1] : xConstraints[1];
            first = first.toAbsoluteVirtual(parentSize[vertical], pixelToVirtual);
            second = second.toAbsoluteVirtual(parentSize[vertical], pixelToVirtual);

            // Handle all valid constraint sets.
            if (first.type == CType.StartAlign && second.type == CType.EndAlign) {
                newLocalBound.topLeft[vertical] = first.value;
                newLocalBound.bottemRight[vertical] = parentSize[vertical] - second.value;
                newLocalBound.bottemRight[vertical] = parentSize[vertical] - second.value;
            } else if (first.type == CType.StartAlign && second.type == CType.Size) {
                newLocalBound.topLeft[vertical] = first.value;
                newLocalBound.bottemRight[vertical] = first.value + second.value;
            } else if (first.type == CType.EndAlign && second.type == CType.Size) {
                newLocalBound.bottemRight[vertical] = parentSize[vertical] - first.value;
                newLocalBound.topLeft[vertical] = newLocalBound.bottemRight[vertical] - second
                    .value;
            } else if (first.type == CType.StartAlign && second.type == CType.Centered) {
                newLocalBound.topLeft[vertical] = first.value;
                newLocalBound.bottemRight[vertical] = parentSize[vertical] - first.value;
            } else if (first.type == CType.EndAlign && second.type == CType.Centered) {
                newLocalBound.bottemRight[vertical] = parentSize[vertical] - first.value;
                newLocalBound.topLeft[vertical] = first.value;
            } else if (first.type == CType.Size && second.type == CType.Centered) {
                newLocalBound.topLeft[vertical] = (parentSize[vertical] - first.value) / 2;
                newLocalBound.bottemRight[vertical] = newLocalBound.topLeft[vertical] + first.value;
            } else
                assert(0, "Invalid constraint set.");
        }

        // Update bounds
        UiBound newGlobalBound = UiBound(
            newLocalBound.topLeft + parentBound.topLeft,
            newLocalBound.bottemRight + parentBound.topLeft);
        this.localBound = newLocalBound;
        this.globalBound = newGlobalBound;
    }

    void updateBoundsTree(UiBound parentBound, const double pixelToVirtual) {
        updateBounds(parentBound, pixelToVirtual);
        foreach (child; children)
            child.updateBoundsTree(this.globalBound, pixelToVirtual);
    }

    void updateBoundsTree(Window window) {
        UiBound windowBounds = UiBound(
            cast(Vec!(2, double))(window.windowPosition),
            cast(Vec!(2, double))(window.windowPosition + window.size));

        double pixelToVirtual = window.width / window.pixelWidth;
        updateBoundsTree(windowBounds, pixelToVirtual);
    }

    bool isMouseOver(Window window) {
        Vec!(2, double) mousePos = window.mousePosition;
        return mousePos.x >= globalBound.tl.x && mousePos.x <= globalBound.br.x
            && mousePos.y >= globalBound.tl.y && mousePos.y <= globalBound.br.y;
    }
}
