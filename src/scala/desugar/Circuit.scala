package desugar
//BEGIN_DESUGAR_SCALA
trait Circuit extends base.Circuit {
  def desugar: Circuit
}
class Fan(n: Int) 
    extends base.Fan(n) with Circuit {
  def desugar = this
}
class Beside(c1: Circuit, c2: Circuit) 
    extends base.Beside(c1, c2) with Circuit {
  def desugar = new Beside(c1.desugar, c2.desugar)
}
class Identity(n: Int) 
    extends base.Identity(n) with Circuit {
  def desugar = {
    val fan1: Circuit = new Fan(1)
    (1 until n) map{_=>fan1} reduce{new Beside(_,_)}
  }
}
//END_DESUGAR_SCALA