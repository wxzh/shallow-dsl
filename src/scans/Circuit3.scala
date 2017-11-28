package scans

trait Circuit3 extends Circuit1 {
  def wellSized: Boolean
}
trait Id3 extends Id1 with Circuit3 {
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