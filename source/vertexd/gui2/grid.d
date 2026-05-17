module vertexd.gui2.grid;
import vertexd.gui2.size;
import vertexd.gui2.ui_element;
import std.algorithm.mutation : removeAt = remove;

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

    override void updateChildBounds() { // holdup how do i deal with parent sizes??? grids are fixed!!
        assert(this.children.length == this.cellRanges.length);

        this.rowEdges = new double[rows.length + 1](0);
        this.colEdges = new double[cols.length + 1](0);
        this.rowEdges[0] = this.top();
        this.colEdges[0] = this.left();

        double totalWidth = this.bounds.width();
        double totalHeight = this.bounds.height();
        foreach (i, UiSize size; this.rows)
            this.rowEdges[i + 1] += size.getAbsolute(totalHeight);
        foreach (i, UiSize size; this.cols)
            this.colEdges[i + 1] += size.getAbsolute(totalWidth);

        foreach (i, CellRange cellRange; this.cellRanges) {
            UiElement element = this.children[i];
            double[2] yBounds = [
                rowEdges[cellRange.rows[0]], rowEdges[cellRange.rows[1]]
            ];
            double[2] xBounds = [
                colEdges[cellRange.cols[0]], colEdges[cellRange.cols[1]]
            ];
            element.bounds = Bounds(xBounds, yBounds);
        }
    }

    void assign(R, C)(UiElement element, R rows, C cols)
            if ((is(R == uint) || is(R == uint[2]))
            && (is(C == uint) || is(C == uint[2]))) {
        uint[2] _toRange(T)(T val) {
            if (is(T == uint))
                return [val, val + 1];
            return val;
        }

        Assignment assignment = Assignment(_toRange(rows), _toRange(cols));
        this.assignments ~= assignment;
    }

    void remove(UiElement element) {
        foreach (i, Assignment a; assignments) {
            if (a.element is element) {
                this.assignments = this.assignments.removeAt(i);
                return;
            }
        }
        throw new Exception("Element was not part of grid: " ~ element.toString());
    }
}
