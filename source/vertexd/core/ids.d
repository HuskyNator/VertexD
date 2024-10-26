module vertexd.core.ids;

shared uint globalID = 0;

mixin template ID(bool global = false) {
    import core.atomic : atomicFetchAdd;
    import std.conv : to;

    static if (!global)
        shared static uint privateID;
    uint id;

    size_t setID() {
        static if (global)
            this.id = atomicFetchAdd(globalID, 1);
        else
            this.id = atomicFetchAdd(privateID, 1);
        return this.id;
    }

    string idName() {
        return typeof(this).stringof ~ "#" ~ id.to!string;
    }
}

//TODO: could make it track using a static array as well.
