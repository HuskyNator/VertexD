module app;
import mat;
import bindbc.glfw;

abstract class App {
private:
	

public:
	Window[] windows;

	this(Window[] windows...) {
		foreach (Window window; windows)
			registerWindow(window);
	}

	final void registerWindow(Window window) {
		this.windows ~= window;
		glfwSetKeyCallback(window.glfw_window, &key_callback);
	}

	abstract void update();
}
