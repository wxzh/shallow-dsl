package paper.sec3;

import static java.lang.Integer.min;
import static java.util.Collections.emptyList;
import static java.util.Collections.singletonList;
import static java.util.stream.Collectors.toList;
import static java.util.stream.IntStream.range;

import java.util.ArrayList;
import java.util.List;
import java.util.function.BinaryOperator;
import java.util.function.IntUnaryOperator;
import java.util.stream.Stream;

import lombok.Obj;


//BEGIN_INIT
@Obj interface Init {
  interface Circuit { int width(); }
  interface Identity extends Circuit {
    int _n();
    default int width() { return _n(); }
  }
  interface Fan extends Circuit {
    int _n();
    default int width() { return _n(); }
  }
  interface Beside extends Circuit {
    Circuit _c1(); Circuit _c2();
    default int width() {
      return _c1().width() + _c2().width();
    }
  }
}
//END_INIT

//BEGIN_MULTIPLE
@Obj interface Multiple extends Init {
  interface Circuit { boolean wellSized(); }
  interface Identity {
    default boolean wellSized() { return _n() > 0; }
  }
  interface Fan {
    default boolean wellSized() { return _n() > 0; }
  }
  interface Beside {
    default boolean wellSized() {
      return _c1().wellSized() && _c2().wellSized();
    }
  }
}
//END_MULTIPLE

//BEGIN_SYNTAX
@Obj interface Syntax extends Init {
  interface Stretch extends Circuit {
    List<Integer> _ns();
    Circuit _c();
    default int width() {
      return _ns().stream()
        .mapToInt(Integer::intValue).sum();
    }
  }
  interface Above extends Circuit {
    Circuit _c1(); Circuit _c2();
    default int width() { return _c1().width(); }
  }
}
//END_SYNTAX

//BEGIN_DEPENDENT
@Obj interface Dependent extends Syntax, Multiple {
  interface Stretch {
    default boolean wellSized() {
      return _ns().size() == _c().width();
    }
  }
  interface Above {
    default boolean wellSized() {
      return _c1().wellSized() && _c2().wellSized()
        && _c1().width() == _c2().width();
    }
  }
}
//END_DEPENDENT

@Obj interface IntPair {
  Integer _1();
  Integer _2();
  default IntPair map(IntUnaryOperator f) {
    return IntPair.of(f.applyAsInt(_1()), f.applyAsInt(_2()));
  }
}

@Obj interface Layout {
  List<List<IntPair>> _l();
  default Layout map(IntUnaryOperator f) {
    return Layout.of(_l().stream()
            .map(xs -> xs.stream()
                    .map(pr -> pr.map(f))
                    .collect(toList()))
            .collect(toList()));
  }
}
//BEGIN_CONTEXT_SENSITIVE
@Obj interface CtxSensitive extends Dependent {
  interface Circuit {
    Layout tlayout(IntUnaryOperator f);
  }
  interface Identity {
    default Layout tlayout(IntUnaryOperator f) {
      return Layout.of(emptyList());
    }
  }
  interface Fan {
    default Layout tlayout(IntUnaryOperator f) {
      return Layout.of(singletonList(range(1, _n())
        .mapToObj(i -> IntPair.of(0,i).map(f))
        .collect(toList())));
    }
  }
  interface Above {
    default Layout tlayout(IntUnaryOperator f) {
      return Layout.of(concat(_c1().tlayout(f)._l(), _c2().tlayout(f)._l()));
    }
  }
  interface Beside {
    default Layout tlayout(IntUnaryOperator f) {
      return Layout.of(lzw(_c1().tlayout(f)._l(),
        _c2().tlayout(f)._l(), CtxSensitive::concat));
    }
  }
  interface Stretch {
    default Layout tlayout(IntUnaryOperator f) {
      return _c().tlayout(f).map(f.andThen(i ->
        scanl1(_ns(), Integer::sum).get(i)-1));
    }
  }
//END_CONTEXT_SENSITIVE
  static <E> List<E> lzw
      (List<E> xs, List<E> ys, BinaryOperator<E> f) {
    int n1 = xs.size(); int n2 = ys.size();
    int min = min(n1, n2);
    List<E> tail = n1 == min ?
      ys.subList(min, n2) : xs.subList(min, n1);
    return concat(range(0, min)
      .mapToObj(i -> f.apply(xs.get(i), ys.get(i)))
      .collect(toList()), tail);
  }
  static <E> List<E> concat(List<E> xs, List<E> ys) {
    return Stream.concat(xs.stream(), ys.stream())
      .collect(toList());
  }
  static <E> List<E> scanl1(List<E> xs, BinaryOperator<E> f) {
    E acc = xs.get(0);
    List<E> res = new ArrayList<>();
    res.add(acc);
    E v;
    for (int i = 1; i < xs.size(); i++) {
      v = f.apply(xs.get(i), acc);
      res.add(v);
      acc = v;
    }
    return res;
  }
}

//BEGIN_MERGE
@Obj interface Merge
    extends Multiple, Dependent, CtxSensitive {
}
//END_MERGE

/*
//BEGIN_INSTRUMENT
interface Beside extends Syntax.Beside, Circuit {
  Circuit _c1(); Circuit _c2();
  default boolean wellSized() {
    return _c1().wellSized() && _c2().wellSized();
  }
  static Circuit of(Circuit c1, Circuit c2) {
    return new Beside() {
      Circuit _c1 = c1; Circuit _c2 = c2;
      public Circuit _c1() { return _c1; }
      public Circuit _c2() { return _c2; }
    };
  }
}
//END_INSTRUMENT
*/