module hoekjed.ververs.verver;

import bindbc.opengl;
import hoekjed.driehoeksnet.buffer;
import hoekjed.kern.wiskunde;
import hoekjed.ververs.deel_verver;
import std.array : replace;
import std.conv : to;
import std.stdio;

class VerverFout : Exception {
	this(string melding) {
		super("Fout in Verver:\n" ~ melding);
	}
}

class Verver {
	public struct BronPaar {
		string hoekV, snipperV;
	}

	static this() {
		vervangers["nauwkeurigheid"] = nauwkeurigheid.stringof;
		static if (is(nauwkeurigheid == double)) {
			static foreach (i; 2 .. 4) {
				vervangers["vec" ~ i.stringof] = " dvec" ~ i.stringof;
				vervangers["mat" ~ i.stringof] = " dmat" ~ i.stringof;
			}
		}
	}

	static string[string] vervangers; // zie DeelVerver#this(bestand)
	static Verver[BronPaar] ververs;
	static Verver huidig = null;

	HoekVerver hoekV;
	SnipperVerver snipperV;
	protected uint verwijzing;

	public static immutable Vec!4 plaatsvervangerkleur = Vec!4(
		[250.0 / 255.0, 176.0 / 255.0, 22.0 / 255.0, 1]
	);

	@property public static Verver plaatsvervanger() {
		static Verver voorbeeld;
		if (voorbeeld is null)
			voorbeeld = Verver.laad(kleur_hoekverver, kleur_snipperverver);
		voorbeeld.zetUniform("u_kleur", plaatsvervangerkleur);
		return voorbeeld;
	}

	final void gebruik() {
		if (huidig is this)
			return;
		glUseProgram(verwijzing);
		huidig = this;
	}

	@disable this();

	private this(HoekVerver hoekV, SnipperVerver snipperV) {
		this.hoekV = hoekV;
		this.snipperV = snipperV;
		this.verwijzing = glCreateProgram();
		glAttachShader(verwijzing, hoekV.verwijzing);
		glAttachShader(verwijzing, snipperV.verwijzing);
		glLinkProgram(verwijzing);

		writeln("Verver aangemaakt: " ~ verwijzing.to!string ~ " (" ~ hoekV.verwijzing.to!string ~ "," ~ snipperV
				.verwijzing.to!string ~ ")");

		int volbracht;
		glGetProgramiv(verwijzing, GL_LINK_STATUS, &volbracht);
		if (volbracht == 0)
			throw new VerverFout(
				"Kon Verver " ~ verwijzing.to!string ~ " niet samenstellen:\n" ~ krijg_foutmelding());
	}

	~this() {
		import core.stdc.stdio : printf;

		glDeleteProgram(verwijzing);
		printf("Verver verwijderd: %u (%u, %u)\n", verwijzing, hoekV.verwijzing, snipperV
				.verwijzing);
	}

	/// Laadt Ververs met gegeven verversbestanden. Hergebruikt (deel)ververs indien mogelijk.
	public static Verver laad(string hoekV, string snipperV, bool* nieuw = null) {
		Verver verver = Verver.ververs.get(BronPaar(hoekV, snipperV), null);
		if (nieuw !is null)
			*nieuw = verver is null;
		if (verver is null) {
			HoekVerver hV = HoekVerver.ververs.get(hoekV, new HoekVerver(hoekV));
			SnipperVerver sV = SnipperVerver.ververs.get(snipperV, new SnipperVerver(snipperV));
			verver = new Verver(hV, sV);
			Verver.ververs[BronPaar(hoekV, snipperV)] = verver;
		}
		return verver;
	}

	static void zetUniformBuffer(int index, Buffer buffer) {
		glBindBufferBase(GL_UNIFORM_BUFFER, index, buffer.buffer);
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

		mixin("glProgramUniformMatrix" ~ (R == K ? K.to!string
				: (K.to!string ~ "x" ~ R.to!string)) ~ (
				is(nauwkeurigheid == float) ? "f" : "d") ~ "v(verwijzing, uniformplek, 1, true, waarde[0].ptr);");
	}

	void zetUniform(V : Mat!(R, K, nauwkeurigheid)[], uint R, uint K)(string naam, V waarde)
			if (R > 1 && R <= 4 && K > 1 && K <= 4) { // Zet Mat[]
		const int uniformplek = glGetUniformLocation(verwijzing, naam.ptr);
		if (uniformplek == -1)
			return foutmelding_ontbrekende_uniform(naam);

		mixin("glProgramUniformMatrix" ~ (R == K ? K.to!string
				: (K.to!string ~ "x" ~ R.to!string)) ~ (
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
		writeln(
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
uniform mat4 voorwerpM;

out vec4 gl_Position;

void main(){
	gl_Position = projectieM * zichtM * voorwerpM * vec4(h_plek, 1.0);
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
