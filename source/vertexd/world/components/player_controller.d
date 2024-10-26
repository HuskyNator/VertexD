module vertexd.world.components.player_controller;

import bindbc.glfw;
import vdmath;
import vertexd.core.input;
import vertexd.core.input_manager;
import vertexd.world.components.component;
import vertexd.core.window : Window;

/// Player controller, primarily as example.
class PlayerController : Component {
    float speed;
    float sensitivity;
    Vec!(2, int) moveDirection;
    Vec!(2, float) rotateDelta;

    this(float speed = 1, float sensitivity = 1) {
        InputManager.register(&keyCallback);
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
            default:
        }
    }

    void mousePositionCallback(Window window, MousePositionInput input) {
        rotateDelta = cast(Vec!(2, float)) input.delta * sensitivity;
    }

    override void update(Node owner) {
        owner.position = owner.position + Vec!3(moveDirection * speed, 0);
        Vec!3 right = owner.rotation ^ Vec!3(1, 0, 0);
        owner.rotation *= Quat.rotation(right, rotateDelta.x);
        owner.rotation *= Quat.rotation(Vec!3(0, 0, 1), rotateDelta.y);
    }

    override void postUpdate(Node owner) {
    }
}
