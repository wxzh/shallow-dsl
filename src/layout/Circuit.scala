package layout

trait Circuit extends wellsized.Circuit with depth.Circuit {
  def layout: Layout
  def tlayout(f: Int => Int): Layout
}
trait Identity extends Circuit with wellsized.Identity with depth.Identity {
  def layout = List()
  def tlayout(f: Int => Int) = List()
}
trait Fan extends Circuit with wellsized.Fan with depth.Fan {
  def layout = List(for (i <- List.range(1,n)) yield (0,i))
  def tlayout(f: Int => Int) = List(for (i <- List.range(1,n)) yield (f(0),f(i)))
}
trait Above extends Circuit with wellsized.Above with depth.Above {
  val c1, c2: Circuit
  def layout = c1.layout ++ c2.layout
  def tlayout(f: Int => Int) = c1.tlayout(f) ++ c2.tlayout(f)
}
trait Beside extends Circuit with wellsized.Beside with depth.Beside {
  val c1, c2: Circuit
  def layout = lzw (c1.layout, shift(c1.width)(c2.layout)) (_ ++ _) 
  def tlayout(f: Int => Int) = 
    lzw (c1.tlayout(f), c2.tlayout(f.andThen(c1.width + _))) (_ ++ _)
}
trait Stretch extends Circuit with wellsized.Stretch with depth.Stretch {
  val c: Circuit
  def layout = c.layout.map(_.map(connect(ns)))
  def tlayout(f: Int => Int) = c.tlayout(f.andThen(partialSum(ns)(_) - 1))
}