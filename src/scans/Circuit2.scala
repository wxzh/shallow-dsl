package scans

trait Circuit2 {
  def depth: Int
}
trait Id2 extends Circuit2 {
  def depth = 0
}
trait Fan2 extends Circuit2 {
  def depth = 1
}
trait Above2 extends Circuit2 {
  val c1, c2: Circuit2
  def depth = c1.depth + c2.depth
}
trait Beside2 extends Circuit2 {
  val c1, c2: Circuit2
  def depth = Math.max(c1.depth, c2.depth)
}
trait Stretch2 extends Stretch1 with Circuit2 {
  val c: Circuit2
  def depth = c.depth
}

trait Circuit12 extends Circuit1 with Circuit2
trait Id12 extends Circuit12 with Id1 with Id2
trait Fan12 extends Circuit12 with Fan1 with Fan2
trait Above12 extends Circuit12 with Above1 with Above2 { override val c1, c2: Circuit12 }
trait Beside12 extends Circuit12 with Beside1 with Beside2 { override val c1, c2: Circuit12 }
trait Stretch12 extends Circuit12 with Stretch1 with Stretch2 { override val c: Circuit12 }