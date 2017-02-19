//BEGIN_DEPENDENT_SCALA
package wellsized
trait Circuit extends width.Circuit { 
  def wellSized: Boolean 
}
trait Identity extends width.Identity with Circuit {
  def wellSized = n > 0
}
trait Fan extends width.Fan with Circuit {
  def wellSized = n > 0
}
trait Beside extends width.Beside with Circuit {
  val c1, c2: Circuit
  def wellSized = c1.wellSized && c2.wellSized
}
trait Above extends Circuit with width.Above {
  val c1, c2: Circuit
  def wellSized = c1.wellSized && c2.wellSized && 
    c1.width==c2.width
}
trait Stretch extends Circuit with width.Stretch {
  val c: Circuit
  def wellSized = c.wellSized && ns.length==c.width
}
//END_DEPENDENT_SCALA