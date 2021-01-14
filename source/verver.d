module verver;
import bindbc.opengl;

class Verver {
	HoekVerver hoekV;
	SnipperVerver snipperV;
	protected uint verwijzing;

	this(HoekVerver hoekV, SnipperVerver snipperV) {
		this.hoekV = hoekV;
		this.snipperV = snipperV;
		this.verwijzing = glCreateProgram();
		glAttachShader(verwijzing, hoekV.verwijzing);
		glAttachShader(verwijzing, snipperV.verwijzing);
		glLinkProgram(verwijzing);
	}

	void gebruik() {
		glUseProgram(verwijzing);
	}

	// VOEG TOE: Uniformen
	// VOEG TOE: uniform buffer object (UBO)
}

alias HoekVerver = DeelVerver!GL_VERTEX_SHADER;
alias SnipperVerver = DeelVerver!GL_FRAGMENT_SHADER;

class DeelVerver(GLenum soort) {
	protected uint verwijzing;

	this(string bestand) {
		import std.file : readText;

		this.verwijzing = glCreateShader(soort);
		string bron = readText(bestand);
		auto p = bron.ptr;
		glShaderSource(verwijzing, 1, &p, null);
		glCompileShader(verwijzing);
	}
}
