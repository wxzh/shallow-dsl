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

object Alterative {
trait Id3 extends Circuit3 { def wellSized = true }
trait Fan3 extends Circuit3 { def wellSized = true }
trait Above3 extends Circuit3 {
  val c1, c2: Circuit3
  def wellSized = c1.wellSized && c2.wellSized && c1.width==c2.width
}
trait Beside3 extends Circuit3 {
  val c1, c2: Circuit3
  def wellSized = c1.wellSized && c2.wellSized
}
trait Stretch3 extends Circuit3 {
  val c: Circuit3
  val ns: List[Int]
  def wellSized = c.wellSized && ns.length==c.width
}

trait Id13 extends Id1 with Id3
trait Fan13 extends Fan1 with Fan3
trait Above13 extends Above1 with Above3
trait Beside13 extends Beside1 with Beside3 
trait Stretch13 extends Stretch1 with Stretch3
}