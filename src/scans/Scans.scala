package scans

import Circuit4._

object Scans {

{
def id(x: Int)                        =  new Id1        {val n=x}
def fan(x: Int)                       =  new Fan1       {val n=x}
def above(x: Circuit1, y: Circuit1)   =  new Above1     {val c1=x; val c2=y}
def beside(x: Circuit1, y: Circuit1)  =  new Beside1    {val c1=x; val c2=y}
def stretch(x: Circuit1, xs: Int*)    =  new Stretch1   {val ns=xs.toList; val c=x}

val circuit  = above(  beside(fan(2),fan(2)),
                       above(  stretch(fan(2),2,2),
                               beside(beside(id(1),fan(2)),id(1))))
println(circuit.width)
}



trait Circuit5 extends Circuit2 with Circuit3 with Circuit4
trait Id5 extends Id2 with Id3 with Id4 with Circuit5
trait Fan5 extends Fan2 with Fan3 with Fan4 with Circuit5
trait Beside5 extends Beside2 with Beside3 with Beside4 with Circuit5 {
  val c1, c2: Circuit5
}
trait Above5 extends Above2 with Above3 with Above4 with Circuit5 {
  val c1, c2: Circuit5
}
trait Stretch5 extends Stretch2 with Stretch3 with Stretch4 with Circuit5 {
  val c: Circuit5
}

{
def id(x: Int)                        =  new Id5  {val n=x}
def fan(x: Int)                       =  new Fan5       {val n=x}
def above(x: Circuit5, y: Circuit5)   =  new Above5     {val c1=x; val c2=y}
def beside(x: Circuit5, y: Circuit5)  =  new Beside5    {val c1=x; val c2=y}
def stretch(x: Circuit5, xs: Int*)    =  new Stretch5   {val ns=xs.toList; val c=x}

val c  = above(  beside(fan(2),fan(2)),
                 above(  stretch(fan(2),2,2),
                         beside(beside(id(1),fan(2)),id(1))))
println(c.width)
println(c.depth)
println(c.wellSized)
println(c.layout(x => x))
}
}