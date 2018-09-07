package scans

// object interface
trait Circuit1 {
  def width: Int
}
// concrete implementations
trait Id1 extends Circuit1 {
  val n: Int
  def width = n
}
trait Fan1 extends Circuit1 {
  val n: Int
  def width = n
}
trait Beside1 extends Circuit1 {
  val c1, c2: Circuit1
  def width = c1.width + c2.width
}
trait Above1 extends Circuit1 {
  val c1, c2: Circuit1
  def width = c1.width
}
trait Stretch1 extends Circuit1 {
  val ns: List[Int]
  val c: Circuit1
  def width = ns.sum
}