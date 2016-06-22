package scans

import javax.swing.JPanel
import java.awt.Graphics2D
import java.awt.Graphics
import java.awt.Dimension
import layout._

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