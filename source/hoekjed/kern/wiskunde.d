module hoekjed.kern.wiskunde;
import std.stdio;
import std.math : sin, cos, abs, sqrt;

import hoekjed.overig;

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

	alias MatSoort = Mat!(rij_aantal, kolom_aantal, nauwkeurigheid);

	union {
		Soort[grootte] vec;
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

	// VOEG TOE: constructer met ... arg lijst

	// this(Soort[][] inhoud) {
	// 	foreach (i; 0 .. rij_aantal)
	// 		foreach (j; 0 .. kolom_aantal)
	// 			this.mat[i][j] = inhoud[i][j];
	// }

	static if (isVec)
		alias vec this;
	else
		alias mat this;

	static immutable auto nul = _bereken_nul();
	private static auto _bereken_nul() {
		MatSoort resultaat;
		static foreach (i; 0 .. grootte)
			resultaat.vec[i] = 0;
		return resultaat;
	}

	static if (isVierkant) {
		static immutable auto identiteit = _bereken_identiteit();
		private static auto _bereken_identiteit() {
			MatSoort resultaat;
			static foreach (i; 0 .. rij_aantal)
				static foreach (j; 0 .. kolom_aantal)
					resultaat.vec[i + j * kolom_aantal] = (i == j ? 1 : 0);
			return resultaat;
		}
	}

	auto gekantelde() const {
		Mat!(kolom_aantal, rij_aantal, Soort) resultaat;
		static foreach (i; 0 .. rij_aantal)
			static foreach (j; 0 .. kolom_aantal)
				resultaat.mat[j][i] = this.mat[i][j];
		return resultaat;
	}

	static {
		Mat!(4, 4, nauwkeurigheid) draaiMx(nauwkeurigheid hoek) {
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

		unittest {
			import std.math : PI, PI_2;

			Mat!4 draai = Mat!(4).draaiMx(0);
			Mat!4 draai2 = Mat!(4).identiteit;
			assert(draai == draai2);

			draai = Mat!(4).draaiMx(PI_2);
			draai2 = Mat!(4).nul;
			draai2[0][0] = 1;
			draai2[1][2] = -1;
			draai2[2][1] = 1;
			draai2[3][3] = 1;
			float delta = 1e-5;
			float verschil = (draai.elk(&abs!(float)) - draai2.elk(&abs!(float))).som();
			assert(verschil < delta);

			draai = Mat!(4).draaiMx(PI);
			draai2 = Mat!(4).identiteit;
			draai2[1][1] = -1;
			draai2[2][2] = -1;
			verschil = (draai.elk(&abs!(float)) - draai2.elk(&abs!(float))).som();
			assert(verschil < delta);
		}

		Mat!(4, 4, nauwkeurigheid) draaiMy(nauwkeurigheid hoek) {
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

		unittest {
			import std.math : PI, PI_2;

			Mat!4 draai = Mat!(4).draaiMy(0);
			Mat!4 draai2 = Mat!(4).identiteit;
			assert(draai == draai2);

			draai = Mat!(4).draaiMy(PI_2);
			draai2 = Mat!(4).nul;
			draai2[0][2] = 1;
			draai2[1][1] = 1;
			draai2[2][0] = -1;
			draai2[3][3] = 1;
			float delta = 1e-5;
			float verschil = (draai.elk(&abs!(float)) - draai2.elk(&abs!(float))).som();
			assert(verschil < delta);

			draai = Mat!(4).draaiMy(PI);
			draai2 = Mat!(4).identiteit;
			draai2[0][0] = -1;
			draai2[2][2] = -1;
			verschil = (draai.elk(&abs!(float)) - draai2.elk(&abs!(float))).som();
			assert(verschil < delta);
		}

		Mat!(4, 4, nauwkeurigheid) draaiMz(nauwkeurigheid hoek) {
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

		unittest {
			import std.math : PI, PI_2;

			Mat!4 draai = Mat!(4).draaiMz(0);
			Mat!4 draai2 = Mat!(4).identiteit;
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
			draai2 = Mat!(4).identiteit;
			draai2[0][0] = -1;
			draai2[1][1] = -1;
			verschil = (draai.elk(&abs!(float)) - draai2.elk(&abs!(float))).som();
			assert(verschil < delta);
		}
	}

	static if (isVec) {
		auto inp(Resultaat = Soort, R:
				Mat!(rij_aantal, 1, T), T)(const R rechts) const {
			Resultaat resultaat = 0;
			static foreach (i; 0 .. grootte)
				resultaat.vec[i] += this.vec[i] * rechts.vec[i];
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

	static if (isMat) {
		// auto maal(T, R:
		// 		Mat!(kolom_aantal, 1, T))(R rechts) {
		// 	alias Onderdeel2 = typeof(Soort * T);
		// 	Vec!(rij_aantal, Onderdeel2) resultaat = Vec!(R, Onderdeel2).nul;
		// 	static foreach (i; 0 .. rij_aantal)
		// 		static foreach (j; 0 .. rij_aantal)
		// 			resultaat.vec[i] += this.mat[i][j] * rechts.vec[j];
		// 	return resultaat;
		// } Is het zelfde als:

		auto maal(T, uint K)(const T[K][kolom_aantal] rechts) const 
				if (is(Resultaat!(Soort, "*", T))) {
			alias Onderdeel2 = Resultaat!(Soort, "*", T);
			Mat!(rij_aantal, K, Onderdeel2) resultaat = Mat!(rij_aantal, K, Onderdeel2).nul;
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

		unittest {
			import std.math : PI_2;

			Mat!4 a = Mat!4.draaiMz(PI_2);
			Vec!4 resultaat = a.maal([1, 0, 0, 1]);
			float verschil = (resultaat.elk(&abs!(float)) - [0, 1, 0, 1]).som();
			float delta = 1e-5;
			assert(verschil < delta);

			Mat!(2, 3) c;
			Mat!(3, 2) d;
			foreach (i; 0 .. c.grootte) {
				c.vec[i] = i + 1;
				d.vec[i] = i + 1;
			}
			auto c_gevonden = c.maal(c.gekantelde);
			assert(is(typeof(c_gevonden) == Mat!2));
			Mat!2 c_verwacht = Mat!2([14, 32, 32, 77]);
			assert(c_gevonden == c_verwacht, c_gevonden.toString() ~ "\n!=\n" ~ c_verwacht.toString());

			auto d_gevonden = c.maal(d);
			assert(is(typeof(d_gevonden) == Mat!2));
			Mat!2 d_verwacht = Mat!2([22, 28, 49, 64]);
			assert(d_gevonden == d_verwacht);
		}
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

	auto elk(S1, S2)(S1 function(S2 onderdeel) functie) const if (!is(S1 == void)) {
		Mat!(rij_aantal, kolom_aantal, S1) resultaat;
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

	auto elk(S1, S2)(S1 delegate(S2 onderdeel) functie) const if (!is(S1 == void)) {
		Mat!(rij_aantal, kolom_aantal, S1) resultaat;
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

	auto opBinary(string op, T)(const T[rij_aantal][kolom_aantal] rechts) const 
			if (is(Resultaat!(Soort, op, T))) {
		Mat!(rij_aantal, kolom_aantal, Resultaat!(Soort, op, T)) resultaat;
		static foreach (i; 0 .. rij_aantal)
			static foreach (j; 0 .. kolom_aantal)
				mixin("resultaat.mat[i][j] = this.mat[i][j] " ~ op ~ " rechts[i][j];");
		return resultaat;
	}

	unittest {
		Mat!(2, 3, int) a;
		Mat!(3, 5, float) b;
		foreach (i; 0 .. 6)
			a.vec[i] = i;
		foreach (i; 0 .. 15)
			b.vec[i] = -i;
		auto c = a.maal(b);
		scope (failure)
			writefln("c:\n%l", c);

		assert(is(typeof(c) == Mat!(2, 5, float)));
		Mat!(2, 5, float) d;
		foreach (i; 0 .. 5)
			d.vec[i] = -(25 + 3 * i);
		foreach (i; 0 .. 5)
			d.vec[i + 5] = -(70 + 12 * i);
		scope (failure)
			writefln("d:\n%l", d);

		assert(c == d);
	}

	static if (isVec) {
		auto opBinary(string op, T)(const T[grootte] rechts) const 
				if (is(Resultaat!(Soort, op, T))) {
			Vec!(grootte, Resultaat!(Soort, op, T)) resultaat;
			static foreach (i; 0 .. grootte)
				mixin("resultaat.vec[i] = this.vec[i] " ~ op ~ " rechts[i];");
			return resultaat;
		}
	}

	unittest {
		Vec!5 a = Vec!5([1, 2, 3, 4, 5]);
		a = a - [5, 4, 3, 2, 1];
		foreach (i; 0 .. 4)
			assert(a[i] == -4 + 2 * i, to!string(a));
	}

	auto opBinary(string op, T)(const T rechts) const 
			if (is(Resultaat!(Soort, op, T))) {
		Mat!(rij_aantal, kolom_aantal, Resultaat!(Soort, op, T)) resultaat;
		static foreach (i; 0 .. grootte)
			mixin("resultaat.vec[i] = this.vec[i] " ~ op ~ " rechts;");
		return resultaat;
	}

	unittest {
		Mat!5 a = Mat!5.nul;
		a = (a + 2) * 3;
		foreach (i; 0 .. a.grootte)
			assert(a.vec[i] == 6);
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

	import std.format : FormatSpec;
	import std.range : put;
	import std.conv : to;

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

	bool opEquals(R)(const R ander) const {
		static if (is(const R == typeof(this)))
			return this.mat == (cast(typeof(this)) ander).mat;
		else {
			static if (!isVec && is(const R == typeof(this.mat)))
				return this.mat == ander;
			else {
				static if (isVec && is(const R == typeof(this.vec)))
					return this.vec == ander;
				else
					return false;
			}
		}
	}

	unittest {
		Mat!(1, 2, float) mat = Mat!(1, 2, float)([1, 2]);
		Mat!(1, 2, float) mat2 = Mat!(1, 2, float)([1, 2]);
		Mat!(2, 1, float) mat3 = Mat!(2, 1, float)([1, 2]);
		Vec!(2, float) vec = Vec!(2, float)([1, 2]);
		float[2] lijst = [1, 2];
		float[2][1] lijst2 = [[1, 2]];
		assert(mat == mat);
		assert(mat == mat2);
		assert(mat != mat3);
		assert(mat != vec);
		assert(mat != lijst);
		assert(mat == lijst2);

		assert(mat2 == mat2);
		assert(mat2 != mat3);
		assert(mat2 != vec);
		assert(mat2 != lijst);
		assert(mat2 == lijst2);

		assert(mat3 == mat3);
		assert(mat3 == vec);
		assert(mat3 == lijst); //! mat 3 is een vec
		assert(mat3 != lijst2);

		assert(vec == vec);
		assert(vec == lijst);
		assert(vec != lijst2);
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
		return Vec!3([atan(richting.z / R), 0, -signbit(richting.x) * acos(richting.y / R)]);
	}

	// VOEG TOE: test

	// Het omgekeerde van krijgDraai.
	// Draai om de y as wordt aangenomen als 0 aangzien dit geen invloed heeft.
	static Vec!3 krijgRichting(Vec!3 draai) {
		import std.math : sin, cos;

		return Vec!3([-sin(draai.z), cos(draai.z), sin(draai.x)]);
	}

	// VOEG TOE: test
}

Vec!3 TEMP_draai(Vec!3 oorsprong, Vec!3 doel) {
	import std.math : acos, PI;

	//TODO: nulvector
	Vec!2 oorsprong_proj = (Vec!2([oorsprong.x, oorsprong.y])).normaliseer();
	nauwkeurigheid oorsprong_theta = oorsprong_proj.y > 0
		? acos(oorsprong_proj.x) : -acos(oorsprong_proj.x);
	Vec!2 doel_proj = (Vec!2([doel.x, doel.y])).normaliseer();
	nauwkeurigheid doel_theta = doel_proj.y > 0 ? acos(doel_proj.x) : -acos(doel_proj.x);
	nauwkeurigheid verschil_theta = doel_theta - oorsprong_theta;

	while (verschil_theta < 0)
		verschil_theta += 2 * PI;

	return Vec!3([0, 0, verschil_theta]);
}
