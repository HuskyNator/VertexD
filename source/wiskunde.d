module wiskunde;
import std.stdio;

version (HoekjeD_Double) {
	private alias standaard_vec_soort = double;
} else {
	private alias standaard_vec_soort = float;
}

struct Vec(int grootte, Soort = standaard_vec_soort) {
	Soort[grootte] inhoud;


}
