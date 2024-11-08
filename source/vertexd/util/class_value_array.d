module vertexd.util.class_value_array;

struct ValueType(T) {
    enum size = __traits(classInstanceSize, A);
    enum alignment = __traits(classInstanceAlignment, A);
    align(alignment) const void[size] object;

    this(T object) {
        this.object = *cast(void[size]*) object;
    }

    const(T) get() const {
        return cast(const T)&object;
    }
}
