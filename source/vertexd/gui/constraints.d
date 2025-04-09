module vertexd.gui.constraints;

alias StartAlign = UiConstraint.StartAlign;
alias EndAlign = UiConstraint.EndAlign;
alias Size = UiConstraint.Size;
alias Centered = UiConstraint.Centered;

struct UiConstraint {
    // Type enum is ordered to simplify constraint set evaluation.
    enum Type : ubyte {
        StartAlign,
        EndAlign,
        Size,
        Centered
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
}
