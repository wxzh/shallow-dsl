package depth
trait Circuit extends width.Circuit { 
  def depth: Int 
}
trait Id extends width.Id with Circuit {
  def depth = 0
}
trait Fan extends width.Fan with Circuit {
  def depth = 1
}
trait Above extends width.Above with Circuit {
  val c1, c2: Circuit
  def depth = c1.depth + c2.depth
}
trait Beside extends width.Beside with Circuit {
  val c1, c2: Circuit
  def depth = Math.max(c1.depth, c2.depth)
}
trait Stretch extends width.Stretch with Circuit {
  val c: Circuit
  def depth = c.depth
}