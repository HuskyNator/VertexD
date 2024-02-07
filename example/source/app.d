module app;
import std.stdio;

abstract class App {
private:
	int appCount = 0;

	this(Engine engine) {
		if (appCount == 0)
			Engine.initialize();
		appCount += 1;
	}

	~this() {
		appCount -= 1;
		if (appCount == 0)
			Engine.terminate();
	}

	abstract void update();
	final void run() {
		update();
		// vdInit();
	}
}
