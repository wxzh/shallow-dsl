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
