package scans

object Test extends App {
  val c = above(beside(fan(2), fan(2)),
          above(stretch(List(2,2), fan(2)),
          beside(id(1), beside(fan(2), id(1)))))
  println(c.width)
  println(c.wellSized)
  println(c.depth)
  println(c.layout)
  println(draw(c.tlayout(i=>i)))
}