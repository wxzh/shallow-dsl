package sql

import scala.collection.mutable.{HashMap,ArrayBuffer}

object SQLext extends App {
  import Utils._
  import SQL._
trait Operator2 extends Operator {
  def resultSchema: Schema
  def JOIN(that: Operator2) = new HashJoin{val op1=Operator2.this; val op2=that}
  override def WHERE(p: Predicate) = new Filter2{val pred=p; val op=Operator2.this}
  def GROUP_BY(xs: Field*) = SumClause(this,xs:_*)
  case class SumClause(o: Operator2, xs: Field*) {
    object SUM {
      def apply(ys: Field*) = 
        new Group{val keys=xs.map{_.name}.toVector; val agg=ys.map(_.name).toVector; val op=o}
    }
  }
}
trait Scan2 extends Scan with Operator2 {
  val delim: Char 
  def resultSchema = Vector()
  override def execOp(yld: Record => Unit) = processDSV(name,delim)(yld)
}
trait Print2 extends Print with Operator2 {
  val op: Operator2
  def resultSchema = Vector()
  override def execOp(yld: Record => Unit) {
    val schema = op.resultSchema
    printSchema(schema)
    op execOp { r => printFields(r.fields) }
  }
}
def printSchema(schema: Schema) = println(schema.mkString(","))

trait Project2 extends Project with Operator2 {
  val op: Operator2
  def resultSchema = out
}
trait Filter2 extends Filter with Operator2 {
  val op: Operator2
  def resultSchema = op.resultSchema
}
trait Join2 extends Join with Operator2 {
  val op1, op2: Operator2
  def resultSchema = op1.resultSchema ++ op2.resultSchema 
}
trait Group extends Operator2 {
  val keys, agg: Schema
  val op: Operator2
  def resultSchema = keys ++ agg
  def execOp(yld: Record => Unit) {
    val hm = new HashMap[Fields,Seq[Int]]
    op execOp { rec =>
      val kvs = rec(keys)
      val sums = hm.getOrElseUpdate(kvs,agg.map(_ => 0))
      hm(kvs) = (sums,rec(agg).map(_.toInt)).zipped map (_ + _)
    }
    hm foreach { case (k,a) => yld(Record(k ++ a.map(_.toString), keys ++ agg)) }
  }
  def show = "Group(" + keys + "," + agg + op.show + ")"
}
trait HashJoin extends Join2 {
  override def show = "HashJoin(" + op1.show + "," + op2.show + ")"
  override def execOp(yld: Record => Unit) {
    val keys = op1.resultSchema intersect op2.resultSchema
    val hm = new HashMap[Fields,ArrayBuffer[Record]]
    op1.execOp { rec1 =>
      val buf = hm.getOrElseUpdate(rec1(keys), new ArrayBuffer[Record])
      buf += rec1
    }
    op2.execOp { rec2 =>
      hm.get(rec2(keys)) foreach { _.foreach { rec1 =>
        yld(Record(rec1.fields ++ rec2.fields, rec1.schema ++ rec2.schema))
      }}
    }
  }
}
case class SELECT(fields: Tuple2[String,String]*) {
  def FROM(o: Operator2) = 
    if (fields.isEmpty) o
    else {
      val (xs, ys) = fields.toVector.unzip
      new Project2{val in=xs;val out=ys;val op=o}
    }
}
implicit def scan(file: String)            =  SCAN(file,',')
def SCAN(file: String, c: Char)   =  new Scan2{val name=file; val delim=c}

val join = (SELECT ('time, 'room, 'title AS 'title1) FROM "talks.csv") JOIN (SELECT ('time, 'room, 'title AS 'title2) FROM "talks.csv")
val q3 = SELECT () FROM (join WHERE 'title1 <> 'title2)
val q4 = SELECT () FROM (SCAN("t1gram.csv", ' ') WHERE 'Phrase==="Auswanderung")
val q5 = SELECT () FROM (SCAN("t1gram.csv", ' ') GROUP_BY ('Phrase) SUM ('MatchCount))

List(q3,q4,q5).foreach { q => 
  println(q.show)
  println(q.exec)
}
}