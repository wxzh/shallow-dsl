//BEGIN_DEPENDENT_SCALA
package wellsized
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