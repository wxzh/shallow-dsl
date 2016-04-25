package paper.sec2;

class A {
//BEGIN_CIRCUIT_OO
interface Circuit { int width(); }
class Fan implements Circuit {
  int _n;
  Fan(int n) { _n = n; }
  public int width() { return _n; }
}
class Beside implements Circuit {
  Circuit _c1, _c2;
  Beside(Circuit c1, Circuit c2) {
    _c1 = c1; c2 = _c2;
  }
  public int width() {
    return _c1.width() + _c2.width();
  }
}
class Identity implements Circuit {
  int _n;
  Identity(int n) { _n = n; }
  public int width() { return _n; }
}
//END_CIRCUIT_OO
}
class Sec2 {
//BEGIN_DESUGAR_OO
interface Circuit {
  int width();
  Circuit desugar();
}
class Fan implements Circuit {
  int _n;
  Fan(int n) { _n = n; }
  public int width() { return _n; }
  public Circuit desugar() { return this; }
}
class Beside implements Circuit {
  Circuit _c1, _c2;
  Beside(Circuit c1, Circuit c2) {
    _c1 = c1; c2 = _c2;
  }
  public int width() {
    return _c1.width() + _c2.width();
  }
  public Circuit desugar() {
    return new Beside(_c1.desugar(), _c2.desugar());
  }
}
class Identity implements Circuit {
  int _n;
  Identity(int n) { _n = n; }
  public int width() { return _n; }
  public Circuit desugar() {
    Circuit res = new Fan(1);
    for (int i = 1; i < _n; i++)
      res = new Beside(res, new Fan(1));
    return res;
  }
}
//END_DESUGAR_OO
}