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
    Vec!(2, int) moveDirection = Vec!(2, int)(0);
    Vec!(2, double) rotation;

    this(float speed = 1, double sensitivity = 0.001) {
        this.speed = speed;
        this.sensitivity = sensitivity;
        InputManager.register(&keyCallback);
        InputManager.register(&mousePositionCallback);
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
                moveDirection.y += (input.action == KeyAction.press) ? 1 : -1;
                break;
            case GLFW_KEY_S:
                moveDirection.y -= (input.action == KeyAction.press) ? 1 : -1;
                break;
            case GLFW_KEY_ESCAPE:
                window.close();
                break;
            default:
        }
    }

    void mousePositionCallback(Window window, MousePositionInput input) {
        Vec!(2, double) delta = input.delta * sensitivity;
        delta.x = 0;
        rotation = Vec!(2, double)((rotation.x + delta.x) % (2 * PI), max(-PI_2, min(PI_2, rotation.y + delta
                .y)));
    }

    override void update(Node caller) {
        caller.position = caller.position() + Vec!3(moveDirection * speed * Time.deltaTime(), 0);
        caller.rotation = Quat.rotation(Vec!3(0, 1, 0), -rotation
                .x) * Quat.rotation(Vec!3(1, 0, 0), -rotation.y);
    }

    override void postUpdate(Node caller) {
    }
}
