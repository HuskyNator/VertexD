module vertexd.core.time;
import core.time;

final abstract class Time {
static:
    private ulong frame;
    private MonoTime startTime;
    private MonoTime frameStart;
    private Duration frameDuration;

    void start() {
        frame = 0;
        startTime = MonoTime.currTime;
        frameStart = MonoTime.currTime;
    }

    void nextFrame() {
        frame += 1;
        MonoTime now = MonoTime.currTime;
        frameDuration = now - frameStart;
        frameStart = now;
    }

    ulong frameID() {
        return frame;
    }

    Duration frameTime(){
        return frameStart - startTime;
    }

    Duration deltaDuration() {
        return frameDuration;
    }

    /// Returns delta duration in seconds.
    float deltaTime() {
        return (cast(float) frameDuration.total!"hnsecs"()) / 10_000_000.0f;
    }

    float fps() {
        return 1 / deltaTime();
    }
}
