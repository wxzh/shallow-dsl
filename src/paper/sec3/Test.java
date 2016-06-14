package paper.sec3;

import java.util.List;

interface A {
    void f();
}
interface B extends A {
    void g();
}

interface As {
  List<? extends A> as();
  default void f() {
      as().get(0).f();
  }
}

interface Bs extends As {
  @Override List<? extends B> as();

  default void g() {
      as().get(0).g();
  }
}
