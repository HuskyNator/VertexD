module vertexd.core.input;

import bindbc.glfw.types;
import std.traits;
import vdmath;

enum KeyAction: ubyte {
    press = GLFW_PRESS,
    release = GLFW_RELEASE,
    repeat = GLFW_REPEAT
}

enum MouseButton: byte {
    mouse_1 = GLFW_MOUSE_BUTTON_1,
    mouse_2 = GLFW_MOUSE_BUTTON_2,
    mouse_3 = GLFW_MOUSE_BUTTON_3,
    mouse_4 = GLFW_MOUSE_BUTTON_4,
    mouse_5 = GLFW_MOUSE_BUTTON_5,
    mouse_6 = GLFW_MOUSE_BUTTON_6,
    mouse_7 = GLFW_MOUSE_BUTTON_7,
    mouse_8 = GLFW_MOUSE_BUTTON_8,
    mouse_left = mouse_1,
    mouse_right = mouse_2,
    mouse_middle = mouse_3
}

enum MouseAction: ubyte {
    press = GLFW_PRESS,
    repeat = GLFW_RELEASE
}

enum Modifier: ubyte {
    shift = GLFW_MOD_SHIFT,
    control = GLFW_MOD_CONTROL,
    alt = GLFW_MOD_ALT,
    super_ = GLFW_MOD_SUPER,
    caps = GLFW_MOD_CAPS_LOCK,
    nu = GLFW_MOD_NUM_LOCK
}

struct KeyInput {
    int key, key_code;
    KeyAction action;
    Modifier modifier;
    this(int key, int key_code, int action, int modifier) nothrow {
        this.key = key;
        this.key_code = key_code;
        this.action = cast(KeyAction) action;
        this.modifier = cast(Modifier) modifier;
    }
}

struct MouseButtonInput {
    MouseButton button;
    MouseAction action;
    Modifier modifier;
    this(int button, int action, int modifier) nothrow {
        this.button = cast(MouseButton) button;
        this.action = cast(MouseAction) action;
        this.modifier = cast(Modifier) modifier;
    }
}

struct MousePositionInput {Vec!(2,double) position; alias this = position;}
struct ScrollInput {Vec!(2,double) delta; alias this = delta;}
struct MouseEnterInput {bool enter; alias this = enter;}

struct InputEvent {
    enum Tag: ubyte {
        none,
        key,
        mouseButton,
        mousePosition,
        mouseExit,
        scroll,
    }
    union Input {
        void[0] _;
        KeyInput keyInput;
        MouseButtonInput mouseButtonInput;
        MousePositionInput mousePositionInput;
        MouseEnterInput mouseEnterInput;
        ScrollInput scrollInput;
    }

    GLFWwindow* window;
    Tag tag = Tag.none;
    Input input;
    alias this = input;

    /// Create input constructor. Beware bug #3332: issues.dlang.org/show_bug.cgi?id=3332
    mixin template Constructor(Tag tag, alias field) {
        this(GLFWwindow* window, typeof(field) input) nothrow {
            this.window = window;
            this.tag = tag;
            mixin(field.stringof) = input;
        }
    }

	static foreach(i; 0.. EnumMembers!Tag.length)
        mixin Constructor!(EnumMembers!Tag[i], Input.tupleof[i]);
}
