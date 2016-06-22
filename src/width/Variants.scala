//BEGIN_VARIANT_SCALA
package width
trait Above extends Circuit {
  val c1, c2: Circuit
  def width = c1.width
}
trait Stretch extends Circuit {
  val ns: List[Int]
  val c: Circuit
  def width = ns.sum
}
//END_VARIANT_SCALA