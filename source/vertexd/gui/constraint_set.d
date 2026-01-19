module vertexd.gui.constraint_set;

import std.conv : to;
import std.exception;
import vertexd.gui.bounds;
import vertexd.gui.constraints;
import vertexd.gui.value;

struct UiConstraintSet { //TODO: reconsider growable / child size dependance
    union {
        struct {
            private UiConstraint first = StartAlign(pixels(0));
            private UiConstraint second = EndAlign(pixels(0));
        }

        UiConstraint[2] constraints;
    }

    this(UiConstraint first, UiConstraint second) {
        if (first.type < second.type)
            constraints = [first, second];
        else
            constraints = [second, first];
        enforce(isValid(), "Constraint set not valid: " ~ toString());
    }

    /// Valid constraint sets:
    /// - StartAlign + EndAlign
    /// - StartAlign + Size(Grow)
    /// - StartAlign + Centered
    /// - StartGrow + EndAlign
    /// - StartGrow + SizeGrow
    /// - StartGrow + Centered
    /// - Size(Grow) + Centered
    bool isValid() const {
        final switch (first.type) {
            case CType.StartAlign:
                if (second.type == CType.EndAlign // || second.type == CType.EndGrow
                    || second.type == CType.Size // || second.type == CType.SizeGrow
                    || second.type == CType.SizeFit
                    || second.type == CType.Centered)
                    return true;
                return false;
                // case CType.StartGrow:
                //     if (second.type == CType.EndAlign
                //         || second.type == CType.EndGrow
                //         || second.type == CType.SizeGrow
                //         || second.type == CType.Centered
                //         )
                //         return true;
                //     return false;
            case CType.EndAlign:
                if (second.type == CType.Size
                    || second.type == CType.SizeFit
                    || second.type == CType.Centered)
                    return true;
                return false;
                // case CType.EndGrow:
                //     return false;
            case CType.Size, CType.SizeFit:
                if (second.type == CType.Centered)
                    return true;
                return false;
                // case CType.SizeGrow:
                //     if (second.type == CType.Centered)
                //         return true;
                //     return false;
            case CType.Centered:
                return false;
        }
    }

    const(UiValue)* getFitReferenceValue() const {
        foreach (ref constraint; constraints) {
            if (constraint.type == CType.SizeFit)
                return &constraint.uiValue;
        }
        return null;
    }

    // bool canGrow() const {
    //     foreach (constraint; constraints) {
    //         if (constraint.type == CType.StartGrow
    //             || constraint.type == CType.EndGrow
    //             || constraint.type == CType.SizeGrow)
    //             return true;
    //     }
    //     return false;
    // }

    UiBound solve(const UiBound parentBound, const double pixelToVirtual, const double fitSize) const {
        double parentSize = parentBound.size();

        // Calculate local bounds.
        UiBound localBound;
        // Simplify by converting to absolute values.
        UiConstraint first = this.first.toAbsoluteVirtual(parentSize, pixelToVirtual);
        UiConstraint second = this.second.toAbsoluteVirtual(parentSize, pixelToVirtual);
        if (first.type == CType.SizeFit)
            first = Size(pixels(fitSize));
        if (second.type == CType.SizeFit)
            second = Size(pixels(fitSize));

        // first = shrinkToAlign(parentBound, first, vertical);
        // second = shrinkToAlign(parentBound, second, vertical);

        // Handle all valid constraint sets.
        if (first.type == CType.StartAlign && second.type == CType.EndAlign) {
            localBound.min = first.value;
            localBound.max = parentSize - second.value;
        } else if (first.type == CType.StartAlign && second.type == CType.Size) {
            localBound.min = first.value;
            localBound.max = first.value + second.value;
        } else if (first.type == CType.EndAlign && second.type == CType.Size) {
            localBound.max = parentSize - first.value;
            localBound.min = localBound.max - second.value;
        } else if (first.type == CType.StartAlign && second.type == CType.Centered) {
            localBound.min = first.value;
            localBound.max = parentSize - first.value;
        } else if (first.type == CType.EndAlign && second.type == CType.Centered) {
            localBound.max = parentSize - first.value;
            localBound.min = first.value;
        } else if (first.type == CType.Size && second.type == CType.Centered) {
            localBound.min = (parentSize - first.value) / 2;
            localBound.max = localBound.min + first.value;
        } else {
            enforce(isValid(), "Constraint set not valid: " ~ toString());
            assert(0, "Constraint set not implemented: " ~ toString());
        }

        // Update bounds
        UiBound globalBound = UiBound(
            localBound.min + parentBound.min,
            localBound.max + parentBound.min);
        return globalBound;
    }

    string toString() const {
        return "ConstraintSet(" ~ first.toString() ~ ", " ~ second.toString() ~ ")";
    }
}
