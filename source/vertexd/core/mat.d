module vertexd.core.mat;
import std.conv : to;
import std.exception : enforce;
import std.math : abs, cos, sin, sqrt;
import std.stdio;
import std.traits : isCallable, isFloatingPoint, ReturnType;
import vertexd.misc;

alias prec = precision;
version (HoekjeD_Double) {
	alias precision = double;
} else {
	alias precision = float;
}

alias Vec(uint size = 3, Type = precision) = Mat!(size, 1, Type);
alias Mat(uint count = 3, Type = precision) = Mat!(count, count, Type);

struct Mat(uint row_count, uint column_count, Type = precision) if (row_count > 0 && column_count > 0) {
	enum uint size = row_count * column_count;
	enum bool isVec = column_count == 1;
	enum bool isMat = !isVec;
	enum bool isSquare = column_count == row_count;

	alias MatType = typeof(this);

	union {
		Type[size] vec = 0; // Standard values are 0
		Type[column_count][row_count] mat;
		static if (isVec) {
			struct {
				static if (size >= 1)
					Type x;
				static if (size >= 2)
					Type y;
				static if (size >= 3)
					Type z;
				static if (size >= 4)
					Type w;
			}
		}
	}

	this(Type n) {
		static if (isVec)
			vec[] = n;
		else {
			static foreach (i; 0 .. row_count)
				static foreach (j; 0 .. column_count)
					mat[i][j] = (i == j) ? n : 0;
		}
	}

	this(Type[] n...) {
		this.vec = n;
	}

	this(Type[column_count][row_count] n) {
		this.mat = n;
	}

	unittest {
		Vec!3 a = Vec!3([1, 2, 3]);
		Vec!3 b = Vec!3(1, 2, 3);
		assert(a == b);

		Mat!3 c = Mat!3(0, 1, 2, 3, 4, 5, 6, 7, 8);
		Mat!3 d = Mat!3([[0, 1, 2], [3, 4, 5], [6, 7, 8]]);
		assert(c == d);
	}

	static if (isVec)
		alias vec this;
	else
		alias mat this;

	void setCol(uint k, Vec!(row_count, Type) col) {
		assert(k < row_count);
		foreach (i; 0 .. row_count) {
			this.mat[k][i] = col[i];
		}
	}

	Vec!row_count col(uint i) {
		Vec!row_count k;
		foreach (r; 0 .. row_count) {
			k.vec[r] = mat[r][i];
		}
		return k;
	}

	Mat!(1, column_count, Type) row(uint i) {
		return Mat!(1, column_count, Type)([mat[i]]);
	}

	static if (isSquare) {
		alias Type2 = Result!(Type, "+", Type); // Integer Promotion
		auto inverse() {
			Mat!(row_count, column_count, Type2) inverse;
			Type2 determinant;
			static if (row_count == 2) {
				inverse[0][0] = mat[1][1];
				inverse[0][1] = -mat[0][1];
				inverse[1][0] = -mat[1][0];
				inverse[1][1] = mat[0][0];
				determinant = mat[0][0] * mat[1][1] - mat[0][1] * mat[1][0];
			} else static if (row_count == 3) {
				// Determine adjugate (transposed cofactor) matrix (2x2 determinants times even index sign)
				inverse[0][0] = mat[1][1] * mat[2][2] - mat[1][2] * mat[2][1];
				inverse[0][1] = -(mat[0][1] * mat[2][2] - mat[0][2] * mat[2][1]);
				inverse[0][2] = mat[0][1] * mat[1][2] - mat[0][2] * mat[1][1];

				inverse[1][0] = -(mat[1][0] * mat[2][2] - mat[1][2] * mat[2][0]);
				inverse[1][1] = mat[0][0] * mat[2][2] - mat[0][2] * mat[2][0];
				inverse[1][2] = -(mat[0][0] * mat[1][2] - mat[0][2] * mat[1][0]);

				inverse[2][0] = mat[1][0] * mat[2][1] - mat[1][1] * mat[2][0];
				inverse[2][1] = -(mat[0][0] * mat[2][1] - mat[0][1] * mat[2][0]);
				inverse[2][2] = mat[0][0] * mat[1][1] - mat[0][1] * mat[1][0];

				determinant = mat[0][0] * inverse[0][0] + mat[0][1] * inverse[1][0] + mat[0][2] * inverse[2][0];
			} else static if (row_count == 4) {
				// Determine 2x2 determinants for bottom 3 rows
				// Mij_kl references the top left index ij & bottom right index kl
				Type2 M10_21 = mat[1][0] * mat[2][1] - mat[1][1] * mat[2][0];
				Type2 M10_31 = mat[1][0] * mat[3][1] - mat[1][1] * mat[3][0];
				Type2 M20_31 = mat[2][0] * mat[3][1] - mat[2][1] * mat[3][0];

				Type2 M10_22 = mat[1][0] * mat[2][2] - mat[1][2] * mat[2][0];
				Type2 M10_32 = mat[1][0] * mat[3][2] - mat[1][2] * mat[3][0];
				Type2 M20_32 = mat[2][0] * mat[3][2] - mat[2][2] * mat[3][0];

				Type2 M10_23 = mat[1][0] * mat[2][3] - mat[1][3] * mat[2][0];
				Type2 M10_33 = mat[1][0] * mat[3][3] - mat[1][3] * mat[3][0];
				Type2 M20_33 = mat[2][0] * mat[3][3] - mat[2][3] * mat[3][0];

				Type2 M11_22 = mat[1][1] * mat[2][2] - mat[1][2] * mat[2][1];
				Type2 M11_32 = mat[1][1] * mat[3][2] - mat[1][2] * mat[3][1];
				Type2 M21_32 = mat[2][1] * mat[3][2] - mat[2][2] * mat[3][1];

				Type2 M11_23 = mat[1][1] * mat[2][3] - mat[1][3] * mat[2][1];
				Type2 M11_33 = mat[1][1] * mat[3][3] - mat[1][3] * mat[3][1];
				Type2 M21_33 = mat[2][1] * mat[3][3] - mat[2][3] * mat[3][1];

				Type2 M12_23 = mat[1][2] * mat[2][3] - mat[1][3] * mat[2][2];
				Type2 M12_33 = mat[1][2] * mat[3][3] - mat[1][3] * mat[3][2];
				Type2 M22_33 = mat[2][2] * mat[3][3] - mat[2][3] * mat[3][2];

				// Determine adjugate (transposed cofactor) matrix (minor times even index sign)
				// Using a laplace expansion to determine the minor
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

				// determine determinant with cofactors
				determinant = mat[0][0] * inverse[0][0] + mat[0][1] * inverse[1][0] + mat[0][2]
					* inverse[2][0] + mat[0][3] * inverse[3][0];
			}

			enforce(determinant != 0, "Matrix not invertable: determinant = 0");
			inverse = inverse / determinant;
			return inverse;
		}

		unittest {
			Mat!2 M = Mat!2([3, 5, 7, 11]);
			Mat!2 I = M.inverse().mult(M);
			Vec!2 i = Vec!2(1);
			assert(i.almostEqs(I.mult(i)));
		}

		unittest {
			Mat!3 M = Mat!3([1, 0, 3, 4, 5, 6, 7, 8, 9]); // Determinant -12

			Mat!3 I = M.inverse().mult(M);
			Vec!3 i = Vec!3(1);
			assert(i.almostEqs(I.mult(i)));
		}

		unittest {
			Mat!4 M = Mat!4([1, -2, 3, 4, 5, 6, 7, -8, 9, 10, 11, 12, 13, 14, 15, 16]); // Determinant 512
			Mat!4 I = M.inverse().mult(M);
			Vec!4 i = Vec!4(1);
			assert(i.almostEqs(I.mult(i)));
		}

		static if ((row_count == 3 || row_count == 4) && isFloatingPoint!Type) {
			static {
				MatType rotationMx(precision angle) {
					MatType rotationM = MatType(1);
					precision cos = cos(angle);
					precision sin = sin(angle);
					rotationM[1][1] = cos;
					rotationM[1][2] = -sin;
					rotationM[2][1] = sin;
					rotationM[2][2] = cos;
					return rotationM;
				}

				unittest {
					import std.math : PI, PI_2;

					Mat!4 rotation = Mat!(4).rotationMx(0);
					Mat!4 rotation2 = Mat!4(1);
					assert(rotation.almostEqs(rotation2));

					rotation = Mat!(4).rotationMx(PI_2);
					rotation2 = Mat!4();
					rotation2[0][0] = 1;
					rotation2[1][2] = -1;
					rotation2[2][1] = 1;
					rotation2[3][3] = 1;
					float delta = 1e-5;
					float diff = (rotation.each(&abs!(float)) - rotation2.each(&abs!(float))).sum();
					assert(diff < delta);

					rotation = Mat!(4).rotationMx(PI);
					rotation2 = Mat!4(1);
					rotation2[1][1] = -1;
					rotation2[2][2] = -1;
					diff = (rotation.each(&abs!(float)) - rotation2.each(&abs!(float))).sum();
					assert(diff < delta);
				}

				MatType rotationMy(precision angle) {
					MatType rotationM = MatType(1);
					precision cos = cos(angle);
					precision sin = sin(angle);
					rotationM[0][0] = cos;
					rotationM[0][2] = sin;
					rotationM[2][0] = -sin;
					rotationM[2][2] = cos;
					return rotationM;
				}

				unittest {
					import std.math : PI, PI_2;

					Mat!4 rotation = Mat!(4).rotationMy(0);
					Mat!4 rotation2 = Mat!4(1);
					assert(rotation == rotation2);

					rotation = Mat!(4).rotationMy(PI_2);
					rotation2 = Mat!4();
					rotation2[0][2] = 1;
					rotation2[1][1] = 1;
					rotation2[2][0] = -1;
					rotation2[3][3] = 1;
					float delta = 1e-5;
					float diff = (rotation.each(&abs!(float)) - rotation2.each(&abs!(float))).sum();
					assert(diff < delta);

					rotation = Mat!(4).rotationMy(PI);
					rotation2 = Mat!4(1);
					rotation2[0][0] = -1;
					rotation2[2][2] = -1;
					diff = (rotation.each(&abs!(float)) - rotation2.each(&abs!(float))).sum();
					assert(diff < delta);
				}

				MatType rotationMz(precision angle) {
					MatType rotationM = MatType(1);
					precision cos = cos(angle);
					precision sin = sin(angle);
					rotationM[0][0] = cos;
					rotationM[0][1] = -sin;
					rotationM[1][0] = sin;
					rotationM[1][1] = cos;
					return rotationM;
				}

				unittest {
					import std.math : PI, PI_2;

					Mat!4 rotation = Mat!(4).rotationMz(0);
					Mat!4 rotation2 = Mat!4(1);
					assert(rotation == rotation2);

					rotation = Mat!(4).rotationMz(PI_2);
					rotation2[0][0] = 0;
					rotation2[0][1] = -1;
					rotation2[1][0] = 1;
					rotation2[1][1] = 0;
					float delta = 1e-5;
					float diff = (rotation.each(&abs!(float)) - rotation2.each(&abs!(float))).sum();
					assert(diff < delta);

					rotation = Mat!(4).rotationMz(PI);
					rotation2 = Mat!4(1);
					rotation2[0][0] = -1;
					rotation2[1][1] = -1;
					diff = (rotation.each(&abs!(float)) - rotation2.each(&abs!(float))).sum();
					assert(diff < delta);
				}
			}
		}
	}

	auto transposed() const {
		Mat!(column_count, row_count, Type) result;
		static foreach (i; 0 .. row_count)
			static foreach (j; 0 .. column_count)
				result.mat[j][i] = this.mat[i][j];
		return result;
	}

	static if (isVec) {
		auto dot(Result = Type, R:
			Mat!(row_count, 1, T), T)(const R right) const {
			Result result = 0;
			static foreach (i; 0 .. size)
				result += this.vec[i] * right.vec[i];
			return result;
		}

		static if (row_count == 3) {
			auto cross(R : Mat!(row_count, 1, T), T)(const R right) const {
				Mat!(row_count, 1, typeof(Type.init * T.init)) result;
				result.vec[0] = this.vec[1] * right.vec[2] - right.vec[1] * this.vec[2];
				result.vec[1] = this.vec[2] * right.vec[0] - right.vec[2] * this.vec[0];
				result.vec[2] = this.vec[0] * right.vec[1] - right.vec[0] * this.vec[1];
				return result;
			}
		}

		auto length(T = precision)() const {
			T l = 0;
			static foreach (i; 0 .. row_count) {
				l += this.vec[i] * this.vec[i];
			}
			return sqrt(l);
		}

		auto normalize(T = precision)() const {
			Mat!(row_count, column_count, T) n;
			n.vec[] = this.vec[];
			n = n * cast(T)(1 / this.length());
			return n;
		}
	}

	auto mult(T, uint K)(const T[K][column_count] right) const if (is(Result!(Type, "*", T))) {
		alias T2 = Result!(Type, "*", T);
		Mat!(row_count, K, T2) result;
		static foreach (i; 0 .. row_count)
			static foreach (j; 0 .. K)
				static foreach (k; 0 .. column_count)
					result.mat[i][j] += this.mat[i][k] * right[k][j];
		return result;
	}

	auto mult(T)(const T[column_count] right) const if (is(Result!(Type, "*", T))) {
		return mult!(T, 1)(cast(T[1][column_count]) right);
	}

	MatType opUnary(string op)() const if (op == "-") {
		return this * cast(Type)-1.0;
	}

	auto opBinary(string op, R)(const R right) const if (op == "^") {
		return this.mult(right);
	}

	auto opOpAssign(string op, T)(T value) {
		this = mixin(this, op, "value");
		return this;
	}

	unittest {
		Mat!4 A = Mat!4(1);
		Vec!4 x = Vec!4([1, 0, 0, 1]);
		Vec!4 Ax = A.mult(x);
		assert(Ax == x);

		Mat!4 A2 = A.transposed();
		int[4] x2 = [1, 2, 3, 4];
		Vec!4 A2x2 = A2 ^ x2;
		assert(A2x2 == x2);

		Mat!(2, 3, int) A3 = Mat!(2, 3, int)([1, 2, 3, 4, 5, 6]);
		Vec!3 x3 = Vec!3([1, 2, 3]);
		Vec!2 A3x3 = A3 ^ x3;
		assert(A3x3 == [14, 32]);
	}

	auto sum(T = precision)() const {
		T result = 0;
		static foreach (i; 0 .. size) {
			result += this.vec[i];
		}
		return result;
	}

	unittest {
		Mat!2 a;
		foreach (i; 0 .. a.size)
			a.vec[i] = 2 * i;
		assert(a.sum() == 12);
	}

	static if (__traits(isFloating, Type) || __traits(isIntegral, Type))
		Type min() const {
			Type minVal = Type.max;
			foreach (i; 0 .. size) {
				if (vec[i] < minVal)
					minVal = vec[i];
			}
			return minVal;
		}

	unittest {
		Vec!3 a = Vec!3(-2, 1, 2);
		assert(a.min() == -2);
	}

	static if (__traits(isFloating, Type) || __traits(isIntegral, Type))
		Type max() const {
			static if (__traits(isFloating, Type))
				Type maxVal = -Type.max;
			else
				Type maxVal = Type.min;

			foreach (i; 0 .. size) {
				if (vec[i] > maxVal)
					maxVal = vec[i];
			}
			return maxVal;
		}

	unittest {
		Vec!3 a = Vec!3(-2, 1, 2);
		assert(a.max() == 2);
	}

	auto each(C)(C func) const 
			if (isCallable!C && !is(ReturnType!C == void) && __traits(compiles, func(Type.init))) {
		Mat!(row_count, column_count, ReturnType!C) result;
		static foreach (i; 0 .. size)
			result.vec[i] = func(this.vec[i]);
		return result;
	}

	void each(C)(C func) const 
			if (isCallable!C && is(ReturnType!C == void) && __traits(compiles, func(Type.init))) {
		static foreach (i; 0 .. size)
			func(this.vec[i]);
	}

	unittest {
		bool even(int number) {
			return number % 2 == 0;
		}

		Mat!(2, 3, int) a;
		foreach (i; 0 .. a.size)
			a.vec[i] = i;

		auto b = a.each(&even);
		assert(is(typeof(b) == Mat!(2, 3, bool)));
		foreach (i; 0 .. b.size)
			assert(b.vec[i] == (i % 2 == 0));
	}

	unittest {
		Vec!5 a;
		uint i = 0;
		void overwrite(float number) {
			a.vec[i++] = number;
		}

		Vec!5 b;
		foreach (j; 0 .. b.size)
			b.vec[j] = 5 - j;
		Vec!5 c = b;
		b.each(&overwrite);
		assert(a == b, "a: " ~ a.toString(true) ~ "\nb: " ~ b.toString(true));
		assert(b == c);
	}

	auto opBinary(string op, S)(const S right) const if (is(Result!(Type, op, S))) {
		alias R = Result!(Type, op, S);
		Mat!(row_count, column_count, R) result;
		mixin("result.vec[] = this.vec[] " ~ op ~ " right;");
		return result;
	}

	unittest {
		Mat!5 a;
		a = (a + 2) * 3;
		foreach (i; 0 .. a.size)
			assert(a.vec[i] == 6);
	}

	static if (isVec) {
		auto opBinary(string op, T:
			S[Size], S, uint Size)(const T right) const 
				if (is(Result!(Type, op, S)) && !isList!(S) && Size == size) { // WARNING: why cant size be used directly?
			alias R = Result!(Type, op, S);
			Mat!(row_count, column_count, R) result;
			static foreach (i; 0 .. size)
				mixin("result.vec[i] = this.vec[i] " ~ op ~ " right[i];");
			return result;
		}
	} else {
		auto opBinary(string op, T:
			S[column_count][row_count], S)(const T right) const 
				if (is(Result!(Type, op, S)) && !isList!(S)) {
			alias R = Result!(Type, op, S);
			Mat!(row_count, column_count, R) result;
			static foreach (i; 0 .. row_count)
				static foreach (j; 0 .. column_count)
					mixin("result.mat[i][j] = this.mat[i][j] " ~ op ~ " right[i][j];");
			return result;
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
		int x = 0; // WARNING: Due to uknown reasons required for the readability of a
		Mat!(3, 3, float) a = Mat!(3, 3, float)([1, 2, 3, 4, 5, 6, 7, 8, 9]);
		Mat!(3, 3, double) b = Mat!(3, 3, double)(1);

		auto c = a + b;
		assert(c.isType!(Mat!(3, 3, double)));
		foreach (i; 0 .. 9) {
			auto expected = i + 1 + (i % 4 == 0);
			assert(c.vec[i] == expected);
		}

		auto d = c - a;
		assert(d.isType(c));
		assert(d == b);

		auto e = a * b;
		assert(c.isType(b));
		foreach (i; 0 .. 9) {
			auto expected = (i + 1) * (i % 4 == 0);
			assert(e.vec[i] == expected);
		}
	}

	M opCast(M : Mat!(row_count, column_count, T), T)() const {
		M result;
		static foreach (i; 0 .. size)
			result.vec[i] = cast(T) this.vec[i];
		return result;
	}

	unittest {
		Mat!(2, 3, float) a = Mat!(2, 3, float)([1.0f, 2, 3, 4, 5, 6]);
		Mat!(2, 3, int) b = cast(Mat!(2, 3, int)) a;
		static foreach (i; 0 .. 6)
			assert(b.vec[i] == cast(int) a.vec[i]);
	}

	static if (isMat)
		string toString(bool nice = false)() const {
			char[] cs;
			cs.reserve(6 * size);
			cs ~= '{';
			static foreach (i; 0 .. row_count) {
				cs ~= '[';
				static foreach (j; 0 .. column_count) {
					cs ~= this.mat[i][j].to!string;
					static if (j != column_count - 1)
						cs ~= ", ";
				}
				static if (i != row_count - 1)
					cs ~= nice ? "],\n " : "], ";
				else
					cs ~= ']';
			}
			cs ~= '}';
			return cast(string) cs;
		}

	static if (isVec)
		string toString() const {
			char[] cs;
			foreach (v; vec)
				cs ~= v.to!string ~ ", ";
			cs = cs[0 .. $ - 2] ~ ']';
			return cast(string) cs;
		}

	bool opEquals(S)(const Mat!(row_count, column_count, S) other) const @safe pure nothrow {
		foreach (uint i; 0 .. size)
			if (this.vec[i] != other.vec[i])
				return false;
		return true;
	}

	static if (isVec) {
		bool opEquals(S)(const S[size] other) const @safe pure nothrow {
			foreach (uint i; 0 .. size)
				if (this.vec[i] != other[i])
					return false;
			return true;
		}
	}

	/**
	 * Params:
	 *   other = 2D list of equivalent size.
	 * Returns: Whether other is equivalent elementswise.
	 * Bugs: https://forum.dlang.org/post/rjnywrpcsipgkronwrrc@forum.dlang.org
	 */
	@disable bool opEquals(S)(const S[column_count][row_count] other) const @safe pure nothrow {
		foreach (uint i; 0 .. row_count)
			foreach (uint j; 0 .. column_count)
				if (this.mat[i][j] != other[i][j])
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

	static if (is(typeof(abs!Type))) {
		bool almostEq(const MatType other, precision delta = 1e-5) const {
			return (cast(MatType)(this - other)).each(&abs!Type).sum() < delta;
		}

		bool assertAlmostEq(const MatType other, precision delta = 1e-5) const {
			MatType diffVec = (cast(MatType)(this - other)).each(&abs!Type);
			float diff = diffVec.sum();
			// string a = other.to!string;
			bool holds = diff < delta;
			assert(holds, "Expected " ~ this.toString ~ " ==(delta=" ~ delta.to!string ~ ") " ~ to!string(
					other) ~ " but found difference: " ~ to!string(diffVec) ~ " (diff=" ~ diff.to!string ~ ")");
			return holds;
		}
	}

	// Hashes required for associative lists
	static if (is(Type == byte) || is(Type == ubyte) || is(Type == short) || is(Type == ushort)
		|| is(Type == int) || is(Type == uint) || is(Type == long) || is(Type == ulong)) {
		size_t toHash() const @safe pure nothrow {
			size_t hash = 1;
			foreach (Type s; this.vec)
				hash = 31 * hash + s;
			return hash;
		}
	}

	static if (is(Type == bool)) {
		size_t toHash() const @safe pure nothrow {
			size_t hash = 1;
			foreach (Type s; this.vec)
				hash = 31 * hash + s ? 5 : 3;
			return hash;
		}
	}

	static if (is(Type == float)) {
		private static int _castFloatInt(const float f) @trusted {
			return *cast(int*)&f;
		}

		size_t toHash() const @safe pure nothrow {
			size_t hash = 1;
			foreach (Type s; this.vec)
				hash = 31 * hash + _castFloatInt(s); // Reinterpret as int
			return hash;
		}
	}

	static if (is(Type == double)) {
		private static long _castDoubleLong(const double d) @trusted {
			return *cast(long*)&d;
		}

		size_t toHash() const @safe pure nothrow {
			size_t hash = 1;
			foreach (Type s; this.vec)
				hash = 31 * hash + _castDoubleLong(s); // Reinterpret as long
			return hash;
		}
	}

	unittest {
		float delta = 1e-6;
		Mat!3 a = Mat!(3)(1);
		float[3][3] diff = [
			[delta, -delta, delta], [delta, delta, -delta], [-delta, -delta, delta]
		];
		Mat!3 b = a + diff;
		assert(a.almostEqs(b));
		assert(!a.almostEqs(b, 8 * delta));
	}

	// Get rotation required to rotate a vector from the y axis towards the direction.
	// Rotation about the x axis is applied before rotation about z
	// Thus there is no rotation around the y axis.
	// _
	static Vec!3 getRotation(Vec!3 direction) {
		import std.math : acos, atan, PI_2, signbit;

		if (direction.x == 0 && direction.y == 0) {
			if (direction.z == 0)
				return direction; // [0,0,0] -> [0,0,0]
			return Vec!3([PI_2, 0, 0]); // [0,0,z] -> [PI/2,0,0]
		}
		precision R = Vec!2([direction.x, direction.y]).length();
		// [x,y,z] -> [atan(z/sqrt(x²+y²)),0,-teken(x)*acos(y/sqrt(x²+y²))]
		return Vec!3([atan(direction.z / R), 0, -signbit(direction.x) * acos(direction.y / R)]);
	}

	// TODO: add test

	// Opposite of getRotation
	// ROtation around y axis assumed 0
	static Vec!3 getDirection(Vec!3 rotation) {
		import std.math : sin, cos;

		return Vec!3([-sin(rotation.z), cos(rotation.z), sin(rotation.x)]);
	}

	// TODO: add test
}
