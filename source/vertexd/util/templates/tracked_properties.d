module vertexd.util.templates.tracked_properties;

mixin template TrackedProperties(S, string name) {
    bool _changed = false;
    mixin(S.stringof, " _", name, ";");
    @property {
        static foreach (member; S.tupleof) {
            mixin(typeof(member).stringof, " ", member.stringof, "(){return _", name, ".", member.stringof, ";}");
            mixin("void ", member.stringof, "(", typeof(member)
                    .stringof, " val){if(this._", name, ".", member.stringof, "==val)return;
                    this._changed=true;
                    this._", name, ".", member.stringof, " = val;}");
        }
        mixin(S.stringof, " ", name, "(){return _", name, ";}");
        mixin("void ", name, "(", S.stringof, " val){this._changed=true;this._", name, "=val;}");
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
    assert(!today._changed);

    today.hour = today.hour + 1;
    assert(today._changed);
}
