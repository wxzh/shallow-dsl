package scans

import Scans._

object Factory extends App {
trait Factory[Circuit] {
  def id(x: Int): Circuit
  def fan(x: Int): Circuit
  def above(x: Circuit, y: Circuit): Circuit
  def beside(x: Circuit, y: Circuit): Circuit
  def stretch(x: Circuit, xs: Int*): Circuit
}

trait Factory1 extends Factory[Circuit1] {
  def id(x: Int)                        =  new Id1  {val n=x}
  def fan(x: Int)                       =  new Fan1       {val n=x}
  def above(x: Circuit1, y: Circuit1)   =  new Above1     {val c1=x; val c2=y}
  def beside(x: Circuit1, y: Circuit1)  =  new Beside1    {val c1=x; val c2=y}
  def stretch(x: Circuit1, xs: Int*)    =  new Stretch1   {val ns=xs.toList; val c=x}
}

import Circuit4._
trait Factory4 extends Factory[Circuit4] {
  def id(x: Int)                        =  new Id4  {val n=x}
  def fan(x: Int)                       =  new Fan4       {val n=x}
  def above(x: Circuit4, y: Circuit4)   =  new Above4     {val c1=x; val c2=y}
  def beside(x: Circuit4, y: Circuit4)  =  new Beside4    {val c1=x; val c2=y}
  def stretch(x: Circuit4, xs: Int*)    =  new Stretch4   {val ns=xs.toList; val c=x}
}

def c[Circuit](f: Factory[Circuit]) =
  f.above (  f.beside(f.fan(2),f.fan(2)),
             f.above (  f.stretch(f.fan(2),2,2),
                        f.beside(f.beside(f.id(1),f.fan(2)),f.id(1))))

println(c(new Factory1{}).width) // 4 
println(c(new Factory4{}).tlayout { x => x }) // List(List((0,1), (2,3)), List((1,3)), List((1,2)))

trait ExtendedFactory[Circuit] extends Factory[Circuit] {
  def rstretch(x: Circuit, xs: Int*): Circuit
}
trait ExtendedFactory4 extends ExtendedFactory[Circuit4] with Factory4 {
  def rstretch(x: Circuit4, xs: Int*) = new RStretch {val c=x; val ns=xs.toList}
}

def c2[Circuit](f: ExtendedFactory[Circuit]) = f.rstretch(c(f),2,2,2,2)

println(c2(new ExtendedFactory4{}).tlayout { x => x }) // List(List((1,3), (5,7)), List((3,7)), List((3,5)))
}