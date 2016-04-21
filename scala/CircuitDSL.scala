import javax.swing.JPanel
import java.awt.Graphics2D
import java.awt.Graphics
import java.awt.Dimension
import javax.swing.SwingUtilities
import javax.swing.JFrame

trait Family {
  type Size = Int
  trait Circuit { 
    def width: Int
  }
  class Id(n: Size) extends Circuit {
    def width = n
  }
  class Fan(n: Size) extends Circuit {
    def width = n
  }
  class Above(c1: Circuit, c2: Circuit) extends Circuit {
    def width = c2.width
  }
  class Beside(c1: Circuit, c2: Circuit) extends Circuit {
    def width = c1.width + c2.width
  }
  class Stretch(ns: List[Size], c: Circuit) extends Circuit {
    def width = ns.sum
  }

  val circuit = 
    new Above(new Above(new Beside(new Fan(2), new Fan(2)), 
                        new Stretch(List(2,2), new Fan(2))),
              new Beside(new Beside(new Id(1), new Fan(2)), new Id(1)))

  trait CircuitWellSize extends Circuit {
    def wellSize: Boolean
  }
  class IdWellSize(n: Int) 
      extends Id(n) with CircuitWellSize {
    def wellSize = true
  }
  class FanWellSize(n: Int) 
      extends Fan(n) with CircuitWellSize {
    def wellSize = true
  }
  class AboveWellSize(c1: CircuitWellSize, c2: CircuitWellSize) 
      extends Above(c1,c2) with CircuitWellSize {
    def wellSize = c1.wellSize && c2.wellSize && (c1.width == c2.width)
  }
  class BesideWellSize(c1: CircuitWellSize, c2: CircuitWellSize) 
      extends Beside(c1,c2) with CircuitWellSize {
    def wellSize = c1.wellSize && c2.wellSize
  }
  class StretchWellSize(ns: List[Int], c: CircuitWellSize) 
      extends Stretch(ns,c) with CircuitWellSize {
    def wellSize = c.wellSize && ns.length == c.width
  }

  class RStretchWellSize(ns: List[Int], c: CircuitWellSize) extends StretchWellSize(ns,c)
}

trait ExtendedFamily extends Family {
  type IntPair = Tuple2[Int,Int]
  type Layout = List[List[IntPair]]

  trait Circuit extends super.Circuit {
    def wellSize: Boolean
    def layout: Layout
    def ---(other: Circuit) = new Above(this, other)
    def |||(other: Circuit) = new Beside(this, other)
    def <--(ns: Int*) = new Stretch(List(ns:_*), this)
    def draw = SwingUtilities.invokeLater(new Runnable() {
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
  class Id(n: Int) 
      extends super.Id(n) with Circuit {
    def wellSize = true
    def layout = List()
  }
  class Fan(n: Int) 
      extends super.Fan(n) with Circuit {
    def wellSize = true
    def layout = List(for (i <- List.range(1, n)) yield (0,i))
  }
  class Above(c1: Circuit, c2: Circuit) 
      extends super.Above(c1,c2) with Circuit {
    def wellSize = c1.wellSize && c2.wellSize && (c1.width == c2.width)
    def layout = c1.layout ++ c2.layout
  }
  class Beside(c1: Circuit, c2: Circuit) 
      extends super.Beside(c1,c2) with Circuit {
    def wellSize = c1.wellSize && c2.wellSize
    def layout = lzw (c1.layout, c2.layout.map(_.map(pmap(c1.width + _)))) (_ ++ _) 
  }
  class Stretch(ns: List[Int], c: Circuit) 
      extends super.Stretch(ns,c) with Circuit {
    def wellSize = c.wellSize && ns.length == c.width
    def layout = {
      val sum = ns.scanLeft(0)(_+_).tail
      c.layout.map(_.map(pmap(sum(_)-1)))
    }
  }

  def lzw[A](l1: List[A], l2: List[A])(f: (A, A) => A): List[A] = (l1, l2) match {
    case (Nil, ys) => ys
    case (xs, Nil) => xs
    case (x::xs, y::ys) => f(x, y) :: lzw (xs, ys) (f) 
  }
  def pmap[A,B](f: A => B)(p: Tuple2[A,A]): Tuple2[B,B] = p match {
    case (x, y) => (f(x), f (y))
  }

  object Id {
    def apply(n: Int) = new Id(n)
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
   (Id(1) ||| Fan(2) ||| Id(1))
  )


  class DrawCircuit(layout: Layout) extends JPanel {
    val L = 30;
    val W = 30;
    val R = 6;
    def toCoord(c: Int, r: Int) = ((c+1)*W, (r+1)*L)

    def drawDot(g: Graphics2D, p: IntPair) = 
      g.fillOval(p._1 - R/2, p._2 - R/2, R, R)

    def drawLine(g: Graphics2D, from: IntPair, to: IntPair) = 
      g.drawLine(from._1, from._2, to._1, to._2);

    override def paintComponent(g: Graphics) {
      super.paintComponent(g);
      val g2d = g.asInstanceOf[Graphics2D];
      val col = layout.flatMap { x => x.map { pr => pr._2 } }.max

      // draw vertical lines
      for (c <- 0 to col) 
        drawLine(g2d, toCoord(c, 0), toCoord(c, layout.size))
      for {
          r <- 0 to (layout.size-1)
          (x,y) <- layout(r)
      } {
        val from = toCoord(x, r)
        val to = toCoord(y, r+1)
        drawDot(g2d, from)
        drawDot(g2d, to);
        drawLine(g2d, from, to);
      }
    }

    override def getPreferredSize = new Dimension(300, 300)
  }
}

object CircuitDSL extends App {
  val c = new ExtendedFamily {}.circuit
  println(List(1,2,3).scanLeft(0)(_+_))
  println(c.wellSize)
  println(c.width)
  println(c.layout)
  c.draw
}