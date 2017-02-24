package sql

import Utils._

object SQL extends App {
trait Operator { 
  def execOp(yld: Record => Unit) 
  def exec = new Print{val op=Operator.this} execOp { _ => }
  def WHERE(p: Predicate) = new Filter{val pred=p; val op=Operator.this}
  def JOIN(that: Operator) = new Join{val op1=Operator.this; val op2=that}
  def SELECT(fields: Field*) = {
    val (in,out) = fields.unzip(f => (f.name,f.alias))
    new Project{val si=Schema(in:_*);val so=Schema(out:_*);val op=Operator.this}
  }
  def show: String
}
trait Scan extends Operator {
  val name: String
  def execOp(yld: Record => Unit) = processCSV(name)(yld) 
  def show = s"Scan($name)"
}
trait Print extends Operator {
  val op: Operator
  def execOp(yld: Record => Unit) = op.execOp { rec => printFields(rec.fields) }
  def show = s"Print(${op.show})"
}
trait Project extends Operator {
  val so, si: Schema
  val op: Operator
  def execOp(yld: Record => Unit) = op.execOp {rec => yld(Record(rec(si), so))}
  def show = s"Project($so,$si,${op.show})"
}
trait Filter extends Operator {
  val pred: Predicate 
  val op: Operator
  def execOp(yld: Record => Unit) = op.execOp { rec => if (pred.eval(rec)) yld(rec)}
  def show = s"Filter(${pred.show},${op.show})"
}
trait Join extends Operator {
  val op1, op2: Operator
  def execOp(yld: Record => Unit) = op1.execOp { rec1 => 
    op2.execOp { rec2 => 
      val keys = rec1.schema intersect rec2.schema
      if (rec1(keys) == rec2(keys))
        yld(Record(rec1.fields++rec2.fields, rec1.schema++rec2.schema)) }}
  def show = s"Join(${op1.show},${op2.show})"
}
trait Predicate {
  def eval(rec: Record): Boolean 
  def show: String
}
trait Eq extends Predicate {
  val ref1, ref2: Ref
  def eval(rec: Record) = ref1.eval(rec) == ref2.eval(rec)
  def show = s"Eq(${ref1.show},${ref2.show})"
}
trait Ne extends Predicate {
  val ref1, ref2: Ref
  def eval(rec: Record) = ref1.eval(rec) != ref2.eval(rec) 
  def show = s"Ne(${ref1.show},${ref2.show})"
}
trait Ref { 
  def eval(r: Record): String 
  def show: String
  def ===(that: Ref)  =  new Eq  {  val ref1=Ref.this; val ref2=that}
  def <>(that: Ref)   =  new Ne  {  val ref1=Ref.this; val ref2=that}
}
trait Field extends Ref {
  val name: String
  var alias: String
  def AS(sym: Symbol) = { alias = sym.name; this }
  def show = s"Field(${name})"
  def eval(rec: Record) = rec(name) 
}
trait Value extends Ref {
  val v: Any
  def show = s"Value($v)"
  def eval(rec: Record) = v.toString 
}

def FROM(file: String) = new Scan   {val name=file}
def FROM(op: Operator) = op
implicit def Field(sym: Symbol)       =  new Field  {val name=sym.name; var alias=name}
implicit def Value(x: String)         =  new Value  {val v=x}
implicit def Value(x: Int)            =  new Value  {val v=x}


val talks = FROM ("talks.csv")
val q1  =  talks WHERE 'time === "09:00 AM" SELECT ('room, 'title)
val q2  =  talks SELECT ('time, 'room, 'title AS 'title1) JOIN 
           (talks SELECT ('time, 'room, 'title AS 'title2)) WHERE 
           'title1 <> 'title2

List(q1,q2).foreach{ q =>
  println(q.show)
  q.exec
}
}
