module vertexd.gui2.ui_element;
import vertexd.gui2.size;
import vdmath.mat;

struct Bounds {
    union {
        struct {
            double[2] xBounds;
            double[2] yBounds;
        }

        double left, right, top, bottom;
    }

    this(double left, right, top, bottom) {
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
}

abstract class UiElement {
    Bounds bounds; // absolute (pixels)
    alias this = bounds;
    float zDepth = 0;

    UiSize cornerRadius = pixels(0);
    Vec!4 backgroundColor = Vec!4(0, 0, 0, 0);

    protected UiElement[] children;
    abstract void updateChildBounds();

    final public const(UiElement[]) getChildren() const {
        return this.children;
    }

}
