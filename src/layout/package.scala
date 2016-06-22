package object layout {
  type IntPair = Tuple2[Int,Int]
  type Layout = List[List[IntPair]] 
  def lzw[A](xs: List[A], ys: List[A])(f: (A, A) => A): List[A] = (xs, ys) match {
    case (Nil,_) => ys
    case (_,Nil) => xs
    case (x::xs,y::ys) => f(x,y)::lzw(xs,ys)(f)
  }
  def pmap[A,B](f: A => B)(p: Tuple2[A,A]): Tuple2[B,B] = p match {
    case (x, y) => (f(x), f (y))
  }
  def shift(w: Int)(layout: Layout) = layout.map(_.map(pmap(w+_)))
  def connect(ns: List[Int])(p: IntPair) =
    pmap ((i: Int) => partialSum(ns)(i) - 1) (p)
  def partialSum(ns: List[Int]): List[Int] = ns.scanLeft(0)(_ + _).tail
}