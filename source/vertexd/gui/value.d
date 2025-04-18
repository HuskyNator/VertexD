module vertexd.gui.value;

UiValue pixels(double value) {
    return UiValue(value, false);
}

UiValue percent(double value) {
    return UiValue(value, true);
}

struct UiValue {
    double value = 0;
    bool relative; // % vs px

    UiValue toAbsoluteVirtual(double parentSize, const double pixelToVirtual) const {
        UiValue absolute;
        absolute.value = (relative ? this.value * parentSize : this.value * pixelToVirtual);
        absolute.relative = false;
        return absolute;
    }
}
