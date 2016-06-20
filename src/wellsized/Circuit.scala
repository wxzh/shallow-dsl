//BEGIN_MULTIPLE_SCALA
package wellsized
trait Circuit extends width.Circuit { 
  def wellSized: Boolean 
}
trait Id extends width.Id with Circuit {
  def wellSized = n > 0
}
trait Fan extends width.Fan with Circuit {
  def wellSized = n > 0
}
trait Beside extends width.Beside with Circuit {
  val c1, c2: Circuit // type refined!
  def wellSized = c1.wellSized && c2.wellSized
}
//END_MULTIPLE_SCALA

//BEGIN_VARIANT
trait Above extends Circuit {
  val c1, c2: Circuit
  def width = c1.width
  def wellSized = 
    c1.wellSized && c2.wellSized && c1.width == c2.width
}
trait Stretch extends Circuit {
  val ns: List[Int]
  val c: Circuit
  def width = ns.sum
  def wellSized = c.wellSized && ns.length == c.width
}
//END_VARIANT