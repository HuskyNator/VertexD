module vertexd.core.input_manager;

import vertexd.core.input;
import vertexd.core.window;
import bindbc.glfw;
import vdmath;
import vertexd.misc: removeElement;

extern(C) void key_callback(GLFWwindow* window, int key, int key_code, int event, int modifier) nothrow {
    InputManager.log(InputEvent(window, KeyInput(key, key_code, event, modifier) ));
}

extern (C) void mouse_button_callback(GLFWwindow* window, int button, int event, int modifier) nothrow {
	InputManager.log(InputEvent(window, MouseButtonInput(button, event, modifier) ));
}

extern (C) void mouse_position_callback(GLFWwindow* window, double x, double y) nothrow {
	InputManager.log(InputEvent(window, MousePositionInput(Vec!(2,double)(x, y))));
}

extern (C) void scroll_callback(GLFWwindow* window, double x, double y) nothrow {
	InputManager.log(InputEvent(window, ScrollInput(Vec!(2,double)(x, y))));
}

extern (C) void mouse_enter_callback(GLFWwindow* window, int enter) nothrow {
    InputManager.log(InputEvent(window, MouseEnterInput(enter == 1)));
}

final abstract class InputManager{
    static:
    private InputEvent[] inputEvents;

    void log(InputEvent event) nothrow {
        this.inputEvents ~= event;
    }

    void clear(){
        this.inputEvents.length = 0;
    }

    void register(Window window){
        glfwSetKeyCallback(window.glfw_window, &key_callback);
		glfwSetMouseButtonCallback(window.glfw_window, &mouse_button_callback);
		glfwSetCursorPosCallback(window.glfw_window, &mouse_position_callback);
		glfwSetScrollCallback(window.glfw_window, &scroll_callback);
        glfwSetCursorEnterCallback(window.glfw_window, &mouse_enter_callback);
    }

    mixin template CallbackMixin(size_t i, alias Type) {
        alias Callback = void delegate(GLFWwindow*, Type);
        enum name = "callbacks_" ~ i.stringof;
        mixin("Callback[] ",  name,";");
        void register( Callback func ) {
            mixin(name) ~= func;
        }
        void deregister( Callback func) {
            mixin(name).removeElement(func);
        }
    }

    static foreach(i; 0.. InputEvent.Input.tupleof.length){
        mixin CallbackMixin!(i, typeof(InputEvent.Input.tupleof[i]));
    }

    void runCallbacks(){
        foreach(event; inputEvents) {
            final switch(event.tag) {
                static foreach(i; 0..InputEvent.Input.tupleof.length)
                    case i:
                        foreach(callback; mixin("callbacks_", i.stringof))
                            callback( event.window, event.input.tupleof[i] );
                    break;
            }
        }
    }


}