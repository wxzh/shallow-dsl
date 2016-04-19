trait Family {
  trait Circuit { 
    def width: Int
  }
  class Identity(n: Int) extends Circuit {
    def width = n
  }
  class Fan(n: Int) extends Circuit {
    def width = n
  }
  class Above(c1: Circuit, c2: Circuit) extends Circuit {
    def width = c2.width
  }
  class Beside(c1: Circuit, c2: Circuit) extends Circuit {
    def width = c1.width + c2.width
  }
  class Stretch(ns: List[Int], c: Circuit) extends Circuit {
    def width = ns.sum
  }

  val circuit = 
    new Above(new Above(new Beside(new Fan(2), new Fan(2)), 
                        new Stretch(List(2,2), new Fan(2))),
              new Beside(new Beside(new Identity(1), new Fan(2)), new Identity(1)))

  trait CircuitWidth extends Circuit {
    def wellSize: Boolean
  }
  class IdentityWidth(n: Int) 
      extends Identity(n) with CircuitWidth {
    def wellSize = true
  }
  class FanWidth(n: Int) 
      extends Fan(n) with CircuitWidth {
    def wellSize = true
  }
  class AboveWidth(c1: CircuitWidth, c2: CircuitWidth) 
      extends Above(c1,c2) with CircuitWidth {
    def wellSize = c1.wellSize && c2.wellSize && (c1.width == c2.width)
  }
  class BesideWidth(c1: CircuitWidth, c2: CircuitWidth) 
      extends Beside(c1,c2) with CircuitWidth {
    def wellSize = c1.wellSize && c2.wellSize
  }
  class StretchWidth(ns: List[Int], c: CircuitWidth) 
      extends Stretch(ns,c) with CircuitWidth {
    def wellSize = c.wellSize && ns.length == c.width
  }

  class RStretchWidth(ns: List[Int], c: CircuitWidth) extends StretchWidth(ns,c)
}

trait ExtendedFamily extends Family {
  trait Circuit extends super.Circuit {
    def wellSize: Boolean
    def ---(other: Circuit) = new Above(this, other)
    def |||(other: Circuit) = new Beside(this, other)
    def <--(ns: Int*) = new Stretch(List(ns:_*), this)
  }
  class Identity(n: Int) 
      extends super.Identity(n) with Circuit {
    def wellSize = true
  }
  class Fan(n: Int) 
      extends super.Fan(n) with Circuit {
    def wellSize = true
  }
  class Above(c1: Circuit, c2: Circuit) 
      extends super.Above(c1,c2) with Circuit {
    def wellSize = c1.wellSize && c2.wellSize && (c1.width == c2.width)
  }
  class Beside(c1: Circuit, c2: Circuit) 
      extends super.Beside(c1,c2) with Circuit {
    def wellSize = c1.wellSize && c2.wellSize
  }
  class Stretch(ns: List[Int], c: Circuit) 
      extends super.Stretch(ns,c) with Circuit {
    def wellSize = c.wellSize && ns.length == c.width
  }
  class RStretch(ns: List[Int], c: Circuit) 
    extends super.Stretch(ns,c)

  object Identity {
    def apply(n: Int) = new Identity(n)
  }
  object Fan {
    def apply(n: Int) = new Fan(n)
  }
  object Above {
    def apply(c1: Circuit, c2: Circuit) = new Above(c1, c2)
  }
  object Beside {
    def apply(c1: Circuit, c2: Circuit) = new Beside(c1, c2)
  }
  object Stretch {
    def apply(ns: List[Int], c: Circuit) = new Stretch(ns, c)
  }

  override val circuit = (
   (Fan(2) ||| Fan(2))
   ---
   (Fan(2) <-- (2,2))
   ---
   (Identity(1) ||| Fan(2) ||| Identity(1))
  )
}

object CircuitDSL extends App {
  val c = new ExtendedFamily {}.circuit
  println(c.wellSize)
  println(c.width)
}