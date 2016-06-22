import javax.swing.SwingUtilities
import javax.swing.JFrame

package object scans {
  import layout._  
  def id(x: Int) = new Id{val n=x}
  def fan(x: Int) = new Fan{val n=x}
  def above(x: Circuit, y: Circuit) = new Above{val c1=x; val c2=y}
  def beside(x: Circuit, y: Circuit) = new Beside{val c1=x; val c2=y}
  def stretch(xs: List[Int], x: Circuit) = new Stretch{val ns=xs; val c=x}

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