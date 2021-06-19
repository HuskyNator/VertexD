module hoekjed.kern.wiskunde;
import std.stdio;
import std.math : sin, cos, abs, pow;

version (HoekjeD_Double) {
	alias nauwkeurigheid = double;
} else {
	alias nauwkeurigheid = float;
}

alias Vec(uint grootte, Soort = nauwkeurigheid) = Mat!(grootte, 1, Soort);
alias Vec(Soort, uint grootte = 3) = Mat!(grootte, 1, Soort);
// alias Vec(uint grootte, Soort) = Mat!(grootte, 1, Soort);

// Rij schrijfwijze
struct Mat(uint rij_aantal, uint kolom_aantal = rij_aantal, Soort = nauwkeurigheid) {
	private alias MSoort = typeof(this);
	private enum uint grootte = rij_aantal * kolom_aantal;
	union {
		Soort[grootte] vec; // Behandelen als vector.
		Soort[kolom_aantal][rij_aantal] mat; // Behandelen als matrix.
		struct { // Werkt voor zowel kolom als rij vectoren.
			static if (grootte >= 1)
				Soort x;
			static if (grootte >= 2)
				Soort y;
			static if (grootte >= 3)
				Soort z;
			static if (grootte >= 4)
				Soort w;
		}
	}

	// Geeft indexeren & impliciete lijst omzetting.
	static if (kolom_aantal == 1)
		alias vec this;
	else
		alias mat this;

	import std.format : FormatSpec;
	import std.range : put;
	import std.conv : to;

	void toString(scope void delegate(const(char)[]) sink, FormatSpec!char fmt) const {
		sink.put("[");
		foreach (i; 0 .. rij_aantal - 1) {
			sink.put(mat[i].to!string);
			sink.put(",\n ");
		}
		if (rij_aantal > 0)
			sink.put(mat[rij_aantal - 1].to!string);
		sink.put("]");
	}

	static if (rij_aantal == kolom_aantal) {
		MSoort gekantelde() pure {
			MSoort resultaat;
			static foreach (i; 0 .. rij_aantal)
				static foreach (j; 0 .. kolom_aantal)
					resultaat.mat[i][j] = mat[j][i];
			return resultaat;
		}
	}

	static immutable MSoort nul = bereken_nul();
	private static MSoort bereken_nul() pure {
		MSoort resultaat;
		static foreach (i; 0 .. grootte)
			resultaat.vec[i] = 0;
		return resultaat;
	}

	static if (rij_aantal == kolom_aantal) {
		static immutable MSoort identiteit = bereken_identiteit();
		private static MSoort bereken_identiteit() pure {
			MSoort resultaat;
			static foreach (i; 0 .. rij_aantal)
				static foreach (j; 0 .. kolom_aantal)
					resultaat.vec[i + j * kolom_aantal] = (i == j ? 1 : 0);
			return resultaat;
		}
	}

	static Mat!(4, 4, nauwkeurigheid) draaiMx(nauwkeurigheid hoek) { // stampen
		Mat!(4, 4, nauwkeurigheid) draaiM = Mat!(4, 4, nauwkeurigheid).nul;
		nauwkeurigheid cos = cos(hoek);
		nauwkeurigheid sin = sin(hoek);
		draaiM[0][0] = 1;
		draaiM[1][1] = cos;
		draaiM[1][2] = -sin;
		draaiM[2][1] = sin;
		draaiM[2][2] = cos;
		draaiM[3][3] = 1;
		return draaiM;
	}

	static Mat!(4, 4, nauwkeurigheid) draaiMy(nauwkeurigheid hoek) { // gieren
		Mat!(4, 4, nauwkeurigheid) draaiM = Mat!(4, 4, nauwkeurigheid).nul;
		nauwkeurigheid cos = cos(hoek);
		nauwkeurigheid sin = sin(hoek);
		draaiM[0][0] = cos;
		draaiM[0][2] = sin;
		draaiM[1][1] = 1;
		draaiM[2][0] = -sin;
		draaiM[2][2] = cos;
		draaiM[3][3] = 1;
		return draaiM;
	}

	static Mat!(4, 4, nauwkeurigheid) draaiMz(nauwkeurigheid hoek) { // rollen
		Mat!(4, 4, nauwkeurigheid) draaiM = Mat!(4, 4, nauwkeurigheid).nul;
		nauwkeurigheid cos = cos(hoek);
		nauwkeurigheid sin = sin(hoek);
		draaiM[0][0] = cos;
		draaiM[0][1] = -sin;
		draaiM[1][0] = sin;
		draaiM[1][1] = cos;
		draaiM[2][2] = 1;
		draaiM[3][3] = 1;
		return draaiM;
	}

	//VOEG TOE: lengte, normaliseren, uitproduct, projectie, getransponeerde (, inverse?)

	static if (kolom_aantal == 1) {
		static if (rij_aantal == 3) {
			MSoort kruis(MSoort r) {
				MSoort n;
				n.vec[0] = this.vec[1] * r.vec[2] - r.vec[1] * this.vec[2];
				n.vec[1] = this.vec[2] * r.vec[0] - r.vec[2] * this.vec[0];
				n.vec[2] = this.vec[0] * r.vec[1] - r.vec[0] * this.vec[1];
				return n;
			}
		}

		nauwkeurigheid som() {
			nauwkeurigheid s = 0;
			static foreach (i; 0 .. rij_aantal)
				s += this.vec[i];
			return s;
		}

		static if (is(Soort == float) || is(Soort == double)) {
			nauwkeurigheid lengte() {
				nauwkeurigheid lengte = 0;
				static foreach (i; 0 .. rij_aantal)
					lengte += pow(this.vec[i], rij_aantal);
				lengte = pow!(nauwkeurigheid, nauwkeurigheid)(lengte, 1 / rij_aantal);
				return lengte;
			}

			MSoort normaliseer() {
				MSoort n = this;
				return n * cast(Soort)(1 / lengte());
			}
		}
	}

	// VEC:
	// .len
	// .norm
	// .in
	// .uit
	// .trans

	// *  / als onderdeelgewijs. Of nee toch niet. Kan mogelijk via [] operatie.

	MSoort opBinary(string op : "*")(const Soort getal) const { // Mat * getal
		MSoort resultaat;
		static foreach (i; 0 .. grootte)
			resultaat.vec[i] = vec[i] * getal;
		return resultaat;
	}

	MSoort opBinary(string op, V:
			Mat!(grootte, 1, S), S)(const V rechts) const if (op == "*" || op == "/") { // Vec *// Vec
		MSoort som = this;
		static foreach (i; 0 .. grootte)
			mixin("som.vec[i] " ~ op ~ "= rechts.vec[i];");
		return som;
	}

	Mat!(rij_aantal, K, Soort) opBinary(string op : "*", M:
			Mat!(kolom_aantal, K, Soort), int K)(const M rechts) const { // Mat * Mat
		Mat!(rij_aantal, K, Soort) resultaat = Mat!(rij_aantal, K, Soort).nul;
		static foreach (r; 0 .. rij_aantal)
			static foreach (k; 0 .. K)
				static foreach (i; 0 .. kolom_aantal) {
					resultaat.vec[r * K + k] += mat[r][i] * rechts.mat[i][k];
				}
		return resultaat;
	}

	MSoort opBinary(string op, M:
			Mat!(rij_aantal, kolom_aantal, S), S)(const M rechts) const 
			if (op == "+" || op == "-") { // Mat +/- Mat.
		MSoort som = this;
		static foreach (i; 0 .. grootte)
			mixin("som.vec[i]" ~ op ~ "= rechts.vec[i];");
		return som;
	}

	T opCast(T : Mat!(rij_aantal, kolom_aantal, S), S)() const { // cast(Mat<S>)Mat
		T omgezet;
		static foreach (i; 0 .. grootte)
			omgezet.vec[i] = cast(S) vec[i];
		return omgezet;
	}

	ref MSoort opOpAssign(string op : "*")(const Soort getal) { // Mat *= getal
		static foreach (i; 0 .. grootte)
			vec[i] *= getal;
		return this;
	}

	ref MSoort opOpAssign(string op : "*", M:
			MSoort)(const M waarde) { // Mat *= Mat Mogelijk niet handig.
		static foreach (r; 0 .. rij_aantal) {
			{
				Soort[kolom_aantal] som;
				static foreach (k; 0 .. kolom_aantal) {
					static foreach (i; 0 .. kolom_aantal)
						som[k] += mat[r][i] * waarde.mat[i][k];
				}
				this[r] = som;
			}
		}
		return this;
	}

	ref MSoort opOpAssign(string op, M:
			MSoort)(const M waarde) { // Mat +/-= Mat
		static if (op == "+" || op == "-") {
			static foreach (i; 0 .. grootte)
				mixin("vec[i] " ~ op ~ "= waarde.vec[i];");
			return this;
		} else
			static assert(0,
					"Operatie " ~ MSoort.stringof ~ " " ~ op ~ "= "
					~ M.stringof ~ " niet omschreven.");
	}
}

Vec!3 TEMP_draai(Vec!3 oorsprong, Vec!3 doel) {
	import std.math : acos, PI;

	//TODO: nulvector
	Vec!2 oorsprong_proj = (Vec!2([oorsprong.x, oorsprong.y])).normaliseer();
	real oorsprong_theta = oorsprong_proj.y > 0 ? acos(oorsprong_proj.x) : -acos(oorsprong_proj.x);
	Vec!2 doel_proj = (Vec!2([doel.x, doel.y])).normaliseer();
	real doel_theta = doel_proj.y > 0 ? acos(doel_proj.x) : -acos(doel_proj.x);
	real verschil_theta = doel_theta - oorsprong_theta;

	while (verschil_theta < 0)
		verschil_theta += 2 * PI;

	return Vec!3([0, 0, verschil_theta]);
}