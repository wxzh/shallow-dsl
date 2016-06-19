//BEGIN_MERGEIDS_SCALA
trait Circuit extends base.Circuit {
  def mergeIds: Circuit = this
}
class Id(val n: Int) extends base.Id(n) with Circuit
object Id {
  def unapply(c: Id) = Some(c.n)
}
class Fan(val n: Int) 
    extends base.Fan(n) with Circuit
class Beside(val c1: Circuit, val c2: Circuit)
    extends base.Beside(c1, c2) with Circuit {
  override def mergeIds: Circuit = {
    val (d1, d2) = (c1.mergeIds, c2.mergeIds)
    (d1, d2) match {
      case (Id(n1), Id(n2)) => new Id(n1 + n2)
      case _ => new Beside(d1, d2)
    }
  }
}
//END_MERGEIDS_SCALA