package desugar

trait Set extends base.Set {
  def opt(m: Int, n: Int): Set = this
}
class None extends base.None with Set {}
class All extends base.All with Set {
  override  def opt(m: Int, n: Int) = new Limit(m, n, this)
}
class Limit(m1:Int, n1:Int, s:Set) extends base.Limit(m1,n1,s) with Set {
  override def opt(m: Int, n: Int): Set = {
    val maxM = Math.max(m, m1)
    val minN = Math.min(n, n1)
    if (maxM < minN) new Limit(maxM, minN, s) else new None
  }
}
class Union(s1: Set, s2: Set) extends base.Union(s1,s2) with Set {
  override def opt(m: Int, n: Int) = new Limit(m, n, this)
}

object Test extends App {
  val c = new Beside(new Fan(3), new Identity(3))
  println(c.width)
}
