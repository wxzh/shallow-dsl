package test

object SimpleTest {
//BEGIN_CLIENT
import width._
beside(fan(3), id(3)).width // 6
//END_CLIENT
}

object Test extends App {
  import layout._
  val c = above(beside(fan(2), fan(2)),
          above(stretch(List(2,2), fan(2)),
          beside(id(1), beside(fan(2), id(1)))))

  println(c.width)
  println(c.wellSized)
  println(c.depth)
  println(c.layout)
  println(draw(c.tlayout(i=>i)))
}