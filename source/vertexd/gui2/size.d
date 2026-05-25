module vertexd.gui2.size;

UiSize pixels(double value) {
    return UiSize(value, false);
}

UiSize fraction(double value) {
    return UiSize(value, true);
}

struct UiSize {
    double value = 0;
    bool relative; // fraction vs pixel

    this(double value, bool relative = false) {
        this.value = value;
        this.relative = relative;
    }

    double getAbsolute(double parentSizeAbs) const {
        if (this.relative)
            return this.value * parentSizeAbs;
        else
            return this.value;
    }
}
