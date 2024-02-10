module engine;
import app;
import bindbc.glfw;

final abstract class Engine {
static private:
	public void run(App app) {
		app.update();

		//... ?

		glfwPollEvents();
	}

	// TODO: run(App[] apps...) ? (multiplex)
}
