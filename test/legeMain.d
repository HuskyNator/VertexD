module test.legeMain;

// Lege main, maakt het mogelijk hoekjed als executable te bouwen. Dit is nodig om een unittest
// build te bouwen. Zie https://github.com/dlang/dub/issues/1856.

void main() {
	pragma(msg, "Test main gecompileerd.");
}
