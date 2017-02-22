//BEGIN_CIRCUIT_SCALA
package width
trait Circuit { 
  def width: Int 
}
class Identity(n: Int) extends Circuit {
  def width = n
}
class Fan(n: Int) extends Circuit {
  def width = n
}
class Beside(c1: Circuit, c2: Circuit) extends Circuit {
  def width = c1.width + c2.width
}
class Above(c1: Circuit, c2: Circuit) extends Circuit {
  def width = c1.width
}
class Stretch(ns: List[Int], c: Circuit) extends Circuit {
  def width = ns.sum
}
//END_CIRCUIT_SCALA