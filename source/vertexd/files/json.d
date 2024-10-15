module vertexd.files.json;

import vdmath.mat;
import std.algorithm : canFind;
import std.conv : to;
import std.exception : enforce;
import std.stdio;
import std.uni;
import std.traits : isPointer;

alias Json = JsonVal[string];

enum JsonType {
	OBJECT,
	LIST,
	STRING,
	DOUBLE,
	LONG,
	BOOL,
	NULL
}

struct JsonVal {
	JsonType type;
	union {
		Json object;
		JsonVal[] list;
		string string_;
		double double_;
		long long_;
		bool bool_;
	}

	this(bool b) {
		this.type = JsonType.BOOL;
		this.bool_ = b;
	}

	this(long l) {
		this.type = JsonType.LONG;
		this.long_ = l;
	}

	this(double d) {
		this.type = JsonType.DOUBLE;
		this.double_ = d;
	}

	this(string s) {
		this.type = JsonType.STRING;
		this.string_ = s;
	}

	this(JsonVal[] list) {
		this.type = JsonType.LIST;
		this.list = list;
	}

	this(Json object) {
		this.type = JsonType.OBJECT;
		this.object = object;
	}

	static JsonVal NULL() {
		JsonVal v;
		v.type = JsonType.NULL;
		v.object = null; //?
		return v;
	}

	T getType(T)() {
		final switch (type) {
			case JsonType.OBJECT:
				assert(0, "Cant `getType` of JsonType.OBJECT");
			case JsonType.LIST:
				assert(0, "Cant `getType` of JsonType.LIST, use `vec` instead");
			case JsonType.STRING:
				return string_.to!T;
			case JsonType.DOUBLE:
				return double_.to!T;
			case JsonType.LONG:
				return long_.to!T;
			case JsonType.BOOL:
				return bool_.to!T;
			case JsonType.NULL:
				static if (isPointer!T || is(T == class))
					return null;
				else
					assert(0, "Cant `getType` of JsonType.NULL on nonPointer/Class type " ~ T
							.stringof);
		}
	}

	Vec!(L, S) vec(uint L, S)() {
		enforce(type == JsonType.LIST, "Type must be list");
		enforce(L == list.length, "Expected list of length " ~ L.to!string ~ " but got " ~ list
				.length.to!string);
		import std.traits;

		Vec!(L, S) v;
		static if (isBoolean!S) {
			enum element = "bool_";
		} else static if (isFloatingPoint!S) {
			enum element = "double_";
		} else static if (isIntegral!S) {
			enum element = "long_";
		} else static if (isSomeChar!S || isSomeString!S) {
			enum element = "string_";
		} else
			static assert(0, "Cant read vector of type " ~ S.stringof);

		foreach (i; 0 .. L)
			v[i] = mixin("list[i].", element, ".to!S");
		return v;
	}

	unittest {
		JsonVal j = JsonVal([JsonVal(true), JsonVal(false)]);
		assert(j.vec!(2, bool) == Vec!(2, bool)([true, false]));
	}
}

/// Created without knowing about std.json
class JsonReader {
	private string content;
	private size_t p = 0;
	private char c; //TODO Potential template
	private uint line; // For debugging.

	static Json readJson(string source) {
		JsonReader reader = new JsonReader();
		reader.content = source;
		return reader.read();
	}

	static Json readJsonFile(string file) {
		import std.file : readText;

		JsonReader reader = new JsonReader();
		reader.content = readText(file);
		return reader.read();
	}

private:
	void step() {
		enforce(p < content.length, "Premature end of input on line" ~ line.to!string);
		this.c = content[p];
		p += 1;
		if (c == '\n')
			line += 1;
	}

	void stepBack() {
		assert(p > 0);
		if (c == '\n')
			line -= 1;
		p -= 1;
		this.c = content[p - 1];
	}

	void stepw() {
		step();
		whitespace();
	}

	bool end() {
		return p == content.length;
	}

	void require(char expected)() {
		enforce(c == expected, "Expected '" ~ expected ~ "' but found '" ~ c ~ "' on line " ~ line
				.to!string);
	}

	static char[] whitespace_characters = [' ', '\n', '\r', '\t'];
	void whitespace() {
		while (whitespace_characters.canFind(c) && !end()) {
			step();
		}
	}

	bool isHex(char c) {
		return isNumber(c) || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');
	}

	Json read() {
		enforce(content.length >= 2, "Json incorrect");
		stepw();
		Json json = readobject();
		if (!end())
			stepw();
		enforce(end(), "End of text expected on line " ~ line.to!string);
		return json;
	}

	Json readobject() {
		require!'{';
		Json json;
		stepw();
		if (c == '}')
			return json;
		goto beginning;
		while (c == ',') {
			stepw();
		beginning:
			string s = readString();
			stepw();
			require!':';
			stepw();
			JsonVal v = readVal();
			json[s] = v;
			stepw();
		}

		require!'}';
		return json;
	}

	JsonVal[] readList() {
		require!'[';
		JsonVal[] list = [];
		stepw();
		if (c == ']')
			return list;
		goto beginning;

		do {
			stepw();
		beginning:
			JsonVal v = readVal();
			list ~= v;
			stepw();
		}
		while (c == ',');
		require!']';
		return list;
	}

	static char[] string_characters = ['"', '\\', '/', 'b', 'f', 'n', 'r', 't'];
	string readString() {
		require!'"';
		size_t p_start = p;
		step();
		while (c != '"') {
			if (c == '\\') {
				step();
				if (c == 'u') {
					static foreach (_; 0 .. 4) {
						step();
						enforce(isHex(c), "Expected hecadecimal number but got " ~ c ~ " on line " ~ line
								.to!string);
					}
				} else {
					enforce(string_characters.canFind(c),
						"Illegal character in string " ~ c ~ " on line " ~ line.to!string);
				}
			} else {
				enforce(!isControl(c), "Control character in string on line " ~ line.to!string);
			}
			step();
		}
		return content[p_start .. (p - 1)].idup;
	}

	JsonVal readNumber() {
		size_t p_start = p;

		bool isFloat = false;
		if (c == '-')
			step();

		if (c >= '1' && c <= '9') {
			step();
			while (isNumber(c))
				step();
		} else {
			enforce(c == '0', "Expected number but got '" ~ c ~ "' on line " ~ line.to!string);
			step();
		}

		if (c == '.') {
			isFloat = true;
			step();
			enforce(isNumber(c), "Expected number but got '" ~ c ~ "' on line " ~ line.to!string);
			step();
			while (isNumber(c))
				step();
		}

		if (c == 'e' || c == 'E') {
			step();
			if (c == '-' || c == '+')
				step();
			enforce(isNumber(c), "Expected number but got " ~ c ~ "' on line " ~ line.to!string);
			step();
			while (isNumber(c))
				step();
		}

		stepBack();

		JsonVal j;
		j.type = isFloat ? JsonType.DOUBLE : JsonType.LONG;
		if (isFloat)
			j.double_ = content[p_start - 1 .. p].to!double;
		else
			j.long_ = content[p_start - 1 .. p].to!long;
		return j;
	}

	void read(string s)() {
		static foreach (char c; s[0 .. $ - 1]) {
			require!c;
			step();
		}
		require!(s[$ - 1]);
	}

	bool readBool() {
		if (c == 't') {
			read!"true";
			return true;
		} else {
			read!"false";
			return false;
		}
	}

	JsonVal readVal() {
		switch (c) {
			case '{':
				JsonVal j = JsonVal(readobject());
				return j;
			case '[':
				JsonVal j = JsonVal(readList());
				return j;
			case 't', 'f':
				JsonVal j = JsonVal(readBool());
				return j;
			case 'n':
				JsonVal j = JsonVal.NULL();
				read!"null";
				return j;
			case '"':
				JsonVal j = JsonVal(readString());
				return j;
			default:
				// Last possibility
				return readNumber();
		}
	}
}

unittest {
	string json_string = `
	{
		"test": {
			"values": [
				true,
				false
			]
		},
		"number": 0,
		"number2": 1.2e+20
	}`;
	Json json = JsonReader.readJson(json_string);
	assert("test" in json);
	JsonVal testval = json["test"];
	assert(testval.type == JsonType.OBJECT);
	Json test = testval.object;
	assert("values" in test);
	JsonVal vals = test["values"];
	assert(vals.type == JsonType.LIST);
	JsonVal[] list = vals.list;
	assert(list.length == 2);
	assert(list[0].type == JsonType.BOOL);
	assert(list[0].bool_ == true);
	assert(list[1].type == JsonType.BOOL);
	assert(list[1].bool_ == false);
	assert("number" in json);
	JsonVal number = json["number"];
	assert(number.type == JsonType.LONG);
	long number_i = number.long_;
	assert(number_i == 0);
	assert("number2" in json);
	JsonVal number2 = json["number2"];
	assert(number2.type == JsonType.DOUBLE);
	double number2_d = number2.double_;
	assert(number2_d == 1.2e+20);

}

unittest {
	string json_string = `
	{"perspective" : {
                "aspectRatio" : 1.7777777777777777,
                "yfov" : 0.39959652046304894,
                "zfar" : 100,
                "znear" : 0.10000000149011612
            }
	}`;
	Json json = JsonReader.readJson(json_string);
	assert("perspective" in json);
	JsonVal perspectiveVal = json["perspective"];
	assert(perspectiveVal.type == JsonType.OBJECT);
	Json perspectiveObj = perspectiveVal.object;

	assert("aspectRatio" in perspectiveObj);
	assert(perspectiveObj["aspectRatio"].type == JsonType.DOUBLE);
	assert(perspectiveObj["aspectRatio"].double_ == 1.7777777777777777);
	assert("yfov" in perspectiveObj);
	assert(perspectiveObj["yfov"].type == JsonType.DOUBLE);
	assert(perspectiveObj["yfov"].double_ == 0.39959652046304894);
	assert("zfar" in perspectiveObj);
	assert(perspectiveObj["zfar"].type == JsonType.LONG);
	assert(perspectiveObj["zfar"].long_ == 100);
	assert("znear" in perspectiveObj);
	assert(perspectiveObj["znear"].type == JsonType.DOUBLE);
	assert(perspectiveObj["znear"].double_ == 0.10000000149011612);
}
