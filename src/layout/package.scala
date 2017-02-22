package object layout {
  import javax.swing._

  def identity(x: Int) = new Identity{val n=x}
  def fan(x: Int) = new Fan{val n=x}
  def above(x: Circuit, y: Circuit) = new Above{val c1=x; val c2=y}
  def beside(x: Circuit, y: Circuit) = new Beside{val c1=x; val c2=y}
  def stretch(xs: List[Int], x: Circuit) = new Stretch{val ns=xs; val c=x}
  def rstretch(ns: List[Int], c: Circuit) = stretch (1 :: ns, beside(c, identity(ns.last - 1)))

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
  def partialSum(ns: List[Int]): List[Int] = ns.scanLeft(0)(_ + _) tail
  def rPartialSum(ns: List[Int]): List[Int] = ns.scanLeft(ns.last)(_ + _) init

  def draw(layout: Layout) = SwingUtilities.invokeLater(new Runnable() {
    override def run {
      val frame = new JFrame
      frame.setTitle("Draw Circuit")
      frame.setResizable(false)
      frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
      frame.getContentPane().add(new DrawCircuit(layout));
      frame.pack();
      frame.setVisible(true);
    }
  })
}