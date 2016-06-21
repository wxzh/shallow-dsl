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
  override def mergeIds: Circuit = {
    val (d1,d2) = (c1.mergeIds,c2.mergeIds)
    (d1,d2) match {
      case (Id(n1),Id(n2)) => Id(n1 + n2)
      case _ => new Beside{val c1=d1; val c2=d2}
    }
  }
}
//END_MERGEIDS_SCALA