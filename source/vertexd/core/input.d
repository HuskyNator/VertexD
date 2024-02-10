module vertexd.core.input;
import bindbc.glfw;
import std.algorithm : min, max;

abstract class Input {
private static:
	uint nextID = 0;
	uint[int] keyIDs;

	uint getID(int key, bool isScanCode) {
		if (!isScanCode) {
			key = glfwGetKeyScancode(key);
			assert(key != -1, "Key not supported");
		}
		uint id = *(keyIDs.require(key, nextID));
		if (id == nextID) {
			nextID += 1;
			keyStates ~= [false, false, false];
		}
		return id;
	}

	uint[3] minKeyUpdated;
	uint[3] maxKeyUpdated; //exclusive
	bool[3][] keyStates; // [released, pressed, repeated]
	bool[2][8] buttonStates; // [pressed, released]

	// GLFW_RELEASE,_PRESS,REPEAT = 0,1,2
	bool getKey(int key, ubyte action = GLFW_PRESS, bool isScanCode = false) {
		uint id = getID(key, isScanCode);
		return keyStates[id][action];
	}

	bool getButton(int button, ubyte action = GLFW_PRESS) {
		return buttonStates[button][action];
	}

	Vec!(2, double)[Window] mousePos; // persistent
	Vec!(2, double)[Window] mouseWheel; // persistent??
	bool[Window] mouseHover;

	void unset() {
		keyStates[] = [false, false, false];
		minKeyUpdated[] = 0;
		maxKeyUpdated[] = 0;
		buttonStates[0][] = false;
		buttonStates[] = [false, false];
	}

	void setKey(int key, int scancode, int action, int mods) {
		uint id = getID(scancode, true);
		minKeyUpdated[action] = min(id, minKeyUpdated);
		maxKeyUpdated[action] = max(id + 1, maxKeyUpdated);
		keyStates[action][id] = true;
	}

	void setButton(int button, int action) {
		buttonStates[action][button] = true;
	}

	extern (C) void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods) nothrow {
		App.setKey(scancode, action, true);
	}

	extern (C) void button_callback(GLFWwindow* window, int button, int action, int mods) nothrow {
		App.setButton(button, action);
	}
}
