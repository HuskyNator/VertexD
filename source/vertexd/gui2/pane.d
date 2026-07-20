module vertexd.gui2.pane;
import vertexd.gui2.size;
import vertexd.gui2.ui_element;
import vertexd.util.misc : removeAt, removeElement;

class Pane : UiElement {
    struct Placement {
        UiSize[2] size;
        UiSize[2] offset;
    }

    Placement[] placements;
    invariant (this.placements.length == this.children.length);

    void addChild(UiElement element,
        UiSize[2] size = [fraction(1), fraction(1)],
        UiSize[2] offset = [pixels(0), pixels(0)]) {
        this.children ~= element;
        this.placements ~= Placement(size, offset);
    }

    void removeChild(UiElement element) {
        size_t index = this.children.removeElement(element);
        this.placements.removeAt(index);
    }

    override void updateChildBounds() {
        foreach (i, Placement placement; this.placements) {
            UiElement child = this.children[i];
            double childLeft = this.bounds.left + placement.offset[0].getAbsolute(this.bounds.width());
            double childRight = childLeft + placement.size[0].getAbsolute(this.bounds.width());
            double childTop = this.bounds.top + placement.offset[1].getAbsolute(this.bounds.height());
            double childBottom = childTop + placement.size[1].getAbsolute(this.bounds.height());
            child.bounds = Bounds(childLeft, childRight, childTop, childBottom);
        }

        foreach (child; this.children)
            if(child.enabled)
                child.updateChildBounds();
    }
}
