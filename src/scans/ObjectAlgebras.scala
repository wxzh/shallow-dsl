package scans

/* This file illustrates how to use Object Algebras to model
   interpretation-independent terms. The file contains the following:

   - The initial parts contain the code in the paper for defining
   the interpretations for width (page 4) and tlayout (page 8-10).

   - Then, we present the Object Algebra interface (CircuitFactory[C]) that
   captures the signatures of the constructors.

   - Then we provide two concrete Object Algebras (Circuit1Factory and Circuit4Factory)
   that capture the interpretations for width and tlayout.

   - *How to construct interpretation-independent terms* is illustrated afterwards, by
   the definitions: c and c2. The definition c2 shows a slightly neater alternative
   using Scala's ability for local imports.

   Also two examples of how to "instantiate" the terms with a concrete interpretation
   are given afterwards.

   - The final part of the file shows that extensibility (the ability to add new
   language constructs) is retained by this approach. To illustrate this, we add
   "rstrech" and show how to extends the Object Algebras.
   
   - To run the file in Eclipse, right click the file, select "Run as" and select "Scala Application"

*/

object ObjectAlgebras extends App {
  // Code from page 4
  trait Circuit1 {
    def width: Int
  }
  trait Identity1 extends Circuit1 {
    val n: Int
    def width = n
  }
  trait Fan1 extends Circuit1 {
    val n: Int
    def width = n
  }
  trait Beside1 extends Circuit1 {
    val c1, c2: Circuit1
    def width = c1.width + c2.width
  }
  trait Above1 extends Circuit1 {
    val c1, c2: Circuit1
    def width = c1.width
  }
  trait Stretch1 extends Circuit1 {
    val ns: List[Int]
    val c: Circuit1
    def width = ns.sum
  }

  // Code from page 8-10
  type Layout = List[List[(Int,Int)]]
  trait Circuit4 extends Circuit1 {
    def tlayout(f: Int => Int): Layout
  }
  trait Identity4 extends Identity1 with Circuit4 {
    def tlayout(f: Int => Int) = List()
  }
  trait Fan4 extends Fan1 with Circuit4 {
    def tlayout(f: Int => Int) = List(for (i <- List.range(1,n)) yield (f(0),f(i)))
  }
  trait Above4 extends Above1 with Circuit4 {
    val c1, c2: Circuit4
    def tlayout(f: Int => Int) = c1.tlayout(f) ++ c2.tlayout(f)
  }
  trait Beside4 extends Beside1 with Circuit4 {
    val c1, c2: Circuit4
    def tlayout(f: Int => Int) = lzw (c1.tlayout(f), c2.tlayout(f.compose(c1.width + _))) (_ ++ _)
  }
  trait Stretch4 extends Stretch1 with Circuit4 {
    val c: Circuit4
    def tlayout(f: Int => Int) = {
      val vs = ns.scanLeft(0)(_ + _).tail
      c.tlayout(f.compose(vs(_) - 1))
    }
  }

  def lzw[A](xs: List[A], ys: List[A])(f: (A, A) => A): List[A] = (xs, ys) match {
    case (Nil,_)        =>  ys
    case (_,Nil)        =>  xs
    case (x::xs,y::ys)  =>  f(x,y) :: lzw (xs,ys) (f)
  }

  trait RStretch extends Stretch4 {
    override def tlayout(f: Int => Int) = {
      val vs = ns.scanLeft(ns.last - 1)(_ + _).init
      c.tlayout(f.compose(vs(_)))
    }
  }

  // An Object Algebra interface (abstract factory) describing the supported circuit constructors
  trait CircuitFactory[C] {
    def identity(x: Int): C
    def fan(x: Int): C
    def above(x: C, y: C): C
    def beside(x: C, y: C): C
    def stretch(x: C, xs: Int*): C
  }

  // Smart constructors defined for Circuit1 (page 5) are moved into an Object Algebra (concrete factory)
  class Circuit1Factory extends CircuitFactory[Circuit1] {
    def identity(x: Int)                  =  new Identity1  {val n=x}
    def fan(x: Int)                       =  new Fan1       {val n=x}
    def above(x: Circuit1, y: Circuit1)   =  new Above1     {val c1=x; val c2=y}
    def beside(x: Circuit1, y: Circuit1)  =  new Beside1    {val c1=x; val c2=y}
    def stretch(x: Circuit1, xs: Int*)    =  new Stretch1   {val ns=xs.toList; val c=x}
  }

  // Another Object Algebra that produces Circuit4
  class Circuit4Factory extends CircuitFactory[Circuit4] {
    def identity(x: Int)                  =  new Identity4  {val n=x}
    def fan(x: Int)                       =  new Fan4       {val n=x}
    def above(x: Circuit4, y: Circuit4)   =  new Above4     {val c1=x; val c2=y}
    def beside(x: Circuit4, y: Circuit4)  =  new Beside4    {val c1=x; val c2=y}
    def stretch(x: Circuit4, xs: Int*)    =  new Stretch4   {val ns=xs.toList; val c=x}
  }

  // An interpretation-independent circuit constructed via an abstract factory (page 5)
  def c[C](f: CircuitFactory[C]) =
    f.above(f.beside(f.fan(2),f.fan(2)),
            f.above(f.stretch(f.fan(2),2,2),
                    f.beside(f.beside(f.identity(1),f.fan(2)),f.identity(1))))

  // A neater alternative
  def c2[C](f: CircuitFactory[C]) = {
    import f._
    above(beside(fan(2),fan(2)),
            above(stretch(fan(2),2,2),
                    beside(beside(identity(1),fan(2)),identity(1))))
  }

  // Supplying concrete factories to allow different interpretations
  println(c(new Circuit1Factory).width) // 4 
  println(c(new Circuit4Factory).tlayout { x => x }) // List(List((0,1), (2,3)), List((1,3)), List((1,2)))

  // Circuit constructs extension
  trait ExtCircuitFactory[C] extends CircuitFactory[C] {
    def rstretch(x: C, xs: Int*): C
  }
  class ExtCircuit4Factory extends Circuit4Factory with ExtCircuitFactory[Circuit4] {
    def rstretch(x: Circuit4, xs: Int*) = new RStretch {val c=x; val ns=xs.toList}
  }
  
  // Client code for extension
  def c3[C](f: ExtCircuitFactory[C]) = {
    import f._
    rstretch(c2(f),2,2,2,2)
  }
  println(c3(new ExtCircuit4Factory).tlayout { x => x }) // List(List((1,3), (5,7)), List((3,7)), List((3,5)))
}