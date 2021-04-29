module hoekjed.verver;
import hoekjed;
import bindbc.opengl;
import std.conv;
import std.array : replace;

class Verver {
	static package Verver[] ververs;

	HoekVerver hoekV;
	SnipperVerver snipperV;
	protected uint verwijzing;

	@property static Verver voorbeeld() {
		static Verver voorbeeld;
		if (voorbeeld is null)
			voorbeeld = new Verver(new HoekVerver("source/hoekjed/voorbeeld.vert"),
					new SnipperVerver("source/hoekjed/voorbeeld.frag"));
		return voorbeeld;
	}

	static Verver huidig = null;
	final void gebruik() {
		if (huidig is this)
			return;
		glUseProgram(verwijzing);
		huidig = this;
	}

	this(HoekVerver hoekV, SnipperVerver snipperV) {
		this.hoekV = hoekV;
		this.snipperV = snipperV;
		this.verwijzing = glCreateProgram();
		glAttachShader(verwijzing, hoekV.verwijzing);
		glAttachShader(verwijzing, snipperV.verwijzing);
		glLinkProgram(verwijzing);

		int volbracht;
		glGetProgramiv(verwijzing, GL_LINK_STATUS, &volbracht);
		if (volbracht == 0) {
			import std.stdio : writeln;

			char[512] melding;
			glGetProgramInfoLog(verwijzing, 512, null, &melding[0]);
			writeln("Kon verver niet samenstellen:");
			writeln("\t" ~ melding.to!string);
			assert(false);
		}

		glUseProgram(verwijzing);

		Verver.ververs ~= this;
	}

	// PAS OP: alias this zorgt voor functie verwarring. S & S[] tijdelijk onbeschikbaar.
	// PAS OP: Vec! werkt nog niet agz DIP niet afgewerkt is. :(
	// void zetUniform(S)(string naam, S waarde) {
	// pragma(msg, "S -> S = " ~ S.stringof);
	// const int uniformplek = glGetUniformLocation(verwijzing, naam.ptr);
	// enum string soort = is(S == uint) ? "ui" : (is(S == int)
	// 			? "i" : (is(S == float) ? "f" : (is(S == double) ? "d" : "")));
	// static assert(soort != "", "Soort " ~ S ~ " niet ondersteund voor zetUniform.");
	// mixin("glUniform1" ~ soort ~ "(uniformplek, waarde);");
	// }

	// void zetUniform(S : T[], T)(string naam, S waarde) {
	// pragma(msg, "S: T[] -> S = " ~ S.stringof ~ " & T = " ~ T.stringof);/
	// const int uniformplek = glGetUniformLocation(verwijzing, naam.ptr);
	// enum string soort = is(T == uint) ? "ui" : (is(T == int)
	// 			? "i" : (is(T == float) ? "f" : (is(T == double) ? "d" : "")));
	// static assert(soort != "", "Soort " ~ S.stringof ~ " niet ondersteund voor zetUniform.");
	// mixin("glUniform1" ~ soort ~ "v(uniformplek, cast(uint) waarde.length, waarde.ptr);");
	// }

	void zetUniform(V : Mat!(L, 1, S), uint L, S)(string naam, V waarde)
			if (L >= 1 && L <= 4) { // zet Vec
		const int uniformplek = glGetUniformLocation(verwijzing, naam.ptr);
		if (uniformplek == -1)
			return;
		enum string waardes = "waarde.x" ~ (L == 1 ? "" : ",waarde.y" ~ (L == 2
					? "" : ",waarde.z" ~ (L == 3 ? "" : ",waarde.w")));
		enum string soort = is(S == uint) ? "ui" : (is(S == int)
					? "i" : (is(S == float) ? "f" : (is(S == double) ? "d" : "")));
		static assert(soort != "", "Soort " ~ S ~ " niet ondersteund voor zetUniform.");
		mixin("glUniform" ~ L.to!string ~ soort ~ "(uniformplek, " ~ waardes ~ ");");
	}

	void zetUniform(V : Mat!(L, 1, S)[], uint L, S)(string naam, V waarde)
			if (L >= 1 && L <= 4) { // zet Vec[]
		const int uniformplek = glGetUniformLocation(verwijzing, naam.ptr);
		if (uniformplek == -1)
			return;
		enum string soort = is(S == uint) ? "ui" : (is(S == int)
					? "i" : (is(S == float) ? "f" : (is(S == double) ? "d" : "")));
		static assert(soort != "", "Soort " ~ S ~ " niet ondersteund voor zetUniform.");
		mixin("glUniform" ~ L.to!string ~ soort
				~ "v(uniformplek, cast(uint) waarde.length, cast(" ~ S.stringof ~ "*) waarde.ptr);");
	}

	void zetUniform(V : Mat!(R, K, nauwkeurigheid), uint R, uint K)(string naam, V waarde)
			if (R > 1 && R <= 4 && K > 1 && K <= 4) { // Zet Mat
		const int uniformplek = glGetUniformLocation(verwijzing, naam.ptr);
		if (uniformplek == -1) {
			import std.stdio : writeln;

			char[512] melding;
			glGetProgramInfoLog(verwijzing, 512, null, &melding[0]);
			writeln("Kon Uniform niet zetten");
			writeln(melding.to!string);
			return;
		}

		mixin("glUniformMatrix" ~ (R == K ? K.to!string : (K.to!string ~ "x" ~ R.to!string)) ~ (
				is(nauwkeurigheid == float) ? "f" : "d") ~ "v(uniformplek, 1, true, waarde[0].ptr);");
		// mixin("glUniformMatrix" ~ R == K ? K.to!string
		// : (K.to!string ~ "x" ~ R.to!string) ~  is(nauwkeurigheid == float)
		// ? "f" : "d" ~ "v(uniformplek, 1, true, waarde.ptr");
	}

	void zetUniform(V : Mat!(R, K, nauwkeurigheid)[], uint R, uint K)(string naam, V waarde)
			if (R > 1 && R <= 4 && K > 1 && K <= 4) { // Zet Mat[]
		const int uniformplek = glGetUniformLocation(verwijzing, naam.ptr);
		mixin("glUniformMatrix" ~ (R == K ? K.to!string : (K.to!string ~ "x" ~ R.to!string)) ~ (
				is(nauwkeurigheid == float)
				? "f" : "d") ~ "v(uniformplek, waarde.length, true, waarde.ptr);");
	}

	// VOEG TOE: uniform buffer object (UBO)
}

alias HoekVerver = DeelVerver!GL_VERTEX_SHADER;
alias SnipperVerver = DeelVerver!GL_FRAGMENT_SHADER;

class DeelVerver(uint soort) {
	protected uint verwijzing;

	this(string bestand) {
		import std.file : readText;

		this.verwijzing = glCreateShader(soort);
		string bron = readText(bestand);
		bron = bron.replace("nauwkeurigheid", nauwkeurigheid.stringof);
		static if (is(nauwkeurigheid == double)) {
			bron = bron.replace(" vec", " dvec");
			bron = bron.replace(" mat", " dmat");
		}
		auto p = bron.ptr;
		glShaderSource(verwijzing, 1, &p, null);
		glCompileShader(verwijzing);

		int volbracht;
		glGetShaderiv(verwijzing, GL_COMPILE_STATUS, &volbracht);
		if (volbracht == 0) {
			import std.stdio : writeln;

			char[512] melding;
			glGetShaderInfoLog(verwijzing, 512, null, &melding[0]);
			writeln("Kon Verver \"" ~ bestand ~ "\" niet bouwen:");
			writeln("\t" ~ melding.to!string);
			assert(false);
		}
	}
}
