module vertexd.core.time;
import core.time;

final abstract class Time {
static:
    private ulong frame;
    private MonoTime startTime;
    private MonoTime frameStart;
    private Duration frameDuration;
    private float frameDeltaTime;

    void start() {
        frame = 0;
        startTime = MonoTime.currTime();
        frameStart = startTime;
    }

    void nextFrame() {
        frame += 1;
        MonoTime now = MonoTime.currTime();
        frameDuration = now - frameStart;
        frameStart = now;
        frameDeltaTime = (cast(float) frameDuration.total!"hnsecs"()) / 10_000_000.0f;
    }

    ulong frameID() nothrow {
        return frame;
    }

    Duration frameTime() {
        return frameStart - startTime;
    }

    Duration deltaDuration() {
        return frameDuration;
    }

    /// Returns delta duration in seconds.
    float deltaTime() {
        return frameDeltaTime;
    }

    float fps() {
        return 1 / frameDeltaTime;
    }
}
