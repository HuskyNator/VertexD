module hoekjed.kern.wiskunde;
import hoekjed.overig;
import std.exception : enforce;
import std.math : abs, cos, sin, sqrt;
import std.stdio;

alias nauw = nauwkeurigheid;
version (HoekjeD_Double) {
	alias nauwkeurigheid = double;
} else {
	alias nauwkeurigheid = float;
}

alias Vec(uint grootte = 3, Soort = nauwkeurigheid) = Mat!(grootte, 1, Soort);
alias Mat(uint aantal = 3, Soort = nauwkeurigheid) = Mat!(aantal, aantal, Soort);

struct Mat(uint rij_aantal, uint kolom_aantal, Soort = nauwkeurigheid)
		if (rij_aantal > 0 && kolom_aantal > 0) {
	enum uint grootte = rij_aantal * kolom_aantal;
	enum bool isVec = kolom_aantal == 1;
	enum bool isMat = !isVec;
	enum bool isVierkant = kolom_aantal == rij_aantal;

	alias MatSoort = typeof(this);

	union {
		Soort[grootte] vec = 0; // Standaard waarden zijn 0.
		Soort[kolom_aantal][rij_aantal] mat;
		static if (isVec) {
			struct {
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
	}

	this(Soort n) {
		static if (isVec)
			vec[] = n;
		else {
			static foreach (i; 0 .. rij_aantal)
				static foreach (j; 0 .. kolom_aantal)
					mat[i][j] = (i == j) ? n : 0;
		}
	}

	this(Soort[grootte] n) {
		this.vec = n;
	}

	this(Soort[] n) {
		enforce(n.length == grootte);
		this.vec = n;
	}

	this(Soort[kolom_aantal][rij_aantal] n) {
		this.mat = n;
	}

	static if (isVec)
		alias vec this;
	else
		alias mat this;

	void zetKol(uint k, Vec!(rij_aantal, Soort) kol) {
		assert(k < rij_aantal);
		foreach (i; 0 .. rij_aantal) {
			this.mat[k][i] = kol[i];
		}
	}

	Vec!rij_aantal kol(uint i) {
		Vec!rij_aantal k;
		foreach (r; 0 .. rij_aantal) {
			k.vec[r] = mat[r][i];
		}
		return k;
	}

	Mat!(1, kolom_aantal, Soort) rij(uint i) {
		return Mat!(1, kolom_aantal, Soort)([mat[i]]);
	}

	static if (isVierkant) {
		MatSoort inverse() {
			MatSoort inverse;
			Soort determinant;
			static if (rij_aantal == 2) {
				inverse[0][0] = mat[1][1];
				inverse[0][1] = -mat[1][0];
				inverse[1][0] = -mat[0][1];
				inverse[1][1] = mat[0][0];
				determinant = mat[0][0] * mat[1][1] - mat[0][1] * mat[1][0];
			} else static if (rij_aantal == 3) {
				// Bepaal geadjudeerde (getransponeerde cofactor matrix) matrix (2x2 determinanten maal een even index teken)
				inverse[0][0] = mat[1][1] * mat[2][2] - mat[1][2] * mat[2][1];
				inverse[0][1] = -(mat[0][1] * mat[2][2] - mat[0][2] * mat[2][1]);
				inverse[0][2] = mat[0][1] * mat[1][2] - mat[0][2] * mat[1][1];

				inverse[1][0] = -(mat[1][0] * mat[2][2] - mat[1][2] * mat[2][0]);
				inverse[1][1] = mat[0][0] * mat[2][2] - mat[0][2] * mat[2][0];
				inverse[1][2] = -(mat[0][0] * mat[1][2] - mat[0][2] * mat[1][0]);

				inverse[2][0] = mat[1][0] * mat[2][1] - mat[1][1] * mat[2][0];
				inverse[2][1] = -(mat[0][0] * mat[2][1] - mat[0][1] * mat[2][0]);
				inverse[2][2] = mat[0][0] * mat[1][1] - mat[0][1] * mat[1][0];

				determinant = mat[0][0] * inverse[0][0]
					+ mat[0][1] * inverse[1][0]
					+ mat[0][2] * inverse[2][0];
			} else static if (rij_aantal == 4) {
				// Bepaalt 2x2 determinanten van de onderste 3 rijen
				// Mij_kl verwijst naar linkerbovenhoekindex ij & rechteronderhoekindex kl
				Soort M10_21 = mat[1][0] * mat[2][1] - mat[1][1] * mat[2][0];
				Soort M10_31 = mat[1][0] * mat[3][1] - mat[1][1] * mat[3][0];
				Soort M20_31 = mat[2][0] * mat[3][1] - mat[2][1] * mat[3][0];

				Soort M10_22 = mat[1][0] * mat[2][2] - mat[1][2] * mat[2][0];
				Soort M10_32 = mat[1][0] * mat[3][2] - mat[1][2] * mat[3][0];
				Soort M20_32 = mat[2][0] * mat[3][2] - mat[2][2] * mat[3][0];

				Soort M10_23 = mat[1][0] * mat[2][3] - mat[1][3] * mat[2][0];
				Soort M10_33 = mat[1][0] * mat[3][3] - mat[1][3] * mat[3][0];
				Soort M20_33 = mat[2][0] * mat[3][3] - mat[2][3] * mat[3][0];

				Soort M11_22 = mat[1][1] * mat[2][2] - mat[1][2] * mat[2][1];
				Soort M11_32 = mat[1][1] * mat[3][2] - mat[1][2] * mat[3][1];
				Soort M21_32 = mat[2][1] * mat[3][2] - mat[2][2] * mat[3][1];

				Soort M11_23 = mat[1][1] * mat[2][3] - mat[1][3] * mat[2][1];
				Soort M11_33 = mat[1][1] * mat[3][3] - mat[1][3] * mat[3][1];
				Soort M21_33 = mat[2][1] * mat[3][3] - mat[2][3] * mat[3][1];

				Soort M12_23 = mat[1][2] * mat[2][3] - mat[1][3] * mat[2][2];
				Soort M12_33 = mat[1][2] * mat[3][3] - mat[1][3] * mat[3][2];
				Soort M22_33 = mat[2][2] * mat[3][3] - mat[2][3] * mat[3][2];

				// Bepaal geadjudeerde (getransponeerde cofactor) matrix (minoren maal een even index teken)
				// Dit door middel van een laplace expansie ter bepaling van de minor.
				inverse[0][0] = mat[1][1] * M22_33 - mat[1][2] * M21_33 + mat[1][3] * M21_32;
				inverse[0][1] = -(mat[0][1] * M22_33 - mat[0][2] * M21_33 + mat[0][3] * M21_32);
				inverse[0][2] = mat[0][1] * M12_33 - mat[0][2] * M11_33 + mat[0][3] * M11_32;
				inverse[0][3] = -(mat[0][1] * M12_23 - mat[0][2] * M11_23 + mat[0][3] * M11_22);

				inverse[1][0] = -(mat[1][0] * M22_33 - mat[1][2] * M20_33 + mat[1][3] * M20_32);
				inverse[1][1] = mat[0][0] * M22_33 - mat[0][2] * M20_33 + mat[0][3] * M20_32;
				inverse[1][2] = -(mat[0][0] * M12_33 - mat[0][2] * M10_33 + mat[0][3] * M10_32);
				inverse[1][3] = mat[0][0] * M12_23 - mat[0][2] * M10_23 + mat[0][3] * M10_22;

				inverse[2][0] = mat[1][0] * M21_33 - mat[1][1] * M20_33 + mat[1][3] * M20_31;
				inverse[2][1] = -(mat[0][0] * M21_33 - mat[0][1] * M20_33 + mat[0][3] * M20_31);
				inverse[2][2] = mat[0][0] * M11_33 - mat[0][1] * M10_33 + mat[0][3] * M10_31;
				inverse[2][3] = -(mat[0][0] * M11_23 - mat[0][1] * M10_23 + mat[0][3] * M10_21);

				inverse[3][0] = -(mat[1][0] * M21_32 - mat[1][1] * M20_32 + mat[1][2] * M20_31);
				inverse[3][1] = mat[0][0] * M21_32 - mat[0][1] * M20_32 + mat[0][2] * M20_31;
				inverse[3][2] = -(mat[0][0] * M11_32 - mat[0][1] * M10_32 + mat[0][2] * M10_31);
				inverse[3][3] = mat[0][0] * M11_22 - mat[0][1] * M10_22 + mat[0][2] * M10_21;

				// Bepaal determinant met de cofactoren.
				determinant = mat[0][0] * inverse[0][0]
					+ mat[0][1] * inverse[1][0]
					+ mat[0][2] * inverse[2][0]
					+ mat[0][3] * inverse[3][0];
			}

			enforce(determinant != 0, "Matrix niet inverteerbaar: determinant = 0");
			inverse = inverse / determinant;
			return inverse;
		}

		unittest {
			Mat!3 M = Mat!3([
					1, 0, 3, 4, 5, 6, 7, 8, 9
				]); // Determinant -12

			Mat!3 I = M.inverse().maal(M);
			Vec!3 i = Vec!3(1);
			assert(i.isOngeveer(I.maal(i)));
		}

		unittest {
			Mat!4 M = Mat!4([
				1, -2, 3, 4, 5, 6, 7, -8, 9, 10, 11, 12, 13, 14, 15, 16
			]); // Determinant 512
			Mat!4 I = M.inverse().maal(M);
			Vec!4 i = Vec!4(1);
			assert(i.isOngeveer(I.maal(i)));
		}

		static if (rij_aantal == 3 || rij_aantal == 4) {
			static {
				MatSoort draaiMx(nauwkeurigheid hoek) {
					MatSoort draaiM = MatSoort(1);
					nauwkeurigheid cos = cos(hoek);
					nauwkeurigheid sin = sin(hoek);
					draaiM[1][1] = cos;
					draaiM[1][2] = -sin;
					draaiM[2][1] = sin;
					draaiM[2][2] = cos;
					return draaiM;
				}

				unittest {
					import std.math : PI, PI_2;

					Mat!4 draai = Mat!(4).draaiMx(0);
					Mat!4 draai2 = Mat!4(1);
					assert(draai.isOngeveer(draai2));

					draai = Mat!(4).draaiMx(PI_2);
					draai2 = Mat!4();
					draai2[0][0] = 1;
					draai2[1][2] = -1;
					draai2[2][1] = 1;
					draai2[3][3] = 1;
					float delta = 1e-5;
					float verschil = (draai.elk(&abs!(float)) - draai2.elk(&abs!(float))).som();
					assert(verschil < delta);

					draai = Mat!(4).draaiMx(PI);
					draai2 = Mat!4(1);
					draai2[1][1] = -1;
					draai2[2][2] = -1;
					verschil = (draai.elk(&abs!(float)) - draai2.elk(&abs!(float))).som();
					assert(verschil < delta);
				}

				MatSoort draaiMy(nauwkeurigheid hoek) {
					MatSoort draaiM = MatSoort(1);
					nauwkeurigheid cos = cos(hoek);
					nauwkeurigheid sin = sin(hoek);
					draaiM[0][0] = cos;
					draaiM[0][2] = sin;
					draaiM[2][0] = -sin;
					draaiM[2][2] = cos;
					return draaiM;
				}

				unittest {
					import std.math : PI, PI_2;

					Mat!4 draai = Mat!(4).draaiMy(0);
					Mat!4 draai2 = Mat!4(1);
					assert(draai == draai2);

					draai = Mat!(4).draaiMy(PI_2);
					draai2 = Mat!4();
					draai2[0][2] = 1;
					draai2[1][1] = 1;
					draai2[2][0] = -1;
					draai2[3][3] = 1;
					float delta = 1e-5;
					float verschil = (draai.elk(&abs!(float)) - draai2.elk(&abs!(float))).som();
					assert(verschil < delta);

					draai = Mat!(4).draaiMy(PI);
					draai2 = Mat!4(1);
					draai2[0][0] = -1;
					draai2[2][2] = -1;
					verschil = (draai.elk(&abs!(float)) - draai2.elk(&abs!(float))).som();
					assert(verschil < delta);
				}

				MatSoort draaiMz(nauwkeurigheid hoek) {
					MatSoort draaiM = MatSoort(1);
					nauwkeurigheid cos = cos(hoek);
					nauwkeurigheid sin = sin(hoek);
					draaiM[0][0] = cos;
					draaiM[0][1] = -sin;
					draaiM[1][0] = sin;
					draaiM[1][1] = cos;
					return draaiM;
				}

				unittest {
					import std.math : PI, PI_2;

					Mat!4 draai = Mat!(4).draaiMz(0);
					Mat!4 draai2 = Mat!4(1);
					assert(draai == draai2);

					draai = Mat!(4).draaiMz(PI_2);
					draai2[0][0] = 0;
					draai2[0][1] = -1;
					draai2[1][0] = 1;
					draai2[1][1] = 0;
					float delta = 1e-5;
					float verschil = (draai.elk(&abs!(float)) - draai2.elk(&abs!(float))).som();
					assert(verschil < delta);

					draai = Mat!(4).draaiMz(PI);
					draai2 = Mat!4(1);
					draai2[0][0] = -1;
					draai2[1][1] = -1;
					verschil = (draai.elk(&abs!(float)) - draai2.elk(&abs!(float))).som();
					assert(verschil < delta);
				}
			}
		}
	}

	auto getransponeerde() const {
		Mat!(kolom_aantal, rij_aantal, Soort) resultaat;
		static foreach (i; 0 .. rij_aantal)
			static foreach (j; 0 .. kolom_aantal)
				resultaat.mat[j][i] = this.mat[i][j];
		return resultaat;
	}

	static if (isVec) {
		auto inp(Resultaat = Soort, R:
			Mat!(rij_aantal, 1, T), T)(const R rechts) const {
			Resultaat resultaat = 0;
			static foreach (i; 0 .. grootte)
				resultaat += this.vec[i] * rechts.vec[i];
			return resultaat;
		}

		static if (rij_aantal == 3) {
			auto uitp(R : Mat!(rij_aantal, 1, T), T)(const R rechts) const {
				Mat!(rij_aantal, 1, typeof(Soort.init * T.init)) resultaat;
				resultaat.vec[0] = this.vec[1] * rechts.vec[2] - rechts.vec[1] * this.vec[2];
				resultaat.vec[1] = this.vec[2] * rechts.vec[0] - rechts.vec[2] * this.vec[0];
				resultaat.vec[2] = this.vec[0] * rechts.vec[1] - rechts.vec[0] * this.vec[1];
				return resultaat;
			}
		}

		auto lengte(T = nauwkeurigheid)() const {
			T l = 0;
			static foreach (i; 0 .. rij_aantal) {
				l += this.vec[i];
			}
			return l;
		}

		auto normaliseer(T = nauwkeurigheid)() const {
			Mat!(rij_aantal, kolom_aantal, T) n;
			n.vec[] = this.vec[];
			n = n * cast(T)(1 / this.lengte());
			return n;
		}
	}

	auto maal(T, uint K)(const T[K][kolom_aantal] rechts) const
	if (is(Resultaat!(Soort, "*", T))) {
		alias Onderdeel2 = Resultaat!(Soort, "*", T);
		Mat!(rij_aantal, K, Onderdeel2) resultaat;
		static foreach (i; 0 .. rij_aantal)
			static foreach (j; 0 .. K)
				static foreach (k; 0 .. kolom_aantal)
					resultaat.mat[i][j] += this.mat[i][k] * rechts[k][j];
		return resultaat;
	}

	auto maal(T)(const T[kolom_aantal] rechts) const
	if (is(Resultaat!(Soort, "*", T))) {
		return maal!(T, 1)(cast(T[1][kolom_aantal]) rechts);
	}

	MatSoort opUnary(string op)() const if (op == "-") {
		return this * cast(Soort)-1.0;
	}

	auto opBinary(string op, R)(const R rechts) const if (op == "^") {
		return this.maal(rechts);
	}

	unittest {
		Mat!4 A = Mat!4(1);
		Vec!4 x = Vec!4([1, 0, 0, 1]);
		Vec!4 Ax = A.maal(x);
		assert(Ax == x);

		Mat!4 A2 = A.getransponeerde();
		int[4] x2 = [1, 2, 3, 4];
		Vec!4 A2x2 = A2 ^ x2;
		// assert(A2x2 == x2);

		Mat!(2, 3, int) A3 = Mat!(2, 3, int)([1, 2, 3, 4, 5, 6]);
		Vec!3 x3 = Vec!3([1, 2, 3]);
		Vec!2 A3x3 = A3 ^ x3;
		// assert(A3x3 == [14, 32]);
	}

	auto som(T = nauwkeurigheid)() const {
		T resultaat = 0;
		static foreach (i; 0 .. grootte) {
			resultaat += this.vec[i];
		}
		return resultaat;
	}

	unittest {
		Mat!2 a;
		foreach (i; 0 .. a.grootte)
			a.vec[i] = 2 * i;
		assert(a.som() == 12);
	}

	auto elk(R, S)(R function(S onderdeel) functie) const
	if (!is(R == void)) {
		Mat!(rij_aantal, kolom_aantal, R) resultaat;
		static foreach (i; 0 .. grootte)
			resultaat.vec[i] = functie(this.vec[i]);
		return resultaat;
	}

	void elk(S)(void function(S onderdeel) functie) const {
		static foreach (i; 0 .. grootte)
			functie(this.vec[i]);
	}

	unittest {
		bool even(int getal) {
			return getal % 2 == 0;
		}

		Mat!(2, 3, int) a;
		foreach (i; 0 .. a.grootte)
			a.vec[i] = i;
		auto b = a.elk(&even);
		assert(is(typeof(b) == Mat!(2, 3, bool)));
		foreach (i; 0 .. b.grootte)
			assert(b.vec[i] == (i % 2 == 0));
	}

	auto elk(R, S)(R delegate(S onderdeel) functie) const
	if (!is(R == void)) {
		Mat!(rij_aantal, kolom_aantal, R) resultaat;
		static foreach (i; 0 .. grootte)
			resultaat.vec[i] = functie(this.vec[i]);
		return resultaat;
	}

	void elk(S)(void delegate(S onderdeel) functie) const {
		static foreach (i; 0 .. grootte)
			functie(this.vec[i]);
	}

	unittest {
		Vec!5 a;
		uint i = 0;
		void overschrijven(float getal) {
			a.vec[i++] = getal;
		}

		Vec!5 b;
		foreach (j; 0 .. b.grootte)
			b.vec[j] = 5 - j;
		Vec!5 c = b;
		b.elk(&overschrijven);
		assert(a == b, "a: " ~ a.toString(true) ~ "\nb: " ~ b.toString(true));
		assert(b == c);
	}

	auto opBinary(string op, S)(const S rechts) const
	if (is(Resultaat!(Soort, op, S))) {
		alias R = Resultaat!(Soort, op, S);
		Mat!(rij_aantal, kolom_aantal, R) resultaat;
		mixin("resultaat.vec[] = this.vec[] " ~ op ~ " rechts;");
		return resultaat;
	}

	unittest {
		Mat!5 a;
		a = (a + 2) * 3;
		foreach (i; 0 .. a.grootte)
			assert(a.vec[i] == 6);
	}

	static if (isVec) {
		auto opBinary(string op, T:
			S[grootte], S)(const T rechts) const
		if (is(Resultaat!(Soort, op, S)) && !isLijst!(S)) {
			alias R = Resultaat!(Soort, op, S);
			Mat!(rij_aantal, kolom_aantal, R) resultaat;
			static foreach (i; 0 .. grootte)
				mixin("resultaat.vec[i] = this.vec[i] " ~ op ~ " rechts[i];");
			return resultaat;
		}
	} else {
		auto opBinary(string op, T:
			S[kolom_aantal][rij_aantal], S)(const T rechts) const
		if (is(Resultaat!(Soort, op, S)) && !isLijst!(S)) {
			alias R = Resultaat!(Soort, op, S);
			Mat!(rij_aantal, kolom_aantal, R) resultaat;
			static foreach (i; 0 .. rij_aantal)
				static foreach (j; 0 .. kolom_aantal)
					mixin("resultaat.mat[i][j] = this.mat[i][j] " ~ op ~ " rechts[i][j];");
			return resultaat;
		}
	}

	unittest {
		Vec!5 a = Vec!5([1, 2, 3, 4, 5]);
		int[5] b = [5, 4, 3, 2, 1];
		a = a - b;
		foreach (i; 0 .. 4)
			assert(a[i] == -4 + 2 * i, to!string(a));
	}

	unittest {
		int x = 0; // PAS OP: Wegens onduidelijke redenen vereist voor de leesbaarheid van a.
		Mat!(3, 3, float) a = Mat!(3, 3, float)([1, 2, 3, 4, 5, 6, 7, 8, 9]);
		Mat!(3, 3, double) b = Mat!(3, 3, double)(1);

		auto c = a + b;
		assert(c.isSoort!(Mat!(3, 3, double)));
		foreach (i; 0 .. 9) {
			auto verwacht = i + 1 + (i % 4 == 0);
			assert(c.vec[i] == verwacht);
		}

		auto d = c - a;
		assert(d.isSoort(c));
		assert(d == b);

		auto e = a * b;
		assert(c.isSoort(b));
		foreach (i; 0 .. 9) {
			auto verwacht = (i + 1) * (i % 4 == 0);
			assert(e.vec[i] == verwacht);
		}
	}

	M opCast(M : Mat!(rij_aantal, kolom_aantal, T), T)() const {
		M resultaat;
		static foreach (i; 0 .. grootte)
			resultaat.vec[i] = cast(T) this.vec[i];
		return resultaat;
	}

	unittest {
		Mat!(2, 3, float) a = Mat!(2, 3, float)([1.0f, 2, 3, 4, 5, 6]);
		Mat!(2, 3, int) b = cast(Mat!(2, 3, int)) a;
		static foreach (i; 0 .. 6)
			assert(b.vec[i] == cast(int) a.vec[i]);
	}

	import std.conv : to;
	import std.format : FormatSpec;
	import std.range : put;

	string toString(bool mooi = false) const {
		char[] cs;
		cs.reserve(6 * grootte);
		cs ~= '{';
		static foreach (i; 0 .. rij_aantal) {
			cs ~= '[';
			static foreach (j; 0 .. kolom_aantal) {
				cs ~= this.mat[i][j].to!string;
				static if (j != kolom_aantal - 1)
					cs ~= ", ";
			}
			static if (i != rij_aantal - 1)
				cs ~= mooi ? "],\n " : "], ";
			else
				cs ~= ']';
		}
		cs ~= '}';
		return cast(string) cs[0 .. $];
	}

	void toString(scope void delegate(const(char)[]) sink, FormatSpec!char fmt) const {
		sink.put("[");
		const string tussenvoegsel = fmt.spec == 'l' ? ",\n " : ", ";
		static foreach (i; 0 .. rij_aantal - 1) {
			sink.put(mat[i].to!string);
			sink.put(tussenvoegsel);
		}
		static if (rij_aantal > 0)
			sink.put(mat[rij_aantal - 1].to!string);
		sink.put("]");
	}

	bool opEquals(S)(const Mat!(rij_aantal, kolom_aantal, S) ander) const @safe pure nothrow {
		foreach (uint i; 0 .. grootte)
			if (this.vec[i] != ander.vec[i])
				return false;
		return true;
	}

	static if (isVec) {
		bool opEquals(S)(const S[grootte] ander) const @safe pure nothrow {
			foreach (uint i; 0 .. grootte)
				if (this.vec[i] != ander[i])
					return false;
			return true;
		}
	}

	/**
	 * Params:
	 *   ander = 2D lijst van gelijke omvang.
	 * Returns: Of ander elementsgewijs gelijk is.
	 * Bugs: https://forum.dlang.org/post/rjnywrpcsipgkronwrrc@forum.dlang.org
	 */
	@disable bool opEquals(S)(const S[kolom_aantal][rij_aantal] ander) const @safe pure nothrow {
		foreach (uint i; 0 .. rij_aantal)
			foreach (uint j; 0 .. kolom_aantal)
				if (this.mat[i][j] != ander[i][j])
					return false;
		return true;
	}

	unittest {
		auto const mat1 = Mat!(1, 2, int)([1, 2]);
		auto const mat2 = Mat!(1, 2, int)([1, 2]);
		auto const mat3 = Mat!(1, 2, int)([2, 1]);
		assert(mat1 == mat1);
		assert(mat1 == mat2);
		assert(mat1 != mat3);

		auto const mat4 = Mat!(1, 2, float)([1.0, 2.0]);
		auto const mat5 = Mat!(2, 1, int)([1, 2]);
		assert(mat1 == mat4);
		assert(!is(typeof(mat1 != mat5)));

		auto const vec1 = Vec!(2, float)([1.0, 2.0]);
		auto const mat6 = Mat!(2, 1, float)([1.0, 2.0]);
		assert(!is(typeof(mat1 == vec1)));
		assert(vec1 == mat6);

		//TODO assert(mat1 == [[1, 2]]);
		assert(!is(typeof(mat1 == [1, 2])));
		assert(vec1 == [1.0f, 2.0f]);
		assert(vec1 == [1.0f, 2.0f]);
	}

	// Hashes vereist voor associatieve lijsten.
	static if (is(Soort == byte) ||
		is(Soort == ubyte) ||
		is(Soort == short) ||
		is(Soort == ushort) ||
		is(Soort == int) ||
		is(Soort == uint) ||
		is(Soort == long) ||
		is(Soort == ulong)) {
		size_t toHash() const @safe pure nothrow {
			size_t hash = 1;
			foreach (Soort s; this.vec)
				hash = 31 * hash + s;
			return hash;
		}
	}

	static if (is(Soort == bool)) {
		size_t toHash() const @safe pure nothrow {
			size_t hash = 1;
			foreach (Soort s; this.vec)
				hash = 31 * hash + s ? 5 : 3;
			return hash;
		}
	}

	static if (is(Soort == float)) {
		private static int _castFloatInt(const float f) @trusted {
			return *cast(int*)&f;
		}

		size_t toHash() const @safe pure nothrow {
			size_t hash = 1;
			foreach (Soort s; this.vec)
				hash = 31 * hash + _castFloatInt(s); // Reinterpret as int
			return hash;
		}
	}

	static if (is(Soort == double)) {
		private static long _castDoubleLong(const double d) @trusted {
			return *cast(long*)&d;
		}

		size_t toHash() const @safe pure nothrow {
			size_t hash = 1;
			foreach (Soort s; this.vec)
				hash = 31 * hash + _castDoubleLong(s); // Reinterpret as long
			return hash;
		}
	}

	static if (is(typeof(abs!Soort))) {
		bool isOngeveer(const MatSoort ander, nauwkeurigheid delta = 1e-5) const {
			return (this - ander).elk(&abs!Soort).som() < delta;
		}
	}

	unittest {
		float delta = 1e-6;
		Mat!3 a = Mat!(3)(1);
		float[3][3] verschil = [
			[delta, -delta, delta], [delta, delta, -delta],
			[-delta, -delta, delta]
		];
		Mat!3 b = a + verschil;
		assert(a.isOngeveer(b));
		assert(!a.isOngeveer(b, 8 * delta));
	}

	// Krijg de draai nodig om een vector vanaf de y as in een richting te draai.
	// Hierbij wordt eerst de x draai toegepast gevolgd door de z draai.
	// Er is dus geen sprake van draai om de y as.
	// (Denk hierbij dus aan stamping gevolgd door giering, ook wel 'pitch' gevolgd door 'yaw')
	static Vec!3 krijgDraai(Vec!3 richting) {
		import std.math : acos, atan, PI_2, signbit;

		if (richting.x == 0 && richting.y == 0) {
			if (richting.z == 0)
				return richting; // [0,0,0] -> [0,0,0]
			return Vec!3([PI_2, 0, 0]); // [0,0,z] -> [PI/2,0,0]
		}
		nauwkeurigheid R = Vec!2([richting.x, richting.y]).lengte();
		// [x,y,z] -> [atan(z/sqrt(x²+y²)),0,-teken(x)*acos(y/sqrt(x²+y²))]
		return Vec!3([
			atan(richting.z / R), 0,
			-signbit(richting.x) * acos(richting.y / R)
		]);
	}

	// VOEG TOE: test

	// Het omgekeerde van krijgDraai.
	// Draai om de y as wordt aangenomen als 0 aangzien deze geen invloed heeft.
	static Vec!3 krijgRichting(Vec!3 draai) {
		import std.math : sin, cos;

		return Vec!3([-sin(draai.z), cos(draai.z), sin(draai.x)]);
	}

	// VOEG TOE: test
}
