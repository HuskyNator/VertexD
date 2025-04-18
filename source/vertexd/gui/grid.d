module vertexd.gui.grid;

import vdmath;
import vertexd.gui.bounds;
import vertexd.gui.node;
import vertexd.gui.value;

class Grid : UiNode {
    size_t rows;
    size_t columns;
    UiNode[] elements;
    size_t elementCount = 0;
    double[4] padding;
    double[2] gap;

    this(size_t rows, size_t columns) {
        this.rows = rows;
        this.columns = columns;
        elements = new UiNode[](rows * columns);
    }

    void addElement(UiNode element, size_t row, size_t column) {
        assert(element !is null);
        assert(this[row, column] is null);
        this[row, column] = element;
        this.elementCount += 1;
    }

    bool removeElement(UiNode element) {
        foreach (ref UiNode elementI; elements)
            if (elementI == element) {
                elementI = null;
                this.elementCount -= 1;
                return true;
            }
        return false;
    }

    UiNode removeElement(size_t row, size_t column) {
        UiNode element = this[row, column];
        if (element !is null)
            this.elementCount -= 1;
        this[row, column] = null;
        return element;
    }

    UiNode getElement(size_t row, size_t column) {
        return this[row, column];
    }

    private ref auto opIndex(size_t indexRow, size_t indexColumn) {
        return elements[indexRow * columns + indexColumn];
    }

    UiBounds firstElementBounds() const {
        UiBounds elementBound;
        elementBound.topLeft = this.boundsInsidePadding.topLeft;
        Vec!(2, double) size = this.boundsInsidePadding.size();
        size.x /= columns;
        size.y /= rows;
        elementBound.bottemRight = elementBound.topLeft + size;
        return elementBound;
    }

    override void updateBounds(const UiBounds parentBounds, const double pixelToValue) {
        super.updateBounds(parentBounds, pixelToValue);
        UiBounds firstBound = firstElementBounds();
        Vec!(2, double) size = firstBound.size();
        foreach (y; 0 .. rows) {
            foreach (x; 0 .. columns) {
                UiNode element = opIndex(y, x);
                if (element is null)
                    continue;
                UiBounds elementBounds = firstBound.shift(size.x * x, size.y * y);
                element.updateBounds(elementBounds, pixelToValue);
            }
        }
    }

    override UiNode[] getContent() {
        return elements;
    }

    void compressRows() {
        size_t newRows = elementCount / columns + 1;
        UiNode[] compressedElements = new UiNode[newRows * columns];
        size_t i = 0;
        foreach (UiNode element; elements) {
            if (element !is null) {
                compressedElements[i] = element;
                i += 1;
            }
        }
        this.elements = compressedElements;
        this.rows = newRows;
    }

    // override void updateBoundsTree(const UiBounds parentBounds, const double pixelToVirtual) {
    //     updateBounds(parentBounds, pixelToVirtual);
    //     UiBounds contentBounds = getContentBounds();
    //     Vec!(2, double) size = contentBounds.size();
    //     assert(children.length <= rows * columns);
    //     foreach (x; 0 .. columns) {
    //         foreach (y; 0 .. rows) {

    //         }
    //     }
    // }
}
