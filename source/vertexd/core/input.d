module vertexd.core.input;

import bindbc.glfw.types;
import std.traits;
import vdmath;
import vertexd.core.window;

enum KeyAction : ubyte {
    press = GLFW_PRESS,
    release = GLFW_RELEASE,
    repeat = GLFW_REPEAT
}

enum MouseButton : byte {
    mouse1 = GLFW_MOUSE_BUTTON_1,
    mouse2 = GLFW_MOUSE_BUTTON_2,
    mouse3 = GLFW_MOUSE_BUTTON_3,
    mouse4 = GLFW_MOUSE_BUTTON_4,
    mouse5 = GLFW_MOUSE_BUTTON_5,
    mouse6 = GLFW_MOUSE_BUTTON_6,
    mouse7 = GLFW_MOUSE_BUTTON_7,
    mouse8 = GLFW_MOUSE_BUTTON_8,
    mouseLeft = mouse1,
    mouseRight = mouse2,
    mouseMiddle = mouse3
}

private alias _MouseButton = MouseButton; // prevent local name collision

enum MouseAction : ubyte {
    press = GLFW_PRESS,
    release = GLFW_RELEASE
}

enum Modifier : ubyte {
    shift = GLFW_MOD_SHIFT,
    control = GLFW_MOD_CONTROL,
    alt = GLFW_MOD_ALT,
    super_ = GLFW_MOD_SUPER,
    caps = GLFW_MOD_CAPS_LOCK,
    nu = GLFW_MOD_NUM_LOCK
}

/// Sequence of InputType type names
alias InputTypeNames = __traits(derivedMembers, InputType);
/// Sequence of InputType types
alias InputTypes = staticMap!(_getMember, InputTypeNames);
private alias _getMember(string member) = __traits(getMember, InputType, member);

// alias KeyInput = InputType.Key;
// mixin("alias ", "Key", "Input=InputType.", "Key", ";");
// // Expose InputType types

//     pragma(msg, member,"Input");
// }

/// Collection of Input Types.
final abstract class InputType {
static:
    struct Key {
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

    struct Character {
        dchar character;
    }

    struct MouseButton {
        _MouseButton button;
        MouseAction action;
        Modifier modifier;
        this(int button, int action, int modifier) nothrow {
            this.button = cast(_MouseButton) button;
            this.action = cast(MouseAction) action;
            this.modifier = cast(Modifier) modifier;
        }
    }

    struct MousePosition {
        Vec!(2, double) position;
        Vec!(2, double) delta;
    }

    struct MouseEnter {
        bool enter;
    }

    struct Scroll {
        Vec!(2, double) delta;
    }

    struct FileDrop {
        string[] paths;
    }
}

static foreach (string member; InputTypeNames)
    mixin("alias ", member, "Input = InputType.", member, ";");

private {
    string _firstToLower(string typeName) {
        import std.ascii : toLower, isASCII;

        char[] tag = typeName.dup;
        assert(isASCII(tag[0]));
        tag[0] = toLower(tag[0]);
        return tag.idup;
    }

    string _tagsMixin() {
        string tags;
        static foreach (string member; InputTypeNames)
            tags ~= _firstToLower(member) ~ ',';
        return tags;
    }

    string _inputMixin() {
        string input;
        static foreach (string member; InputTypeNames)
            input ~= "InputType." ~ member ~ ' ' ~ _firstToLower(member) ~ "Input;";
        return input;
    }
}

/// Tagged union with a reference to the matching window.
struct InputEvent {

    /// Tags for Input types, defined as the lowerCamelCase of UpperCamelCase typenames.
    mixin("enum Tag{", _tagsMixin(), "}");

    /// Union for Input types, matches `Tag` with "Input" appended to identifiers.
    mixin("union InputData{", _inputMixin(), "}"); //TODO: Explore defining types inside InputData union instead.

    Window window;
    Tag tag;
    InputData input;

    static foreach (i; 0 .. EnumMembers!Tag.length) {
        this(Window window, typeof(InputData.tupleof[i]) input) nothrow {
            this.window = window;
            this.tag = EnumMembers!Tag[i];
            mixin("this.input.",__traits(identifier, InputData.tupleof[i]), "= input;");
        }
    }
}
