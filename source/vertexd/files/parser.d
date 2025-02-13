module vertexd.files.parser;

import std.ascii : isWhite;
import std.conv : ConvException, parse, to;
import std.file : read;
import std.typecons : Flag, No, Yes;

/// Utility class.
/// Can be extended by using composition (eg. with alias this)
struct Parser {
    string path;
    size_t index = 0;
    size_t line = 0;
    immutable char[] data;

    this(string path) {
        this.path = path;
        data = cast(immutable char[]) read(path);
    }

    bool peek(const char[] expect) {
        if (index + expect.length >= data.length)
            return false;
        return data[index + 1 .. index + expect.length + 1] == expect;
    }

    void skipWhitespace() {
        while (index < data.length && data[index].isWhite()) {
            if (data[index] == '\n')
                line += 1;
            index += 1;
        }
    }

    void skipLine() {
        while (index < data.length) {
            if (data[index] == '\n') {
                line += 1;
                index += 1;
                break;
            }
            index += 1;
        }
    }

    string consumeWord(bool expectNewline = false)() {
        return consumeWord!expectNewline(&skipWhitespace);
    }

    string consumeWord(bool expectNewline = false)(void delegate() whitespaceSkipper) {
        assert(index < data.length && !data[index].isWhite());
        static if (expectNewline) {
            size_t oldLine = line;
            scope (success)
                if (line == oldLine && index != data.length)
                    throw new Parser.ParseException(this, "Expected end of line at index " ~ index
                            .to!string);
        }
        size_t startIndex = index;
        while (index < data.length) {
            if (data[index].isWhite())
                break;
            index += 1;
        }
        size_t end = index;
        whitespaceSkipper();
        return data[startIndex .. end];
    }

    T consumeNumber(T, bool expectNewline = false)() {
        return consumeNumber!(T, expectNewline)(&skipWhitespace);
    }

    T consumeNumber(T, bool expectNewline = false)(void delegate() whitespaceSkipper) {
        string word = cast(string) consumeWord!(expectNewline)(whitespaceSkipper);
        return parseNumber!T(word);
    }

    T parseNumber(T)(string word) {
        try {
            size_t wordLength = word.length; // parse consumes word.
            auto result = parse!(T, string, Yes.doCount)(word);
            if (result.count != wordLength)
                throw new ParseException(this, "Number parse length incorrect " ~ result.count.to!string ~ " instead of " ~ word
                        .length.to!string);
            return result.data;
        } catch (ConvException c) {
            throw new ParseException(this, "Number parse failed.", c);
        }
    }

    auto consumeList(size_t number, Type, bool expectNewline, bool seperator = false)() {
        Type[number] result;
        size_t listLine = line;
        foreach (i; 0 .. number) {
            if (line != listLine || index == data.length)
                throw new Parser.ParseException(this,
                    "List of length " ~ number.to!string ~ " expected but reached end of line/file after element #" ~ i
                        .to!string);
            result[i] = consumeNumber!Type();
            static if (seperator) {
                if (i == number = 1)
                    continue;
                if (index == data.length || data[index] != ',')
                    throw new Parser.ParseException(this, "List expected with ',' seperator after element #" ~ (i + 1)
                            .to!string);
            }
        }
        static if (expectNewline) {
            if (line == listLine && index == data.length)
                throw new Parser.ParseException(this, "Expected end of line at index " ~ index
                        .to!string);
        }
        return result;
    }

    string currentLine() {
        size_t start = index;
        size_t end = index;
        if (data.length == 0)
            return "";
        while (start > 0) {
            if (data[start - 1] == '\n')
                break;
            start -= 1;
        }
        while (end < data.length) {
            if (data[end] == '\n')
                break;
            end += 1;
        }
        return data[start .. end];
    }

    class ParseException : Exception {
        this(ref Parser parser, string msg) {
            super(
                msg ~ "\nfile:" ~ parser.path ~ " line(" ~ parser.line.to!string ~ "):" ~ parser.currentLine());
        }

        this(ref Parser parser, string msg, Throwable nexInChain) {
            super(msg ~ "\nfile:" ~ parser.path ~ " line(" ~ parser.line.to!string ~ "):" ~ parser.currentLine(), nexInChain);
        }
    }
}
