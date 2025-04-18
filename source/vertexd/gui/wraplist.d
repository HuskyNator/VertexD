module vertexd.gui.wraplist;

import std.stdio : stderr;

import vdmath;
import vertexd.gui.bounds;
import vertexd.gui.node;
import vertexd.gui.value;
import vertexd.util.misc : removeElement;

class WrapList : UiNode {
    UiNode[] elements;
    UiValue elementWidth;
    UiValue elementHeight;
    UiValue[2] gap; // between elements
    bool xCentered = false; // automatic gap
    bool yCentered = false;

    this(UiValue width, UiValue height) {
        this.elementWidth = width;
        this.elementHeight = height;
        this.elements = [];
    }

    void setGap(UiValue gap) {
        this.gap[] = gap;
    }

    void add(UiNode element) {
        this.elements ~= element;
    }

    void remove(UiNode element) {
        this.elements.removeElement(element);
    }

    override Vec!(2, double) getFitSize(const Vec!(2, double) referenceFitSize, const double pixelToVirtual) const {
        double[2] pixelGap = gapToAbsVirtual(referenceFitSize, pixelToVirtual);

        double width = elementWidth.toAbsoluteVirtual(referenceFitSize.x, pixelToVirtual).value;
        double height = elementHeight.toAbsoluteVirtual(referenceFitSize.y, pixelToVirtual).value;

        uint columnCount = calcColumnCount(referenceFitSize.x, width, pixelGap);
        uint rowCount = calcRowCount(columnCount);
        double fitWidth = columnCount * width;
        if (columnCount > 0)
            fitWidth += (columnCount - 1) * pixelGap[0];
        double fitHeight = rowCount * height;
        if (rowCount > 0)
            fitWidth += (rowCount - 1) * pixelGap[1];
        return Vec!(2, double)(fitWidth, fitHeight);
    }

    double[2] gapToAbsVirtual(const Vec!(2, double) parentSize, const double pixelToVirtual) const {
        double first = gap[0].toAbsoluteVirtual(parentSize.x, pixelToVirtual).value;
        double second = gap[1].toAbsoluteVirtual(parentSize.y, pixelToVirtual).value;
        return [first, second];
    }

    uint calcColumnCount(double parentWidth, double width, double[2] pixelGap) const {
        if (parentWidth < width) {
            stderr.writeln("Element does not fit parent width");
            return 1u;
        } else if (parentWidth < 2 * width + pixelGap[0])
            return 1;
        uint columns = cast(uint)((parentWidth + pixelGap[0]) / (width + pixelGap[0]));
        if (columns > elements.length)
            return cast(uint) elements.length;
        return columns;
    }

    uint calcRowCount(uint columns) const {
        return cast(uint)((elements.length + columns - 1) / columns);
    }

    override void updateBounds(const UiBounds parentBounds, const double pixelToVirtual) {
        super.updateBounds(parentBounds, pixelToVirtual);
        if (elements.length == 0)
            return;

        Vec!(2, double) thisParentSize = this.boundsInsidePadding.size();
        double width = elementWidth.toAbsoluteVirtual(thisParentSize.x, pixelToVirtual).value;
        double height = elementHeight.toAbsoluteVirtual(thisParentSize.y, pixelToVirtual).value;
        double[2] pixelGap = gapToAbsVirtual(thisParentSize, pixelToVirtual);

        UiBounds firstBound = UiBounds(boundsInsidePadding.topLeft, boundsInsidePadding.topLeft
                + Vec!(2, double)(width, height));

        // Check sizes are positive
        if (thisParentSize.x <= 0)
            return stderr.writeln("Inproper parent width");
        else if (width <= 0)
            return stderr.writeln("Inproper element width");
        if (thisParentSize.y <= 0)
            return stderr.writeln("Inproper parent height");
        else if (height <= 0)
            return stderr.writeln("Inproper element height");

        if (thisParentSize.y < height)
            stderr.writeln("Element does not fit parent height");

        uint columns = calcColumnCount(thisParentSize.x, width, pixelGap);
        uint rows = calcRowCount(columns);

        double xBetween = 0;
        double yBetween = 0;
        if (columns >= 2) {
            xBetween = pixelGap[0];
            if (xCentered) {
                double centeredGap = (thisParentSize.x - columns * width) / (columns - 1);
                xBetween = (centeredGap > xBetween) ? centeredGap : xBetween;
            }
        }
        if (rows >= 2) {
            yBetween = pixelGap[1];
            if (yCentered) {
                double centeredGap = (thisParentSize.y - rows * height) / (rows - 1);
                yBetween = (centeredGap > yBetween) ? centeredGap : yBetween;
            }
        }

        uint column = 0;
        uint row = 0;
        foreach (UiNode element; elements) {
            UiBounds elementBounds = firstBound.shift(
                column * (width + xBetween),
                row * (height + yBetween));
            element.updateBounds(elementBounds, pixelToVirtual);

            column += 1;
            if (column == columns) {
                column = 0;
                row += 1;
            }
        }
    }

    override UiNode[] getContent() {
        return elements;
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
