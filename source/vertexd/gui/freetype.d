module vertexd.gui.freetype;

import std.stdio;
import bindbc.freetype;
import std.exception : enforce;

FT_Library _FreeTypeLib;

void _initFreeType() {
    FT_Error error = FT_Init_FreeType(&_FreeTypeLib);
    enforce(error == 0, "Could not load library FreeType");
}

void _terminateFreeType() {
    FT_Done_FreeType(_FreeTypeLib);
    _FreeTypeLib = null;
}
