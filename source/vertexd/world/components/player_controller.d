module vertexd.world.components.player_controller;

import bindbc.glfw;
import vdmath;
import vertexd.core.input;
import vertexd.core.input_manager;
import vertexd.world.components.component;
import vertexd.core.window : Window;
import vertexd.core.time;
import std.math.constants : PI, PI_2;
import std.algorithm.comparison : min, max;

/// Player controller, primarily as example.
class PlayerController : Component {
    float speed;
    double sensitivity;
    Vec!(3, int) moveDirection = Vec!(3, int)(0);
    Vec!(2, double) rotation;
    bool run = false;

    this(float speed = 1, double sensitivity = 0.005) {
        this.speed = speed;
        this.sensitivity = sensitivity;
        InputManager.register(&keyCallback);
        InputManager.register(&mousePositionCallback);
    }

    ~this() { // TODO: test whether this gets triggered properly (or whether the callbacks prevent deconstruction, making this class a Zombie)
        InputManager.deregister(&keyCallback);
        InputManager.deregister(&mousePositionCallback);
    }

    void keyCallback(Window window, KeyInput input) {
        if (input.action == KeyAction.repeat)
            return;
        switch (input.key) {
            case GLFW_KEY_A:
                moveDirection.x -= (input.action == KeyAction.press) ? 1 : -1;
                break;
            case GLFW_KEY_D:
                moveDirection.x += (input.action == KeyAction.press) ? 1 : -1;
                break;
            case GLFW_KEY_W:
                moveDirection.z -= (input.action == KeyAction.press) ? 1 : -1;
                break;
            case GLFW_KEY_S:
                moveDirection.z += (input.action == KeyAction.press) ? 1 : -1;
                break;
            case GLFW_KEY_LEFT_CONTROL:
                moveDirection.y -= (input.action == KeyAction.press) ? 1 : -1;
                break;
            case GLFW_KEY_SPACE:
                moveDirection.y += (input.action == KeyAction.press) ? 1 : -1;
                break;
            case GLFW_KEY_LEFT_SHIFT:
                run = input.action == KeyAction.press;
                break;
            case GLFW_KEY_ESCAPE:
                window.close();
                break;
            default:
        }
    }

    void mousePositionCallback(Window window, MousePositionInput input) {
        Vec!(2, double) delta = input.delta * sensitivity * Time.deltaTime();
        rotation = Vec!(2, double)((rotation.x + delta.x) % (2.0 * PI), max(-PI_2, min(PI_2, rotation.y + delta
                .y)));
    }

    override void update(Node caller) {
        // Determine rotation
        Quat yRotation = Quat.rotation(Vec!3(0, 1, 0), -rotation.x);
        Quat xRotation = Quat.rotation(Vec!3(1, 0, 0), -rotation.y);

        // Determine xz movement distance & direction
        Vec!3 xzDir = Vec!3(moveDirection.x, 0, moveDirection.z);
        if (xzDir.x != 0 && moveDirection.z != 0)
            xzDir = xzDir.normalize(); // pythagoras
        xzDir = yRotation ^ xzDir;
        Vec!3 movement = Vec!3(xzDir.x, moveDirection.y, xzDir.z);
        float effectiveSpeed = speed * (run ? 2 : 1);

        // Update position and rotaiton
        caller.position = caller.position() + movement * effectiveSpeed * Time.deltaTime();
        caller.rotation = yRotation * xRotation;
    }

    override void postUpdate(Node caller) {
    }
}
