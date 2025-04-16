module vertexd.gui.constraints;

import vertexd.gui.bounds;
import std.conv : to;

alias StartAlign = UiConstraint.StartAlign;
// alias StartShrink = UiConstraint.StartShrink;
alias EndAlign = UiConstraint.EndAlign;
// alias EndShrink = UiConstraint.EndShrink;
alias Size = UiConstraint.Size;
alias Centered = UiConstraint.Centered;

alias CType = UiConstraint.Type;

struct UiConstraint {
    // Type enum is ordered to simplify constraint set evaluation.
    enum Type : ubyte {
        StartAlign,
        // StartGrow, // shrink with minimum size as align
        EndAlign,
        // EndGrow,
        Size,
        // SizeGrow,
        Centered // with offset
    }

    Type type;
    double value;
    bool relative; // % vs px

    // Simplified Constructors
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

    string toString() const {
        return type.to!string ~ "(" ~ value.to!string ~ "," ~ (relative ? "true"
                : "false") ~ ")";
    }

}
