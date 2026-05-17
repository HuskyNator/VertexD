module vertexd.gui2.ui_element;
import vertexd.gui2.size;
import vdmath.mat;

struct Bounds {
    double[2] xBounds;
    double[2] yBounds;

    double width() const {
        return xBounds[1] - xBounds[0];
    }

    double height() const {
        return yBounds[1] - yBounds[0];
    }
}

abstract class UiElement {
    Bounds bounds; // absolute (pixels)
    float zDepth = 0;

    UiSize cornerRadius = pixels(0);
    Vec!4 backgroundColor = Vec!4(0, 0, 0, 0);

    UiElement[] children;
    abstract void updateChildBounds();

    const final {
        double width() {
            return this.bounds.width();
        }

        double height() {
            return this.bounds.height();
        }

        double left() {
            return this.bounds.xBounds[0];
        }

        double right() {
            return this.bounds.xBounds[1];
        }

        double top() {
            return this.bounds.yBounds[0];
        }

        double bottom() {
            return this.bounds.yBounds[1];
        }
    }
}
