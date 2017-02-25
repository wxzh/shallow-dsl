package sql

import Utils._

trait SQL2 {
type O <: Operator 
type P <: Predicate
type R <: Ref

trait Operator { self: O =>
  def execOp(yld: Record => Unit) 
  def exec = Print(this).execOp { _ => }
  def WHERE(p: P): O = Filter(p,this)
  def JOIN(that: O): O = Join(this,that)
  def SELECT(fields: Field*) = {
    val (in,out) = fields.unzip(f => (f.name,f.alias))
    Project(Schema(in:_*), Schema(out:_*), this)
  }
}

trait Scan extends Operator { self: O =>
  val name: String
  def execOp(yld: Record => Unit) = processCSV(name)(yld) 
}
trait Print extends Operator { self: O =>
  val op: O
  def execOp(yld: Record => Unit) = op.execOp { r => printFields(r.fields) }
}
trait Project extends Operator { self: O =>
  val si, so: Schema
  val op: O
  def execOp(yld: Record => Unit) = op.execOp { rec => yld(Record(rec(si), so)) }
}
trait Filter extends Operator { self: O =>
  val pred: Predicate 
  val op: O
  def execOp(yld: Record => Unit) = op.execOp { rec => if (pred.eval(rec)) yld(rec) }
}
trait Join extends Operator { self: O =>
  val op1, op2: O
  def execOp(yld: Record => Unit) = op1.execOp { rec1 => 
      op2.execOp { rec2 => 
        val keys = rec1.schema intersect rec2.schema
        if (rec1(keys) == rec2(keys))
        yld(Record(rec1.fields++rec2.fields, rec1.schema++rec2.schema)) }}
}
trait Predicate {
  def eval(r: Record): Boolean 
}
trait Eq extends Predicate { self: P =>
  val ref1, ref2: R
  def eval(rec: Record) = ref1.eval(rec) == ref2.eval(rec)
}
trait Ne extends Predicate { self: P =>
  val ref1, ref2: R
  def eval(rec: Record) = ref1.eval(rec) != ref2.eval(rec) 
}
trait Ref { self: R =>
  def eval(r: Record): String 
  def ===(that: R): P  =  Eq(this,that)
  def <>(that: R): P   =  Ne(this,that)
}
trait Field extends Ref { self: R=>
  val name: String
  var alias: String
  def AS(sym: Symbol) = { alias = sym.name; this }
  def eval(rec: Record) = rec(name) 
}
trait Value extends Ref { self: R=>
  val v: Any
  def eval(r: Record) = v.toString 
}
def FROM(file: String): O
def Print(op: O): O
def Project(out: Schema, in: Schema, o: O): O
def Join(o1: O, o2: O): O
def Filter(p: P, o: O): O
def Eq(r1: R, r2: R): P
def Ne(r1: R, r2: R): P
}

object SQL2Syntax extends App with SQL2 {
type O = Operator 
type P = Predicate
type R = Ref

def FROM(file: String)                  = new Scan   {val name=file}
def Print(o: O)                         = new Print  {val op=o}
def Project(x: Schema, y: Schema, o: O) = new Project{val si=x; val so=y; val op=o}
def Join(o1: O, o2: O)                  = new Join   {val op1=o1; val op2=o2}
def Filter(p: P, o: O)                  = new Filter {val pred=p; val op=o}
def Eq(r1: R, r2: R)                    = new Eq     {val ref1=r1; val ref2=r2}
def Ne(r1: R, r2: R)                    = new Ne     {val ref1=r1; val ref2=r2}
implicit def Field(sym: Symbol)         = new Field  {val name=sym.name; var alias=name}
implicit def Value(x: String)           = new Value  {val v=x}
implicit def Value(x: Int)              = new Value  {val v=x}

val q0  =  FROM ("talks.csv")
val q1  =  q0 WHERE 'time === "09:00 AM" SELECT ('room, 'title) 
val q2  =  q0 SELECT ('time, 'room, 'title AS 'title1) JOIN 
           (q0 SELECT ('time, 'room, 'title AS 'title2)) WHERE 
           'title1 <> 'title2

List(q1,q2).foreach(_.exec)
}