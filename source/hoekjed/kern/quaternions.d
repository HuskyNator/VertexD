module hoekjed.kern.quaternions;
import hoekjed.kern.wiskunde;
import std.math;

alias Quat = Quaternion!nauwkeurigheid;

struct Quaternion(Soort = nauw) {
	alias QuatSoort = Quaternion!Soort;
	Soort r = 1;
	Vec!(3, Soort) v = Vec!(3, Soort)(0);

	this(Soort r, Vec!(3, Soort) v) {
		this.r = r;
		this.v = v;
	}

	this(Soort r, Soort x, Soort y, Soort z) {
		this.r = r;
		this.v = Vec!(3, Soort)([x, y, z]);
	}

	auto opBinary(string op)(const QuatSoort r) const if (op == "*") {
		alias l = this;
		return QuatSoort(l.r * r.r - l.v.inp(r.v), r.v * l.r + l.v * r.r + l.v.uitp(r.v));
	}

	// Draai
	Vec!(3, Soort) opBinary(string op)(const Vec!(3, Soort) r) const if (op == "*") {
		QuatSoort qr = QuatSoort(0, r);
		return (this * qr * ~this).v;
	}

	// Geconjugeerde
	auto opUnary(string op)() const if (op == "~") {
		return QuatSoort(r, -v);
	}

	static QuatSoort draai(Vec!(3, Soort) as, Soort hoek) {
		return QuatSoort(cos(hoek / 2.0), as * cast(Soort) sin(hoek / 2.0));
	}

	auto naarMat(uint n = 3)() const if (n == 3 || n == 4) {
		Mat!(n, Soort) res = Mat!(n, Soort)(1);
		res[0][0] = 1 - 2 * v.y * v.y - 2 * v.z * v.z;
		res[0][1] = 2 * v.x * v.y - 2 * r * v.z;
		res[0][2] = 2 * v.x * v.z + 2 * r * v.y;
		res[1][0] = 2 * v.x * v.y + 2 * r * v.z;
		res[1][1] = 1 - 2 * v.x * v.x - 2 * v.z * v.z;
		res[1][2] = 2 * v.y * v.z - 2 * r * v.x;
		res[2][0] = 2 * v.x * v.z - 2 * r * v.y;
		res[2][1] = 2 * v.y * v.z + 2 * r * v.x;
		res[2][2] = 1 - 2 * v.x * v.x - 2 * v.y * v.y;
		return res;
	}
}
