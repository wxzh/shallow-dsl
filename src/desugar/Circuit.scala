package desugar

//BEGIN_DESUGAR_SCALA
trait Circuit extends width.Circuit {
  def desugar: Circuit
}
trait Fan extends width.Fan with Circuit {
  def desugar = this
}
trait Beside extends width.Beside with Circuit {
  val c1, c2: Circuit
  def desugar = Beside(c1.desugar, c2.desugar)
}
trait Id extends width.Id with Circuit {
  def desugar = 
    List.fill(n)(Fan(1)).reduce(Beside(_,_))
}
//END_DESUGAR_SCALA
//BEGIN_COMPANION
object Fan {
  def apply(x: Int): Circuit = new Fan{val n=x}
}
object Beside {
  def apply(x: Circuit, y: Circuit): Circuit = 
    new Beside{ val c1 = x; val c2 = y }
}
//END_COMPANION