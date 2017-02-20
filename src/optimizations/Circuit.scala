package optimizations

//BEGIN_MERGEIDS_SCALA
trait Circuit extends width.Circuit {
  def merge: Circuit = this
}
trait Id extends width.Id with Circuit
trait Fan extends width.Fan with Circuit
trait Beside extends width.Beside with Circuit {
  val c1, c2: Circuit
  override def merge = (c1.merge, c2.merge) match { 
    case (Id(n1), Id(n2)) => id(n1 + n2) 
    case _ => beside(c1.merge, c2.merge)
  }
}
//END_MERGEIDS_SCALA
//BEGIN_EXTRACTOR
object Id { def unapply(x: Id) = Some(x.n) }
//END_EXTRACTOR