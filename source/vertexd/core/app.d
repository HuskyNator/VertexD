module vertexd.core.app;
import bindbc.glfw;

abstract class App {
public:
	InputManager inputManager;
	Window[] windows;

	this(Engine engine) {
	}

	final void addWindow(Window window) {
		this.windows ~= window;
		window.bind(inputManager);
	}

	final void removeWindow(Window window) {
		this.windows.remove(window);
		window.unbind();
	}

	abstract void update();
}
