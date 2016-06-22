package width

trait Set {
  def exists(m: Int, n: Int): Boolean
}
class None extends Set {
  override def exists(m: Int, n: Int) = false
}
class All extends Set {
  override def exists(m: Int, n: Int) = true
}
class Limit(m1: Int, n1: Int, s: Set) extends Set {
  override def exists(m: Int, n: Int) = {
    val maxM = Math.max(m, m1)
    val minN = Math.min(n, n1)
    maxM <= minN && s.exists(maxM, minN)
  }
}
class Union(s1: Set, s2: Set) extends Set {
  override def exists(m: Int, n: Int) =
    s1.exists(m, n) || s2.exists(m, n)
}