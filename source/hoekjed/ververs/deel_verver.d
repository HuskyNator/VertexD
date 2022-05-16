module hoekjed.ververs.deel_verver;
import bindbc.opengl;
import hoekjed.kern.wiskunde : nauwkeurigheid;
import hoekjed.ververs;
import std.array : replace;
import std.conv : to;
import std.stdio : writeln;

alias HoekVerver = DeelVerver!GL_VERTEX_SHADER;
alias SnipperVerver = DeelVerver!GL_FRAGMENT_SHADER;

class DeelVerver(uint soort) {
	package uint verwijzing;

	static DeelVerver!(soort)[string] ververs;

	private string krijg_foutmelding() {
		int lengte;
		glGetShaderiv(this.verwijzing, GL_INFO_LOG_LENGTH, &lengte);
		char[] melding = new char[lengte];
		glGetShaderInfoLog(this.verwijzing, lengte, null, &melding[0]);
		return cast(string) melding.idup;
	}

	this(string bestand) {
		import std.file : exists, readText;

		this.verwijzing = glCreateShader(soort);
		writeln("Deelverver aangemaakt: " ~ verwijzing.to!string);
		string bron;
		if (exists(bestand)) // Gegeven bestand is een verwijzing naar een bestand met verfinhoud.
			bron = readText(bestand);
		else // Gegeven bestand is verfinhoud.
			bron = bestand;
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
		if (volbracht == 0)
			throw new VerverFout("Kon DeelVerver " ~ verwijzing.to!string ~ " niet bouwen:\n" ~ cast(
					string) krijg_foutmelding());

		this.ververs[bestand] = this;
	}

	~this() {
		import core.stdc.stdio : printf;

		glDeleteShader(verwijzing);
		printf("Deelverver verwijderd: %u\n", verwijzing);
	}
}
