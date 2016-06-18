package desugar
//BEGIN_DESUGAR_SCALA
trait Circuit extends base.Circuit {
  def desugar: Circuit = this
}
class Fan(val n: Int) 
    extends base.Fan(n) with Circuit
class Beside(val c1: Circuit, val c2: Circuit) 
    extends base.Beside(c1, c2) with Circuit {
  override def desugar = new Beside(c1.desugar, c2.desugar)
}
class Id(val n: Int) 
    extends base.Id(n) with Circuit {
  override def desugar: Circuit = {
    val fan1: Circuit = new Fan(1)
    (1 until n) map{_=>fan1} reduce{new Beside(_,_)}
  }
}
//END_DESUGAR_SCALA