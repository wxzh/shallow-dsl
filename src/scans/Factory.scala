package scans

import Scans._

object Factory extends App {
trait Circuit[C] {
  def id(x: Int): C
  def fan(x: Int): C
  def above(x: C, y: C): C
  def beside(x: C, y: C): C
  def stretch(x: C, xs: Int*): C
}

trait Factory1 extends Circuit[Circuit1] {
  def id(x: Int)                        =  new Id1        {val n=x}
  def fan(x: Int)                       =  new Fan1       {val n=x}
  def above(x: Circuit1, y: Circuit1)   =  new Above1     {val c1=x; val c2=y}
  def beside(x: Circuit1, y: Circuit1)  =  new Beside1    {val c1=x; val c2=y}
  def stretch(x: Circuit1, xs: Int*)    =  new Stretch1   {val ns=xs.toList; val c=x}
}

import Circuit4._
trait Factory4 extends Circuit[Circuit4] {
  def id(x: Int)                        =  new Id4        {val n=x}
  def fan(x: Int)                       =  new Fan4       {val n=x}
  def above(x: Circuit4, y: Circuit4)   =  new Above4     {val c1=x; val c2=y}
  def beside(x: Circuit4, y: Circuit4)  =  new Beside4    {val c1=x; val c2=y}
  def stretch(x: Circuit4, xs: Int*)    =  new Stretch4   {val ns=xs.toList; val c=x}
}

def circuit[C](f: Circuit[C]) =
  f.above (  f.beside(f.fan(2),f.fan(2)),
             f.above (  f.stretch(f.fan(2),2,2),
                        f.beside(f.beside(f.id(1),f.fan(2)),f.id(1))))

println(circuit(new Factory1{}).width) // 4 
println(circuit(new Factory4{}).layout { x => x }) // List(List((0,1), (2,3)), List((1,3)), List((1,2)))

trait ExtendedCircuit[C] extends Circuit[C] {
  def rstretch(x: C, xs: Int*): C
}
trait ExtendedFactory4 extends ExtendedCircuit[Circuit4] with Factory4 {
  def rstretch(x: Circuit4, xs: Int*) = new RStretch {val c=x; val ns=xs.toList}
}

def circuit2[C](f: ExtendedCircuit[C]) = f.rstretch(circuit(f),2,2,2,2)

println(circuit2(new ExtendedFactory4{}).layout { x => x }) // List(List((1,3), (5,7)), List((3,7)), List((3,5)))
}