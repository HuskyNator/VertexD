module vertexd.core.app;

class App {
	
	void update();

	void addWindow(Window window){
		// make window current here?
		// or rather: create window _here_ (dont instantiate before adding to app?) & have the context be local to the App
		// or change to `Window addWindow(string name, int width, int height)` ?
	}
}