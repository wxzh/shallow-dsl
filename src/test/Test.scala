package test

object SimpleTest {
//BEGIN_CLIENT_SCALA
import width._
new Beside(new Fan(3), new Identity(3)).width // 6
//END_CLIENT_SCALA
}

object Test extends App {
  import layout._
//  val c = above(beside(fan(2), fan(2)),
//          above(stretch(List(2,2), fan(2)),
//          beside(identity(1), beside(fan(2), identity(1)))))


  val c = beside(identity(2),
          rstretch(List(2,3,1), fan(3)))

  println(c.width)
  println(c.wellSized)
  println(c.depth)
  println(c.tlayout(i=>i))
//  println(draw(c.tlayout(i=>i)))
}