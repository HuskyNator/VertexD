module vertexd.gui.constraints;

import vertexd.gui.bounds;
import vertexd.gui.value;
import std.conv : to;

alias CType = UiConstraint.Type;
alias StartAlign = UiConstraint.StartAlign;
alias EndAlign = UiConstraint.EndAlign;
alias Size = UiConstraint.Size;
alias SizeFit = UiConstraint.SizeFit;
alias Centered = UiConstraint.Centered;
// alias StartShrink = UiConstraint.StartShrink;
// alias EndShrink = UiConstraint.EndShrink;

// TODO: Design better constraint system to support eg. aspectRatios (vertical:horizontal), alongside minimum/maximum sizes?
struct UiConstraint {
    // Type enum is ordered to simplify constraint set evaluation.
    enum Type : ubyte {
        StartAlign,
        EndAlign,
        Size,
        SizeFit, // with reference size
        Centered // with offset
        // StartGrow, // shrink with minimum size as align
        // EndGrow,
        // SizeGrow,
    }

    Type type;
    UiValue uiValue;

    private alias this = uiValue;

    // Simplified Constructors
    static foreach (T; __traits(allMembers, UiConstraint.Type)) {
        mixin("static UiConstraint ", T, "(UiValue value=pixels(0))
        {return UiConstraint(UiConstraint.Type.", T, ",value);}");
        mixin("static UiConstraint ", T, "(Args...)(Args args)
        {return UiConstraint(UiConstraint.Type.", T, ",UiValue(args));}");
    }

    UiConstraint toAbsoluteVirtual(double parentSize, double pixelToVirtual) const {
        UiConstraint absolute = this;
        absolute.uiValue = absolute.uiValue.toAbsoluteVirtual(parentSize, pixelToVirtual);
        return absolute;
    }

    string toString() const {
        return type.to!string ~ "(" ~ value.to!string ~ "," ~ (relative ? "true" : "false") ~ ")";
    }

}
