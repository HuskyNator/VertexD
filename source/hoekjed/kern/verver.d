module hoekjed.kern.verver;
import bindbc.opengl;
import hoekjed.kern;
import std.array : replace;
import std.conv;

class VerverFout : Exception {
	this(string melding) {
		super("Fout in Verver:\n" ~ melding);
	}
}

class Verver {
	public struct BronPaar{
		string hoekV, snipperV;
	}

	public static Verver[BronPaar] ververs;
	static Verver huidig = null;

	HoekVerver hoekV;
	SnipperVerver snipperV;
	protected uint verwijzing;

	public static immutable Vec!4 plaatsvervangerkleur = {
		[250.0 / 255.0, 176.0 / 255.0, 22.0 / 255.0, 1]
	};

	@property public static Verver plaatsvervanger() {
		static Verver voorbeeld;
		if (voorbeeld is null)
			voorbeeld = Verver.laad(kleur_hoekverver, kleur_snipperverver);
		voorbeeld.zetUniform("kleur", plaatsvervangerkleur);
		return voorbeeld;
	}

	final void gebruik() {
		if (huidig is this)
			return;
		glUseProgram(verwijzing);
		huidig = this;
	}

	private this(){}

	private this(HoekVerver hoekV, SnipperVerver snipperV) {
		this.hoekV = hoekV;
		this.snipperV = snipperV;
		this.verwijzing = glCreateProgram();
		glAttachShader(verwijzing, hoekV.verwijzing);
		glAttachShader(verwijzing, snipperV.verwijzing);
		glLinkProgram(verwijzing);

		int volbracht;
		glGetProgramiv(verwijzing, GL_LINK_STATUS, &volbracht);
		if (volbracht == 0)
			throw new VerverFout(
					"Kon Verver " ~ verwijzing.to!string ~ " niet samenstellen:\n" ~ krijg_foutmelding());
	}

	/// Laadt Ververs met gegeven verversbestanden. Hergebruikt (deel)ververs indien mogelijk.
	public static Verver laad(string hoekV, string snipperV){
		Verver verver = Verver.ververs.get(BronPaar(hoekV, snipperV), null);
		if(verver is null){
			HoekVerver hV = HoekVerver.ververs.get(hoekV, new HoekVerver(hoekV));
			SnipperVerver sV = SnipperVerver.ververs.get(snipperV, new SnipperVerver(snipperV));
			verver = new Verver(hV, sV);
			Verver.ververs[BronPaar(hoekV, snipperV)] = verver;
		}
		return verver;
	}

	void zetUniform(Zicht zicht) {
		this.zetUniform("projectieM", zicht.projectieM);
		this.zetUniform("zichtM", zicht.zichtM);
	}

	void zetUniform(V : Mat!(L, 1, S), uint L, S)(string naam, V waarde)
			if (L >= 1 && L <= 4) { // zet Vec
		const int uniformplek = glGetUniformLocation(verwijzing, naam.ptr);
		if (uniformplek == -1)
			return foutmelding_ontbrekende_uniform(naam);

		enum string waardes = "waarde.x" ~ (L == 1 ? "" : ",waarde.y" ~ (L == 2
					? "" : ",waarde.z" ~ (L == 3 ? "" : ",waarde.w")));
		enum string soort = is(S == uint) ? "ui" : (is(S == int)
					? "i" : (is(S == float) ? "f" : (is(S == double) ? "d" : "")));
		static assert(soort != "", "Soort " ~ S ~ " niet ondersteund voor zetUniform.");
		mixin("glProgramUniform" ~ L.to!string ~ soort ~ "(verwijzing, uniformplek, " ~ waardes ~ ");");
	}

	void zetUniform(V : Mat!(L, 1, S)[], uint L, S)(string naam, V waarde)
			if (L >= 1 && L <= 4) { // zet Vec[]
		const int uniformplek = glGetUniformLocation(verwijzing, naam.ptr);
		if (uniformplek == -1)
			foutmelding_ontbrekende_uniform(naam);

		enum string soort = is(S == uint) ? "ui" : (is(S == int)
					? "i" : (is(S == float) ? "f" : (is(S == double) ? "d" : "")));
		static assert(soort != "", "Soort " ~ S ~ " niet ondersteund voor zetUniform.");
		mixin("glProgramUniform" ~ L.to!string ~ soort
				~ "v(verwijzing, uniformplek, cast(uint) waarde.length, cast(" ~ S.stringof ~ "*) waarde.ptr);");
	}

	void zetUniform(V : Mat!(R, K, nauwkeurigheid), uint R, uint K)(string naam, V waarde)
			if (R > 1 && R <= 4 && K > 1 && K <= 4) { // Zet Mat
		const int uniformplek = glGetUniformLocation(verwijzing, naam.ptr);
		if (uniformplek == -1)
			return foutmelding_ontbrekende_uniform(naam);

		mixin("glProgramUniformMatrix" ~ (R == K ? K.to!string : (K.to!string ~ "x" ~ R.to!string)) ~ (
				is(nauwkeurigheid == float) ? "f" : "d") ~ "v(verwijzing, uniformplek, 1, true, waarde[0].ptr);");
	}

	void zetUniform(V : Mat!(R, K, nauwkeurigheid)[], uint R, uint K)(string naam, V waarde)
			if (R > 1 && R <= 4 && K > 1 && K <= 4) { // Zet Mat[]
		const int uniformplek = glGetUniformLocation(verwijzing, naam.ptr);
		if (uniformplek == -1)
			return foutmelding_ontbrekende_uniform(naam);

		mixin("glProgramUniformMatrix" ~ (R == K ? K.to!string : (K.to!string ~ "x" ~ R.to!string)) ~ (
				is(nauwkeurigheid == float)
				? "f" : "d") ~ "v(verwijzing, uniformplek, waarde.length, true, waarde.ptr);");
	}

	private string krijg_foutmelding() {
		int lengte;
		glGetProgramiv(this.verwijzing, GL_INFO_LOG_LENGTH, &lengte);
		char[] melding = new char[lengte];
		glGetProgramInfoLog(this.verwijzing, lengte, null, melding.ptr);
		return cast(string) melding.idup;
	}

	private void foutmelding_ontbrekende_uniform(string naam) {
		import std.stdio;

		stderr.writeln(
				"Verver " ~ verwijzing.to!string ~ " kon uniform " ~ naam
				~ " niet vinden.\n" ~ krijg_foutmelding());
	}

	public static string kleur_hoekverver = `
#version 460

layout(location=0)in vec3 h_plek;
layout(location=1)in vec3 h_normaal;
layout(location=2)in vec2 h_beeldplek;

uniform mat4 projectieM;
uniform mat4 zichtM;
uniform mat4 tekenM;

out vec4 gl_Position;

void main(){
	gl_Position = projectieM * zichtM * tekenM * vec4(h_plek, 1.0);
}
`;

	public static string kleur_snipperverver = `
#version 460

uniform vec4 kleur;

out vec4 u_kleur;

void main(){
	u_kleur = kleur;
}
`;
}

alias HoekVerver = DeelVerver!GL_VERTEX_SHADER;
alias SnipperVerver = DeelVerver!GL_FRAGMENT_SHADER;

class DeelVerver(uint soort) {
	protected uint verwijzing;

	static DeelVerver!(soort)[string] ververs;

	private string krijg_foutmelding() {
		int lengte;
		glGetShaderiv(this.verwijzing, GL_INFO_LOG_LENGTH, &lengte);
		char[] melding = new char[lengte];
		glGetShaderInfoLog(this.verwijzing, lengte, null, &melding[0]);
		return cast(string) melding.idup;
	}

	this(string bestand) {
		import std.file : readText, exists;

		this.verwijzing = glCreateShader(soort);
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
}
