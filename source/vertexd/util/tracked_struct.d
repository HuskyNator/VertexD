module vertexd.util.tracked_struct;

struct TrackedStruct(T) {
    T value;
    bool changed = false;

    @property {
        static foreach (member; T.tupleof) {
            mixin("typeof(member) ", __traits(identifier, member), "(){
                return value.", __traits(identifier, member), ";}");
            mixin("void ", __traits(identifier, member), "( typeof(member) newVal){
                if(this.value.", __traits(identifier, member), "!=newVal){
                    this.changed=true;
                    this.value.", __traits(identifier, member), "=newVal;
                }}");
        }
    }

    void opAssign(T newVal) {
        if (value != newVal) {
            this.changed = true;
            this.value = newVal;
        }
    }
}

///
unittest {
    struct Date {
        string month;
        float hour;
    }

    class A {
        TrackedStruct!(Date) date;

        this(Date today) {
            this.date = TrackedStruct!(Date)(today);
        }
    }

    A today = new A(Date("november", 22.0f));
    assert(!today.changed);

    today.hour = today.hour + 1;
    assert(today.changed);
}
