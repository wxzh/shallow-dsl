package optimizations

//BEGIN_MERGEIDS_SCALA
trait Circuit {
  def mergeIds: Circuit = this
}
trait Id extends Circuit { val n: Int }
object Id {
  def apply(i: Int) = new Id{val n=i}
  def unapply(c: Id) = Some(c.n)
}
trait Fan extends Circuit { val n: Int }
trait Beside extends Circuit {
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