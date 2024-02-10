module app;
import std.stdio;

abstract class App {
public:
	Window[] windows;

	this(Window[] windows...) {
		this.windows = windows;
	}

	abstract void update();
}
