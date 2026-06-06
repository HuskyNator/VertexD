module vertexd.gui2.image;
import vertexd.gui2.ui_element;
import vertexd.memory.bindless_texture;

class Image : UiElement {
    BindlessTexture texture;

    this(BindlessTexture texture) {
        this.texture = texture;
    }

    override void updateChildBounds() {
        return;
    }

}
