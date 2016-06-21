package desugar

//BEGIN_DESUGAR_SCALA
trait Circuit extends width.Circuit {
  def desugar: Circuit = this
}
trait Fan extends width.Fan with Circuit
object Fan {
  def apply(x: Int): Circuit = new Fan{val n=x}
}
trait Beside extends width.Beside with Circuit {
  val c1, c2: Circuit
  override def desugar =
    Beside(c1.desugar, c2.desugar)
}
object Beside {
  def apply(x: Circuit, y: Circuit): Circuit = 
    new Beside{val c1=x; val c2=y}
}
trait Id extends width.Id with Circuit {
  override def desugar =
    List.fill(n)(Fan(1)).reduce(Beside(_,_))
}
//END_DESUGAR_SCALA