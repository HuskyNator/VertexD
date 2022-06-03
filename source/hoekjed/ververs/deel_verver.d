module hoekjed.ververs.deel_verver;
import bindbc.opengl;
import hoekjed.kern.wiskunde : nauwkeurigheid;
import hoekjed.ververs;
import std.regex;
import std.conv : to;
import std.stdio : writeln;

alias HoekVerver = DeelVerver!GL_VERTEX_SHADER;
alias SnipperVerver = DeelVerver!GL_FRAGMENT_SHADER;

class DeelVerver(uint soort)
		if (soort == GL_VERTEX_SHADER || soort == GL_FRAGMENT_SHADER) {
	package uint verwijzing;

	static DeelVerver!(soort)[string] ververs;

	private string krijg_foutmelding() {
		int lengte;
		glGetShaderiv(this.verwijzing, GL_INFO_LOG_LENGTH, &lengte);
		if (lengte == 0)
			return "";
		char[] melding = new char[lengte];
		glGetShaderInfoLog(this.verwijzing, lengte, null, &melding[0]);
		return cast(string) melding.idup;
	}

	this(string bron) {
		this.verwijzing = glCreateShader(soort);
		writeln("Deelverver(" ~ (soort == GL_VERTEX_SHADER ? "HoekVerver" : "SnipperVerver") ~
				") aangemaakt: " ~ verwijzing.to!string);
		writeln(bron);

		auto p = bron.ptr;
		int l = cast(int) bron.length;
		glShaderSource(verwijzing, 1, &p, &l);
		glCompileShader(verwijzing);

		int volbracht;
		glGetShaderiv(verwijzing, GL_COMPILE_STATUS, &volbracht);
		if (volbracht == 0)
			throw new VerverFout(
				"Kon DeelVerver " ~ verwijzing.to!string ~ " niet bouwen:\n" ~ krijg_foutmelding());
		else
			writeln("Foutmelding log: " ~ krijg_foutmelding());

		this.ververs[bron] = this;
	}

	~this() {
		import core.stdc.stdio : printf;

		glDeleteShader(verwijzing);
		printf("Deelverver verwijderd: %u\n", verwijzing);
	}
}
