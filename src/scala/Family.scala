trait Init {
  type C <: Circuit
  trait Circuit { 
    self: C =>
    def width: Int
    def |||(c: C) = Beside(this, c)
  }
  trait Fan extends Circuit {
    self: C =>
    val n: Int
    def width = n
  }
  trait Beside extends Circuit {
    self: C =>
    val c1, c2: C
    def width = c1.width + c2.width
  }
  def Fan(i: Int): C
  def Beside(x: C, y: C): C
}

object Init extends Init {
  type C = Circuit
  def Fan(i: Int) = new Fan { val n = i }
  def Beside(x: C, y: C) = new Beside { val c1 = x; val c2 = y }
}

trait Ext extends Init {
  type C <: Circuit
  trait Circuit extends super.Circuit { 
    self: C =>
    def ---(c: C) = Above(this, c)
  }
  trait Above extends Circuit {
    self: C =>
    val c1, c2: C 
    def width = c2.width
  }
  trait Fan extends super.Fan with Circuit {
    self: C =>
  }
  trait Beside extends super.Beside with Circuit {
    self: C =>
  }
  def Above(x: C, y: C): C
}

object Ext extends Ext {
  type C = Circuit
  def Fan(i: Int) = new Fan { val n = i }
  def Beside(x: C, y: C) = new Beside { val c1 = x; val c2 = y }
  def Above(x: C, y: C): C = new Above { val c1 = x; val c2 = y }
}

object ExtTest extends App {
  import Ext._
  (Fan(1) ||| Fan(2) 
  --- 
  Fan(3))
}