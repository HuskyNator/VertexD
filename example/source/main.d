module main;
import app;
import std.stdio;
import vertexd;

void main() {
	App app = new MyApp();
	Engine.run(app);
}

class MyApp : App {

	// Player player;
	// Scene scene;

	this() {
		// Cube cube = new Cube();
		// cube.rotation = Vec!3(0, 0, PI / 2);
		// cube.position = Vec!3(3, 3, 3);

		// Player player = new Player();
		// Camera cam = new ProjectiveCamera(w, h, 0, 100);
		// cam.bind(player);
		// // set cam to inherit/child player?

		// Scene scene = new Scene();
		// scene.add(cube);
		// scene.add(player);

		// Window window = app.addWindow("Test", 800, 800);
		// window.setScene(scene);
		// window.bind(player);
	}

	override void update() {
		writeln("nothing to see here");
	}

}
