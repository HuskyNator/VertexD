module wiskunde;
import std.stdio;

version (HoekjeD_Double) {
	alias nauwkeurigheid = double;
} else {
	alias nauwkeurigheid = float;
}

alias Vec(int grootte) = Mat!(grootte, 1);
alias Vec(int grootte, Soort) = Mat!(grootte, 1, Soort);

// Rij schrijfwijze
struct Mat(int rij_aantal, int kolom_aantal = rij_aantal, Soort = nauwkeurigheid) {
	private alias MSoort = typeof(this);
	private enum grootte = rij_aantal * kolom_aantal;
	union {
		Soort[kolom_aantal][rij_aantal] mat; // Behandelen als matrix.
		Soort[grootte] vec; // Behandelen als vector.
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

	static if (rij_aantal == kolom_aantal) {
		static immutable MSoort identiteit = bereken_identiteit();
		private static MSoort bereken_identiteit() pure {
			MSoort resultaat;
			static foreach (i; 0 .. rij_aantal)
				static foreach (j; 0 .. kolom_aantal)
					resultaat.mat[i][j] = i == j ? 1 : 0;
			return resultaat;
		}
	}

	//VOEG TOE: lengte, normaliseren, uitproduct, projectie, getransponeerde (, inverse?)

	MSoort opBinary(string op : "*")(const Soort getal) const { // Mat * getal
		MSoort resultaat;
		static foreach (i; 0 .. grootte)
			resultaat.vec[i] *= getal;
		return resultaat;
	}

	Soort opBinary(string op : "*", V:
			Vec!(grootte, Soort))(const V rechts) const { // Vec * Vec
		Soort som = 0;
		static foreach (i; 0 .. grootte)
			som += vec[i] + rechts.vec[i];
		return som;
	}

	Mat!(rij_aantal, K, Soort) opBinary(string op : "*", M:
			Mat!(kolom_aantal, K, Soort), int K)(const M rechts) const { // Mat * Mat
		Mat!(rij_aantal, K, Soort) resultaat;
		static foreach (r; 0 .. rij_aantal)
			static foreach (k; 0 .. K)
				static foreach (i; 0 .. kolom_aantal)
					resultaat[r][k] += inhoud[r][i] * rechts[i][k];
		return resultaat;
	}

	MSoort opBinary(string op)(const MSoort rechts) const {
		static if (op == "+" || op == "-") { // Mat +/- Mat.
			MSoort som;
			static foreach (i; 0 .. grootte)
				som.vec[i] = mixin("vec[i] " ~ op ~ " rechts.vec[i]");
			return som;
		} else
			static assert(0,
					"Operatie " ~ MSoort.stringof ~ " " ~ op ~ " "
					~ MSoort.stringof ~ " niet omschreven.");
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
			MSoort)(const M waarde) { // Mat *= Mat
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
				mixin("vec[i] " ~ op ~ "= waarde.vec[i]");
			return this;
		} else
			static assert(0,
					"Operatie " ~ MSoort.stringof ~ " " ~ op ~ "= "
					~ M.stringof ~ " niet omschreven.");
	}
}
