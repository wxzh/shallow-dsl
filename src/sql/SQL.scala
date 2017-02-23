package sql

import scala.collection.mutable.{HashMap,ArrayBuffer}
import Utils._

object SQL extends App {
trait Operator { 
  def execOp(yld: Record => Unit) 
  def exec = new Print{val op=Operator.this} execOp { _ => }
  def WHERE(p: Predicate) = new Filter{val pred=p; val op=Operator.this}
  def JOIN(that: Operator) = new Join{val op1=Operator.this; val op2=that}
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
  val out, in: Schema
  val op: Operator
  def execOp(yld: Record => Unit) = op.execOp {rec => yld(Record(rec(in), out))}
  def show = s"Project($out,$in,${op.show})"
}
trait Filter extends Operator {
  val pred: Predicate 
  val op: Operator
  def execOp(yld: Record => Unit) = op.execOp {rec => if (pred.eval(rec)) yld(rec)}
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
  def ===(that: Ref)  =  new Eq{val ref1=Ref.this; val ref2=that}
  def <>(that: Ref)   =  new Ne{val ref1=Ref.this; val ref2=that}
}
trait Field extends Ref {
  val name: String
  def AS(s: String) = (name, s)
  def show = s"Field(${name.toString})"
  def eval(rec: Record) = rec(name) 
}
trait Value extends Ref {
  val v: Any
  def show = s"Value($v)"
  def eval(r: Record) = v.toString 
}

case class SELECT(fields: Tuple2[String,String]*) {
  def FROM(o: Operator) = 
    if (fields.isEmpty) o
    else {
      val (xs, ys) = fields.toVector.unzip
      new Project{val in=xs;val out=ys;val op=o}
    }
}
implicit def scan(file: String)            =  new Scan{val name=file}
implicit def fieldAs(sym: Symbol)          =  new Field{val name=sym2str(sym)}
implicit def field(sym: Symbol)            =  (sym2str(sym), sym2str(sym))
implicit def value(x: Any)                 =  new Value{val v=x}
implicit def sym2str(sym: Symbol): String  =  sym.toString.tail



val q0 = SELECT () FROM "talks.csv"
val q1 = SELECT ('room AS 'where, 'title AS 'what) FROM "talks.csv"
val q2 = SELECT ('room, 'title) FROM ("talks.csv" WHERE 'time === "09:00 AM")
val join = (SELECT ('time, 'room, 'title AS 'title1) FROM "talks.csv") JOIN (SELECT ('time, 'room, 'title AS 'title2) FROM "talks.csv")
val q3 = SELECT () FROM (join WHERE 'title1 <> 'title2)

List(q0,q1,q2,q3).foreach { q => 
  println(q.show)
  println(q.exec)
}
}
