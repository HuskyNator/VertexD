module vertexd.gui2.grid;
import vertexd.gui2.size;
import vertexd.gui2.ui_element;
import vertexd.util.misc : removeElement, removeAt;

// TODO: add mouse interaction

// TODO: Why don't programming languages _generate_ tagged unions.
// automatically seeing during compilation what structs implement a defined tagged union & adding support for it.

class Grid : UiElement {
    UiSize[] rows;
    UiSize[] cols;
    private double[] rowEdges;
    private double[] colEdges;

    struct CellRange {
        uint[2] rows;
        uint[2] cols;
    }

    CellRange[] cellRanges;
    invariant (this.cellRanges.length == this.children.length);

    override void updateChildBounds() {
        this.rowEdges = new double[rows.length + 1];
        this.colEdges = new double[cols.length + 1];
        this.rowEdges[] = 0;
        this.colEdges[] = 0;
        this.rowEdges[0] = this.top;
        this.colEdges[0] = this.left;

        double totalWidth = this.bounds.width();
        double totalHeight = this.bounds.height();
        foreach (i, UiSize size; this.rows)
            this.rowEdges[i + 1] += size.getAbsolute(totalHeight); // shouldnt this sum all?
        foreach (i, UiSize size; this.cols)
            this.colEdges[i + 1] += size.getAbsolute(totalWidth);

        foreach (i, CellRange cellRange; this.cellRanges) {
            UiElement element = this.children[i];
            double top = rowEdges[cellRange.rows[0]];
            double bottom = rowEdges[cellRange.rows[1]];
            double left = colEdges[cellRange.cols[0]];
            double right = colEdges[cellRange.cols[1]];
            element.bounds = Bounds(left, right, top, bottom);
        }

        foreach (child; this.children) {
            if (child.enabled)
                child.updateChildBounds();
        }
    }

    void place(R, C)(UiElement element, R rows, C cols)
            if ((is(R == uint) || is(R == uint[2])) && (is(C == uint) || is(C == uint[2]))) {
        uint[2] _toRange(T)(T val) {
            return (is(T == uint)) ? [val, val + 1] : val;
        }

        CellRange range = CellRange(_toRange(rows), _toRange(cols));
        this.cellRanges ~= range;
        this.children ~= element;
    }

    void remove(UiElement element) {
        size_t index = this.children.removeElement(element);
        this.cellRanges.removeAt(index);
    }
}
