module vertexd.util.templates.tracked_properties;

mixin template TrackedProperties(S, string name) {
    bool changed = false;
    mixin(S.stringof, " _", name, ";");
    @property {
        static foreach (member; S.tupleof) {
            mixin(typeof(member).stringof, " ", member.stringof, "(){return _", name, ".", member.stringof, ";}");
            mixin("void ", member.stringof, "(", typeof(member)
                    .stringof, " val){this.changed=true;this._", name, ".", member
                    .stringof, " = val;}");
        }
        mixin(S.stringof, " ", name, "(){return _", name, ";}");
        mixin("void ", name, "(", S.stringof, " val){this._", name, "=val;}");
    }
}

///
unittest {
    struct Date {
        string month;
        float hour;
    }

    class A {
        mixin TrackedProperties!(Date, "date");

        this(Date today) {
            this._date = today;
        }
    }

    A today = new A(Date("november", 22.0f));
    assert(!today.changed);

    today.hour = today.hour + 1;
    assert(today.changed);
}
