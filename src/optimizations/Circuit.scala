package optimizations

//BEGIN_MERGEIDS_SCALA
trait Circuit extends width.Circuit {
  def mergeIds: Circuit = this
}
trait Id extends width.Id with Circuit
object Id {
  def apply(i: Int) = new Id{val n=i}
  def unapply(c: Id) = Some(c.n)
}
trait Fan extends width.Fan with Circuit
trait Beside extends width.Beside with Circuit {
  val c1, c2: Circuit
  override def mergeIds = 
    (c1.mergeIds,c2.mergeIds) match {
      case (Id(n1),Id(n2)) => Id(n1 + n2)
      case _ => Beside(c1.mergeIds, c2.mergeIds)
  }
}
//END_MERGEIDS_SCALA
object Beside {
  def apply(x: Circuit, y: Circuit): Circuit = new Beside{val c1=x; val c2=y}
}