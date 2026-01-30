module vertexd.core.input_manager;

import bindbc.glfw;
import vdmath;
import vertexd.core.input;
import vertexd.core.window;
import vertexd.util.misc : removeElement;
import std.traits: EnumMembers;

extern (C) void key_callback(GLFWwindow* glfw_window, int key, int key_code, int event, int modifier) nothrow {
    InputManager.log(InputEvent(Window.windows[glfw_window], KeyInput(key, key_code, event, modifier)));
}

extern (C) void mouse_button_callback(GLFWwindow* glfw_window, int button, int event, int modifier) nothrow {
    InputManager.log(InputEvent(Window.windows[glfw_window], MouseButtonInput(button, event, modifier)));
}

extern (C) void mouse_position_callback(GLFWwindow* glfw_window, double x, double y) nothrow {
    Window window = Window.windows[glfw_window];
    // TODO: reset cursor position under disabled cursor mode to prevent rounding issues?
    Vec!(2, double) newPosition = Vec!(2, double)(x, y);
    Vec!(2, double) delta = newPosition - window.mousePosition;
    window.mousePosition = newPosition;
    InputManager.updateMousePosition(window, newPosition);
    InputManager.log(InputEvent(window, MousePositionInput(newPosition, delta)));
}

extern (C) void scroll_callback(GLFWwindow* glfw_window, double x, double y) nothrow {
    InputManager.log(InputEvent(Window.windows[glfw_window], ScrollInput(Vec!(2, double)(x, y))));
}

extern (C) void mouse_enter_callback(GLFWwindow* glfw_window, int enter) nothrow {
    Window window = Window.windows[glfw_window];
    if (enter)
        glfwGetCursorPos(glfw_window, &window.mousePosition.x, &window.mousePosition.y);
    InputManager.log(InputEvent(Window.windows[glfw_window], MouseEnterInput(enter == 1)));
}

final abstract class InputManager {
static:
    private InputEvent[] inputEvents;
    private Vec!(2, double) mousePosition; // global on virtual screen

    void updateMousePosition(Window window, Vec!(2, double) mousePosition) nothrow {
        this.mousePosition = (cast(Vec!(2, double)) window.windowPosition) + mousePosition;
    }

    void log(InputEvent event) nothrow {
        this.inputEvents ~= event;
    }

    void clear() {
        this.inputEvents.length = 0;
    }

    /// Register Window with InputManager
    void register(Window window) {
        glfwSetKeyCallback(window.glfw_window, &key_callback);
        glfwSetMouseButtonCallback(window.glfw_window, &mouse_button_callback);
        glfwSetCursorPosCallback(window.glfw_window, &mouse_position_callback);
        glfwSetScrollCallback(window.glfw_window, &scroll_callback);
        glfwSetCursorEnterCallback(window.glfw_window, &mouse_enter_callback);
    }

    private alias CallBack(T) = void delegate(Window, T);
    private string _callBackName(size_t i)() {
        return "_callback" ~ InputTypeNames[i];
    }

    static foreach (i, Type; InputTypes) {
        mixin("CallBack!(InputTypes[i])[] ", _callBackName!i, ";");

        /// Register CallBack with InputManager
        void register(CallBack!(Type) func) {
            mixin(_callBackName!i) ~= func;
        }

        void deregister(CallBack!(Type) func) {
            mixin(_callBackName!i).removeElement(func);
        }
    }

    void runCallbacks() {
        foreach (event; inputEvents) {
            final switch (event.tag) {
                static foreach (i, tag; EnumMembers!(InputEvent.Tag))
                    case tag:
                        foreach (callback; mixin(_callBackName!i))
                            callback(event.window, event.input.tupleof[i]);
                        break;
                        }
            }

            clear();
        }

        void pollInput() {
            glfwPollEvents();
        }
    }
