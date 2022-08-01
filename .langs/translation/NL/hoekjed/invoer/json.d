module hoekjed.invoer.json;
import hoekjed.kern.mat;
import std.algorithm: canFind
import std.conv : to;
import std.exception : enforce;
import std.stdio;
import std.uni;

alias Json = JsonVal[string];

enum JsonSoort {
	VOORWERP,
	LIJST,
	STRING,
	DOUBLE,
	LONG,
	BOOL,
	NULL
}

struct JsonVal {
	JsonSoort soort;
	union {
		Json voorwerp;
		JsonVal[] lijst;
		string string_;
		double double_;
		long long_;
		bool bool_;
	}

	this(bool b) {
		this.soort = JsonSoort.BOOL;
		this.bool_ = b;
	}

	this(long l) {
		this.soort = JsonSoort.LONG;
		this.long_ = l;
	}

	this(double d) {
		this.soort = JsonSoort.DOUBLE;
		this.double_ = d;
	}

	this(string s) {
		this.soort = JsonSoort.STRING;
		this.string_ = s;
	}

	this(JsonVal[] lijst) {
		this.soort = JsonSoort.LIJST;
		this.lijst = lijst;
	}

	this(Json voorwerp) {
		this.soort = JsonSoort.VOORWERP;
		this.voorwerp = voorwerp;
	}

	static JsonVal NULL() {
		JsonVal v;
		v.soort = JsonSoort.NULL;
		v.voorwerp = null; //?
		return v;
	}

	Vec!(L, S) vec(uint L, S)() {
		enforce(soort == JsonSoort.LIJST, "Soort moet lijst zijn.");
		enforce(L == lijst.length, "Verwachtte lijst van lengte " ~ L.to!string ~
				" maar kreeg " ~ lijst.length.to!string);
		import std.traits;

		Vec!(L, S) v;
		static if (isBoolean!S) {
			enum onderdeel = "bool_";
		} else static if (isFloatingPoint!S) {
			enum onderdeel = "double_";
		} else static if (isIntegral!S) {
			enum onderdeel = "long_";
		} else static if (isSomeChar!S || isSomeString!S) {
			enum onderdeel = "string_";
		} else
			static assert(0, "Kan geen vector lezen van soort " ~ S.stringof);

		foreach (i; 0 .. L)
			v[i] = mixin("lijst[i].", onderdeel, ".to!S");
		return v;
	}

	unittest {
		JsonVal j = JsonVal([JsonVal(true), JsonVal(false)]);
		assert(j.vec!(2, bool) == Vec!(2, bool)([true, false]));
	}
}

/// Gemaakt zonder kennis van std.json.
class JsonLezer {
	private string inhoud;
	private size_t p = 0;
	private char c; //TODO Mogelijk template
	private uint regel; // Voor debugging.

	static Json leesJson(string bron) {
		JsonLezer lezer = new JsonLezer();
		lezer.inhoud = bron;
		return lezer.lees();
	}

	static Json leesJsonBestand(string bestand) {
		import std.file : readText;

		JsonLezer lezer = new JsonLezer();
		lezer.inhoud = readText(bestand);
		return lezer.lees();
	}

private:
	void stap() {
		enforce(p < inhoud.length, "Vroegtijdig einde van invoer op regel " ~ regel.to!string);
		this.c = inhoud[p];
		p += 1;
		if (c == '\n')
			regel += 1;
	}

	void stapTerug() {
		assert(p > 0);
		if (c == '\n')
			regel -= 1;
		p -= 1;
		this.c = inhoud[p - 1];
	}

	void stapw() {
		stap();
		witruimte();
	}

	bool eind() {
		return p == inhoud.length;
	}

	void eis(char verwacht)() {
		enforce(c == verwacht, "Verwachtte '" ~ verwacht ~ "' maar vond '" ~ c ~ "' op regel " ~ regel
				.to!string);
	}

	static char[] witruimte_karakters = [
		' ', '\n', '\r', '\t'
	];
	void witruimte() {
		while (witruimte_karakters.canFind(c) && !eind()) {
			stap();
		}
	}

	bool isHex(char c) {
		return isNumber(c) || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');
	}

	Json lees() {
		enforce(inhoud.length >= 2, "Json foutief");
		stapw();
		Json json = leesVoorwerp();
		if (!eind())
			stapw();
		enforce(eind(), "Einde van tekst verwacht op regel " ~ regel
				.to!string);
		return json;
	}

	Json leesVoorwerp() {
		eis!'{';
		Json json;
		stapw();
		if (c == '}')
			return json;
		goto begin;
		while (c == ',') {
			stapw();
		begin:
			string s = leesString();
			stapw();
			eis!':';
			stapw();
			JsonVal v = leesVal();
			json[s] = v;
			stapw();
		}

		eis!'}';
		return json;
	}

	JsonVal[] leesLijst() {
		eis!'[';
		JsonVal[] lijst = [
		];
		stapw();
		if (c == ']')
			return lijst;
		goto begin;

		do {
			stapw();
		begin:
			JsonVal v = leesVal();
			lijst ~= v;
			stapw();
		}
		while (c == ',');
		eis!']';
		return lijst;
	}

	static char[] string_karakters = [
		'"', '\\', '/', 'b',
		'f', 'n', 'r', 't'
	];
	string leesString() {
		eis!'"';
		size_t p_begin = p;
		stap();
		while (c != '"') {
			if (c == '\\') {
				stap();
				if (c == 'u') {
					static foreach (_; 0 .. 4) {
						stap();
						enforce(isHex(c), "Verwachtte hexadecimaal getal maar kreeg " ~ c ~ " op regel " ~ regel
								.to!string);
					}
				} else {
					enforce(string_karakters.canFind(c), "Illegaal karakter in string " ~ c ~ " op regel " ~ regel
							.to!string);
				}
			} else {
				enforce(!isControl(c), "Controle karakter in string op regel " ~ regel
						.to!string);
			}
			stap();
		}
		return inhoud[p_begin .. (p - 1)]
			.idup;
	}

	JsonVal leesGetal() {
		size_t p_begin = p;

		bool isFloat = false;
		if (c == '-')
			stap();

		if (c >= '1' && c <= '9') {
			stap();
			while (
				isNumber(c))
				stap();
		} else {
			enforce(c == '0', "Verwachtte cijfer maar kreeg '" ~ c ~ "' op regel " ~ regel
					.to!string);
			stap();
		}

		if (c == '.') {
			isFloat = true;
			stap();
			enforce(isNumber(c), "Verwachtte cijfer maar kreeg '" ~ c ~ "' op regel " ~ regel
					.to!string);
			stap();
			while (isNumber(c))
				stap();
		}

		if (c == 'e' || c == 'E') {
			stap();
			if (c == '-' || c == '+')
				stap();
			enforce(isNumber(c), "Verwachtte cijfer maar kreeg " ~ c ~ "' op regel " ~ regel
					.to!string);
			stap();
			while (isNumber(c))
				stap();
		}

		stapTerug();

		JsonVal j;
		j.soort = isFloat ? JsonSoort.DOUBLE : JsonSoort.LONG;
		if (isFloat)
			j.double_ = inhoud[p_begin - 1 .. p]
				.to!double;
		else
			j.long_ = inhoud[p_begin - 1 .. p]
				.to!long;
		return j;
	}

	void lees(string s)() {
		static foreach (char c; s[0 .. $ - 1]) {
			eis!c;
			stap();
		}
		eis!(s[$ - 1]);
	}

	bool leesBool() {
		if (c == 't') {
			lees!"true";
			return true;
		} else {
			lees!"false";
			return false;
		}
	}

	JsonVal leesVal() {
		switch (c) {
		case '{':
			JsonVal j = JsonVal(
				leesVoorwerp());
			return j;
		case '[':
			JsonVal j = JsonVal(
				leesLijst());
			return j;
		case 't', 'f':
			JsonVal j = JsonVal(
				leesBool());
			return j;
		case 'n':
			JsonVal j = JsonVal.NULL();
			lees!"null";
			return j;
		case '"':
			JsonVal j = JsonVal(
				leesString());
			return j;
		default:
			// Laatste mogelijkheid
			return leesGetal();
		}
	}
}

unittest {
	string json_string = `
	{
		"test": {
			"values": [
				"true",
				"false"
			]
		},
		"getal": 0,
		"getal2": 1.2e+20
	}`;
	Json json = JsonLezer.leesJson(json_string);
	assert("test" in json);
	JsonVal testval = json["test"];
	assert(
		testval.soort == JsonSoort
			.VOORWERP);
	Json test = testval
		.voorwerp;
	assert("values" in test);
	JsonVal vals = test["values"];
	assert(
		vals.soort == JsonSoort
			.LIJST);
	JsonVal[] lijst = vals
		.lijst;
	assert(lijst.length == 2);
	assert(
		lijst[0].soort == JsonSoort
			.BOOL);
	assert(
		lijst[0].bool_ == true);
	assert(
		lijst[1].soort == JsonSoort
			.BOOL);
	assert(
		lijst[1].bool_ == false);
	assert("getal" in json);
	JsonVal getal = json["getal"];
	assert(
		getal.soort == JsonSoort
			.LONG);
	long getal_i = getal
		.long_;
	assert(getal_i == 0);
	assert("getal2" in json);
	JsonVal getal2 = json["getal2"];
	assert(
		getal2.soort == JsonSoort
			.DOUBLE);
	double getal2_d = getal2
		.double_;
	assert(
		getal2_d == 1.2e+20);
}
