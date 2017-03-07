package scans

object Scans {
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

{
def identity(x: Int)                  =  new Identity1  {val n=x}
def fan(x: Int)                       =  new Fan1       {val n=x}
def above(x: Circuit1, y: Circuit1)   =  new Above1     {val c1=x; val c2=y}
def beside(x: Circuit1, y: Circuit1)  =  new Beside1    {val c1=x; val c2=y}
def stretch(x: Circuit1, xs: Int*)    =  new Stretch1   {val ns=xs.toList; val c=x}

val c  = above(  beside(fan(2),fan(2)),
                 above(  stretch(fan(2),2,2),
                         beside(beside(identity(1),fan(2)),identity(1))))
println(c.width)
}

trait Circuit2 extends Circuit1 {
  def depth: Int
}
trait Identity2 extends Identity1 with Circuit2 {
  def depth = 0
}
trait Fan2 extends Fan1 with Circuit2 {
  def depth = 1
}
trait Above2 extends Above1 with Circuit2 {
  val c1, c2: Circuit2
  def depth = c1.depth + c2.depth
}
trait Beside2 extends Beside1 with Circuit2 {
  val c1, c2: Circuit2
  def depth = Math.max(c1.depth, c2.depth)
}
trait Stretch2 extends Stretch1 with Circuit2 {
  val c: Circuit2
  def depth = c.depth
}

trait Circuit3 extends Circuit1 {
  def wellSized: Boolean
}
trait Identity3 extends Identity1 with Circuit3 {
  def wellSized = true
}
trait Fan3 extends Fan1 with Circuit3 {
  def wellSized = true
}
trait Above3 extends Above1 with Circuit3 {
  val c1, c2: Circuit3
  def wellSized = c1.wellSized && c2.wellSized && c1.width==c2.width
}
trait Beside3 extends Beside1 with Circuit3 {
  val c1, c2: Circuit3
  def wellSized = c1.wellSized && c2.wellSized
}
trait Stretch3 extends Stretch1 with Circuit3 {
  val c: Circuit3
  def wellSized = c.wellSized && ns.length==c.width
}

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

trait Circuit5 extends Circuit2 with Circuit3 with Circuit4
trait Identity5 extends Identity2 with Identity3 with Identity4 with Circuit5
trait Fan5 extends Fan2 with Fan3 with Fan4 with Circuit5
trait Beside5 extends Beside2 with Beside3 with Beside4 with Circuit5 {
  val c1, c2: Circuit5
}
trait Above5 extends Above2 with Above3 with Above4 with Circuit5 {
  val c1, c2: Circuit5
}
trait Stretch5 extends Stretch2 with Stretch3 with Stretch4 with Circuit5 {
  val c: Circuit5
}

{
def identity(x: Int)                  =  new Identity5  {val n=x}
def fan(x: Int)                       =  new Fan5       {val n=x}
def above(x: Circuit5, y: Circuit5)   =  new Above5     {val c1=x; val c2=y}
def beside(x: Circuit5, y: Circuit5)  =  new Beside5    {val c1=x; val c2=y}
def stretch(x: Circuit5, xs: Int*)    =  new Stretch5   {val ns=xs.toList; val c=x}

val c  = above(  beside(fan(2),fan(2)),
                 above(  stretch(fan(2),2,2),
                         beside(beside(identity(1),fan(2)),identity(1))))
println(c.width)
println(c.depth)
println(c.wellSized)
println(c.tlayout(x => x))
}
}