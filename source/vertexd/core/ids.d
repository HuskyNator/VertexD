module vertexd.core.ids;

shared uint globalID = 0;

/// Template implementing (locally/globally) unique id's.
/// Beware to initialize using `setID`.
mixin template ID(bool global = false) {
    import core.atomic : atomicFetchAdd;
    import std.conv : to;

    static if (!global)
        shared static uint privateID;
    private uint _id;

    uint setID() {
        static if (global)
            this._id = atomicFetchAdd(globalID, 1);
        else
            this._id = atomicFetchAdd(privateID, 1);
        return this._id;
    }

    @property uint id() {
        return _id;
    }

    string idName() {
        return typeof(this).stringof ~ "#" ~ id.to!string;
    }
}

//TODO: could make it track using a static array as well.
