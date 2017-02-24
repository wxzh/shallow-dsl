package sql

import scala.collection.mutable.{HashMap,ArrayBuffer}
import Utils._
import SQL._

object SQLext extends App {
// interpretation extension 
trait Operator2 extends Operator {
  def resultSchema: Schema
  override def exec = new Print2{val op=Operator2.this} execOp { _ => }
  override def WHERE(p: Predicate) = new Filter2{val pred=p; val op=Operator2.this}
  def JOIN(that: Operator2) = new HashJoin{val op1=Operator2.this; val op2=that}
  override def SELECT(fields: Field*) = {
    val (in,out) = fields.unzip(f => (f.name,f.alias))
    new Project2{val si=Schema(in:_*);val so=Schema(out:_*);val op=Operator2.this}
  }
  def GROUP_BY(xs: Field*) = SumClause(this,Schema(xs.map(_.name):_*))
  case class SumClause(o: Operator2, xs: Schema) {
    object SUM { def apply(ys: Field*) = new Group{val keys=xs; val agg=Schema(ys.map(_.name):_*); val op=o} }}
}
trait Scan2 extends Scan with Operator2 {
  val delim: Char 
  def resultSchema = Schema()
  override def execOp(yld: Record => Unit) = processDSV(name,delim)(yld)
}
trait Print2 extends Print with Operator2 {
  val op: Operator2
  def resultSchema = Schema()
  override def execOp(yld: Record => Unit) {
    val schema = op.resultSchema
    printSchema(schema)
    op.execOp{rec => printFields(rec.fields)}
  }
}
trait Project2 extends Project with Operator2 {
  val op: Operator2
  def resultSchema = so
}
trait Filter2 extends Filter with Operator2 {
  val op: Operator2
  def resultSchema = op.resultSchema
}
// operator extension
trait Group extends Operator2 {
  val keys, agg: Schema
  val op: Operator2
  def resultSchema = keys ++ agg
  def execOp(yld: Record => Unit) {
    val hm = new HashMap[Fields,Seq[Int]]
    op.execOp { rec =>
      val kvs = rec(keys)
      val sums = hm.getOrElseUpdate(kvs,agg.map(_ => 0))
      hm(kvs) = (sums,rec(agg).map(_.toInt)).zipped.map(_ + _)
    }
    hm.foreach { case (k,a) => yld(Record(k ++ a.map(_.toString), keys ++ agg)) }
  }
  def show = "Group(" + keys + "," + agg + op.show + ")"
}
trait HashJoin extends Operator2 {
  val op1, op2: Operator2
  def resultSchema = op1.resultSchema ++ op2.resultSchema 
  def show = "HashJoin(" + op1.show + "," + op2.show + ")"
  def execOp(yld: Record => Unit) {
    val keys = op1.resultSchema intersect op2.resultSchema
    val hm = new HashMap[Fields,ArrayBuffer[Record]]
    op1.execOp { rec1 =>
      val buf = hm.getOrElseUpdate(rec1(keys), new ArrayBuffer[Record])
      buf += rec1 }
    op2.execOp { rec2 =>
      hm.get(rec2(keys)) foreach { _.foreach { rec1 =>
        yld(Record(rec1.fields ++ rec2.fields, rec1.schema ++ rec2.schema)) }}}}
}

def FROM(file: String): Operator2 =  FROM(file,',')
def FROM(file: String, c: Char)   =  new Scan2{val name=file; val delim=c}

val join = FROM ("talks.csv") SELECT ('time, 'room, 'title AS 'title1) JOIN (FROM ("talks.csv") SELECT ('time, 'room, 'title AS 'title2))
val q3 = join WHERE 'title1 <> 'title2
val q4 = FROM ("t1gram.tsv", '\t') WHERE 'Phrase==="Auswanderung"
val q5 = FROM ("t1gram.tsv", '\t') GROUP_BY ('Phrase) SUM ('MatchCount)
val q6 = FROM ("orders.csv") GROUP_BY ('Customer) SUM ('OrderPrice)
val q7 = FROM ("orders.csv") GROUP_BY ('Customer,'OrderDate) SUM ('OrderPrice)
val q8 = FROM ("orders.csv") GROUP_BY ('Customer) SUM ('OrderPrice, 'OrderAmount)

List(join,q3,q4,q5,q6,q7,q8).foreach { q => 
  println(q.show)
  println(q.resultSchema)
  q.exec
}
}