//BEGIN_CIRCUIT_SCALA
package width
trait Circuit { def width: Int }
trait Fan extends Circuit {
  val n: Int 
  def width = n
}
trait Id extends Circuit {
  val n: Int
  def width = n
}
trait Beside extends Circuit {
  val c1, c2: Circuit
  def width = c1.width + c2.width
}
//END_CIRCUIT_SCALA