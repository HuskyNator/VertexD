module vertexd.gui2.ui_element;
import vertexd.gui2.size;
import vdmath.mat;
import vertexd.core.input;

struct Bounds {
    union {
        struct {
            double[2] xBounds;
            double[2] yBounds;
        }

        struct {
            double left;
            double right;
            double top;
            double bottom;
        }
    }

    this(double left, double right, double top, double bottom) {
        this.left = left;
        this.right = right;
        this.top = top;
        this.bottom = bottom;
    }

    double width() const {
        return xBounds[1] - xBounds[0];
    }

    double height() const {
        return yBounds[1] - yBounds[0];
    }

    Vec!2 size() const {
        return Vec!2(width(), height());
    }

    bool contains(Vec!(2, double) point) const {
        return point.x >= this.left && point.x < this.right
            && point.y >= this.top && point.y < this.bottom;
    }

    bool contains(Bounds bounds) const {
        bool xOverlap = bounds.left < right && bounds.right > left;
        bool yOverlap = bounds.top < bottom && bounds.bottom > top;
        return xOverlap && yOverlap;
    }
}

abstract class UiElement {
    Bounds bounds; // absolute (pixels)
    alias this = bounds;
    float zDepth = 0;
    bool enabled = true;

    UiSize cornerRadius = pixels(0);
    Vec!4 backgroundColor = Vec!4(0, 0, 0, 0);

    protected UiElement[] children;
    abstract void updateChildBounds();

    // callbacks
    void delegate(UiElement, bool enter) mouseEnterExitCallback;
    void delegate(UiElement, InputType.MouseButton) clickCallback;
    bool mouseInside = false;

    import vertexd.core.window;

    void updateBoundsTree(Window window) {
        this.bounds.xBounds = [0, window.pixelWidth];
        this.bounds.yBounds = [0, window.pixelHeight];
        this.updateChildBounds();
    }

    final public UiElement[] getChildren() {
        return this.children;
    }
}
