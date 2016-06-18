//BEGIN_CIRCUIT_SCALA
package base
trait Circuit { def width: Int }
class Identity(val n: Int) extends Circuit {
  def width = n
}
class Fan(val n: Int) extends Circuit {
  def width = n
}
class Beside(val c1: Circuit, val c2: Circuit) 
    extends Circuit {
  def width = c1.width + c2.width
}
//END_CIRCUIT_SCALA
