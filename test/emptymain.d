module test.emptymain;

/// Empty main, enables building vertexd as executable, required to build unittests
/// See https://github.com/dlang/dub/issues/1856
void main() {
	pragma(msg, "Test main compiled.");
}
