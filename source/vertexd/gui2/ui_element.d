module vertexd.gui2.ui_element;
import vertexd.gui2.size;
import vdmath.mat;

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
}

abstract class UiElement {
    Bounds bounds; // absolute (pixels)
    alias this = bounds;
    float zDepth = 0;

    UiSize cornerRadius = pixels(0);
    Vec!4 backgroundColor = Vec!4(0, 0, 0, 0);

    protected UiElement[] children;
    abstract void updateChildBounds();

    import vertexd.core.window;

    void updateBoundsTree(Window window) {
        this.bounds.xBounds = [0, window.pixelWidth];
        this.bounds.yBounds = [0, window.pixelHeight];
        this.updateChildBounds();
    }

    final public const(UiElement[]) getChildren() const {
        return this.children;
    }

}
