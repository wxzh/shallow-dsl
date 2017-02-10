//BEGIN_CIRCUIT_SCALA
package width
trait Circuit { def width: Int }
trait Id extends Circuit {
  val n: Int
  def width = n
}
trait Fan extends Circuit {
  val n: Int 
  def width = n
}
trait Beside extends Circuit {
  val c1, c2: Circuit
  def width = c1.width + c2.width
}
//END_CIRCUIT_SCALA
trait Above extends Circuit {
  val c1, c2: Circuit
  def width = c1.width
}
trait Stretch extends Circuit {
  val ns: List[Int]
  val c: Circuit
  def width = ns.sum
}