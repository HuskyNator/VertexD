module vertexd.core.ids;

shared size_t global_id = 0;

mixin template ID(bool global = false) {
    import core.atomic: atomicFetchAdd;
    import std.conv: to;

    static if (!global)
        shared size_t private_id;
    size_t id;

    size_t setID() {
        static if (global)
            this.id = atomicFetchAdd(global_id, 1);
        else
            this.id = atomicFetchAdd(private_id, 1);
        return this.id;
    }

    string idName(){
        return typeof(this).stringof~"#"~id.to!string;
    }
}

//TODO: could make it track using a static array as well.