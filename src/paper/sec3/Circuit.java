package paper.sec3;

import java.util.List;

import lombok.Obj;


@Obj
interface Init {
//BEGIN_INIT
interface Circuit { int width(); }
interface Fan extends Circuit {
  int _n();
  default int width() { return _n(); }
}
interface Identity extends Circuit {
  int _n();
  default int width() { return _n(); }
}
interface Beside extends Circuit {
  Circuit _c1();
  Circuit _c2();
  default int width() {
    return _c1().width() + _c2().width();
  }
}
//END_INIT
//BEGIN_SYNTAX
interface Stretch extends Circuit {
  List<Integer> _ns();
  Circuit _c();
  default int width() {
    return _ns().stream().reduce(0, (a,b) -> a+b);
  }
}
interface Above extends Circuit {
  Circuit _c1();
  Circuit _c2();
  default int width() { return _c1().width(); }
}
//END_SYNTAX
}

@Obj
interface SemanticsExt extends Init {
//BEGIN_SEMANTICS
interface CircuitWS extends Circuit {
  boolean wellSized();
}
interface IdentityWS extends Identity, CircuitWS {
  default boolean wellSize() { return true; }
}
interface FanWS extends Fan, CircuitWS {
  default boolean wellSize() { return true; }
}
interface BesideWS extends Beside, CircuitWS {
  CircuitWS _c1();
  CircuitWS _c2();
  default boolean wellSized() {
    return _c1().wellSized() && _c2().wellSized();
  }
}
interface StretchWS extends Stretch, CircuitWS {
  CircuitWS _c();
  default boolean wellSized() {
    return _ns().size() == _c().width();
  }
}
interface AboveWS extends Beside, CircuitWS {
  CircuitWS _c1();
  CircuitWS _c2();
  default boolean wellSized() {
    return _c1().wellSized() && _c2().wellSized() && _c1().width() == _c2().width();
  }
}
//END_SEMANTICS
}
/*
//BEGIN_FAMILY
@Obj interface Family {
  // same code of Figure ?
}
//END_FAMILY
*/
@Obj interface Family {
  interface Circuit { int width(); }
  interface Identity extends Circuit {
    int _n();
    default int width() {
      return _n();
    }
  }
  interface Fan extends Circuit {
    int _n();
    default int width() {
      return _n();
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

/*
//BEGIN_FAMILY_SYNTAX
@Obj interface Syntax extends Family {
  // same code of Figure ?
}
//END_FAMILY_SYNTAX
*/
@Obj interface Syntax extends Family {
  interface Stretch extends Circuit {
    List<Integer> _ns();
    Circuit _c();
    default int width() {
      return _ns().stream().reduce(0, (a,b) -> a+b);
    }
  }
  interface Above extends Circuit {
    Circuit _c1();
    Circuit _c2();
    default int width() { return _c2().width(); }
  }
}

//BEGIN_FAMILY_SEMANTICS
@Obj interface Semantics extends Syntax {
  interface Circuit {
    boolean wellSized();
  }
  interface Identity {
    default boolean wellSized() { return true; }
  }
  interface Fan {
    default boolean wellSized() { return true; }
  }
  interface Beside {
    default boolean wellSized() {
      return _c1().wellSized() && _c2().wellSized();
    }
  }
  interface Stretch {
    default boolean wellSized() {
      return _ns().size() == _c().width();
    }
  }
  interface Above {
    default boolean wellSized() {
      return _c1().wellSized() && _c2().wellSized();
    }
  }
}
//END_FAMILY_SEMANTICS
interface Circuit {
  boolean wellSized();
}

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