package paper;

import java.util.List;

import lombok.Obj;


interface namespace {
@Obj
//BEGIN_CIRCUIT
interface Circuit { int width(); }
//END_CIRCUIT
@Obj
//BEGIN_FAN
interface Fan extends Circuit {
  int _n();
  default int width() { return _n(); }
}
//END_FAN

//BEGIN_STRETCH
interface Stretch extends Circuit {
  List<Integer> _ns();
  Circuit _c();
  default int width() {
    return _ns().stream().reduce(0, (a,b) -> a+b);
  }
}
//END_STRETCH
@Obj
//BEGIN_BESIDE
interface Beside extends Circuit {
  Circuit _c1();
  Circuit _c2();
  default int width() {
    return _c1().width() + _c2().width();
  }
}
//END_BESIDE
@Obj
//BEGIN_ID
//interface Identity extends Circuit {
//  int _n();
//  default int width() { return _n(); }
//}
//END_ID
interface Identity extends Circuit {
  int _n();
  default int width() {
    return _n();
  }
  default Circuit desugar() {
    Circuit res = Fan.of(1);
    for (int i = 1; i < _n(); i++)
      res = Beside.of(res, Fan.of(1));
    return res;
  }
}

@Obj
//BEGIN_ABOVE
interface Above extends Circuit {
  Circuit _c1();
  Circuit _c2();
  default int width() { return _c2().width(); }
}
//END_ABOVE

@Obj
//BEGIN_CIRCUITWS
interface CircuitWS extends Circuit {
  boolean wellSized();
}
//END_CIRCUITWS
@Obj
//BEGIN_FANWS
interface FanWS extends Fan, CircuitWS {
  default boolean wellSize() { return true; }
}
//END_FANWS
@Obj
//BEGIN_STRETCHWS
interface StretchWS extends Stretch, CircuitWS {
  CircuitWS _c();
  default boolean wellSized() {
    return _ns().size() == _c().width();
  }
}
//END_STRETCHWS
@Obj
//BEGIN_BESIDEWS
interface BesideWS extends Beside, CircuitWS {
  CircuitWS _c1();
  CircuitWS _c2();
  default boolean wellSized() {
    return _c1().wellSized() && _c2().wellSized();
  }
}
//END_BESIDEWS
}
/*
//BEGIN_FAMILY
@Obj interface Family {
  // the same code in Figure .
  ...
}
//END_FAMILY
*/
@Obj interface Family {
  interface Circuit { int width(); }
  interface Fan extends Circuit {
    int _n();
    default int width() {
      return _n();
    }
  }
  interface Stretch extends Circuit {
    List<Integer> _ns();
    Circuit _c();
    default int width() {
      return _ns().stream().reduce(0, (a,b) -> a+b);
    }
  }
  interface Beside extends Circuit {
    Circuit _c1();
    Circuit _c2();
    default int width() {
      return _c1().width() + _c2().width();
    }
  }
}


//BEGIN_FAMILY_SYNTAX
@Obj interface NewSyntax extends Family {
  interface Identity extends Circuit {
    int _n();
    default int width() { return _n(); }
  }
  interface Above extends Circuit {
    Circuit _c1();
    Circuit _c2();
    default int width() { return _c2().width(); }
  }
}
//END_FAMILY_SYNTAX

//BEGIN_FAMILY_SEMANTICS
@Obj interface NewSemantics extends Family {
  interface Circuit { boolean wellSized(); }
  interface Fan extends Circuit {
    default boolean wellSized() { return true; }
  }
  interface Stretch extends Circuit {
    default boolean wellSized() {
      return _ns().size() == _c().width();
    }
  }
  interface Beside extends Circuit {
    default boolean wellSized() {
      return _c1().wellSized() && _c2().wellSized();
    }
  }
}
//END_FAMILY_SEMANTICS