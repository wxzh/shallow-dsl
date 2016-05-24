package paper.sec2;

import static java.util.stream.IntStream.range;

class A {
//BEGIN_CIRCUIT_OO
abstract class Circuit {
  abstract int width();
}
class Fan extends Circuit {
  int _n;
  Fan(int n) { _n = n; }
  int width() { return _n; }
}
class Beside extends Circuit {
  Circuit _c1, _c2;
  Beside(Circuit c1, Circuit c2) {
    _c1 = c1; c2 = _c2;
  }
  int width() { return _c1.width() + _c2.width(); }
}
class Identity extends Circuit {
  int _n;
  Identity(int n) { _n = n; }
  int width() { return _n; }
}
//END_CIRCUIT_OO
}
class Sec2 {
//BEGIN_DESUGAR_OO
abstract class Circuit {
  abstract int width();
  abstract Circuit desugar();
}
class Fan extends Circuit {
  int _n;
  Fan(int n) { _n = n; }
  int width() { return _n; }
  Circuit desugar() { return this; }
}
class Beside extends Circuit {
  Circuit _c1, _c2;
  Beside(Circuit c1, Circuit c2) {
    _c1 = c1; c2 = _c2;
  }
  int width() { return _c1.width() + _c2.width(); }
  Circuit desugar() {
    return new Beside(_c1.desugar(), _c2.desugar());
  }
}
class Identity extends Circuit {
  int _n;
  Identity(int n) { _n = n; }
  int width() { return _n; }
  Circuit desugar() {
    Circuit fan1 = new Fan(1);
    return range(1, _n)
      .mapToObj(i -> fan1)
      .reduce(fan1, (x,y) -> new Beside(x,y));
  }
}
//END_DESUGAR_OO
}