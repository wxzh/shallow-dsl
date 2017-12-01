package scans

object Circuit4 {
trait Circuit4 extends Circuit1 {
  def layout(f: Int => Int): List[List[(Int,Int)]]
}
trait Id4 extends Id1 with Circuit4 {
  def layout(f: Int => Int) = List()
}
trait Fan4 extends Fan1 with Circuit4 {
  def layout(f: Int => Int) = List(for (i <- List.range(1,n)) yield (f(0),f(i)))
}
trait Above4 extends Above1 with Circuit4 {
  val c1, c2: Circuit4
  def layout(f: Int => Int) = c1.layout(f) ++ c2.layout(f)
}
trait Beside4 extends Beside1 with Circuit4 {
  val c1, c2: Circuit4
  def layout(f: Int => Int) = lzw (c1 layout f, c2.layout(f compose (c1.width + _))) (_ ++ _)
}
trait Stretch4 extends Stretch1 with Circuit4 {
  val c: Circuit4
  def layout(f: Int => Int) = {
    val vs = ns.scanLeft(0)(_ + _).tail
    c.layout(f.compose(vs(_) - 1))
  }
}

def lzw[A](xs: List[A], ys: List[A])(f: (A, A) => A): List[A] = (xs, ys) match {
  case (Nil,_)        =>  ys
  case (_,Nil)        =>  xs
  case (x::xs,y::ys)  =>  f(x,y) :: lzw (xs,ys) (f)
}

trait RStretch extends Stretch4 {
  override def layout(f: Int => Int) = {
    val vs = ns.scanLeft(ns.last - 1)(_ + _).init
    c.layout(f.compose(vs(_)))
  }
}
}