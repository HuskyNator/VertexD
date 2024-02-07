module engine;
import app;

final class Engine {
static:
private:
	void initialize() {
		glfwInit();
	}

	void destroy() {
		glfwTerminate();
	}

	uint engineCount = 0;
	public this() {
		if (engineCount == 0)
			Engine.initialize();
		engineCount += 1;
	}

	public ~this() {
		engineCount -= 1;
		if (engineCount == 0)
			Engine.destroy();
	}

	public void run(App app) {
		// TODO
	}
}
