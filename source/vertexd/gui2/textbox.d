module vertexd.gui2.textbox;
import bindbc.glfw;
import core.time;
import std.datetime.systime;
import vdmath;
import vertexd;
import vertexd.gui.font;
import vertexd.gui2;
import std.algorithm.comparison : max;

class TypeBox : TextBox {
    bool inFocus = false;
    bool blinkOn = false;
    int cursorPosition;
    SysTime blinkTime;

    // for now ignores window
    void charCallback(Window window, InputType.Character input) {
        if (!inFocus)
            return;
        addChar(input.character);
    }

    void keyCallback(Window window, InputType.Key input) {
        if (!inFocus)
            return;
        if (input.action == KeyAction.release)
            return;
        switch (input.key) {
            case GLFW_KEY_BACKSPACE:
                if (this.text.length > 0)
                    removeChar();
                break;
            case GLFW_KEY_ENTER:
                addChar('\n');
                break;
            case GLFW_KEY_ESCAPE:
                setFocus(false);
                break;
            default:
                break;
        }
    }

    void clickedSomewhere(Window window, InputType.MouseButton input) {
        if (input.button == MouseButton.mouseLeft && input.action == MouseAction.press) {
            if (this.bounds.contains(window.mousePosition)) {
                setCursorToPosition(cast(Vec!(2, int))(window.mousePosition * window.toPixelsRatio()));
                setFocus(true);
            } else
                setFocus(false);
        }
    }

    void setCursorToPosition(Vec!(2, int) mousePosition) { // TODO: make work with scroll
        if (layout.length == 0) {
            this.cursorPosition = 0;
            return;
        }

        int line = max(0, (mousePosition.y - offset.y) / font.lineHeight);
        int cursorIndex = this.text.length - 1;
        foreach (index, Vec!(2, int) charPosition; this.layout) {
            if (charPosition.y < mousePosition.y)
                continue;
            if (charPosition.y > mousePosition.y + font.lineHeight)
                break;
            // TODO: clicking left of left most character (due to offset)
            if (charPosition.x > mousePosition.x)
                break;
            cursorIndexRight = index;
        } // THIS ALGORITHM IS BAD, CAN DO BETTER ^

    }

    void setFocus(bool focus) {
        if (focus == inFocus)
            return;
        if (focus)
            setBlinkOn();
        else
            setBlinkOff();
        this.inFocus = focus;
    }

    void removeChar() {
        setBlinkOff();
        this.text.length -= 1;
    }

    void addChar(dchar character) {
        setBlinkOff();
        this.text ~= character;
    }

    void setBlinkOn() {
        if (inFocus && !blinkOn) {
            blinkOn = true;
            blinkTime = Clock.currTime();
        }
    }

    void setBlinkOff() {
        blinkOn = false;
    }

    override void updateChildBounds() {
        if (inFocus) {
            Duration blinkDur = Clock.currTime() - blinkTime;
            long msecs = blinkDur.total!"msecs"();
            if (msecs % 1000 > 500)
                setBlinkOff();
            else
                setBlinkOn();
        }

        super.updateChildBounds();
    }

    this(T...)(T args) {
        super(args);
        InputManager.register(&charCallback);
        InputManager.register(&keyCallback);
        InputManager.register(&clickedSomewhere);
    }

    ~this() {
        InputManager.deregister(&charCallback);
        InputManager.deregister(&keyCallback);
        InputManager.deregister(&clickedSomewhere);
    }
}
