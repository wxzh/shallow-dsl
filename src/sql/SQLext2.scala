package sql

import Utils._
import scala.collection.mutable.{HashMap,ArrayBuffer}

trait SQLext2 extends SQL2 {
  type O <: Operator
  def Group(x: Schema, y: Schema, o: O): O
  trait Operator extends super.Operator { self: O =>
    def resultSchema: Schema
    override def JOIN(that: O) = Join(this, that)
    def GROUP_BY(xs: Symbol*) = SumClause(this,xs:_*)
      case class SumClause(o: O, xs: Symbol*) {
        object SUM {
          def apply(ys: Symbol*) = Group(Symbol2Schema(xs:_*), Symbol2Schema(ys:_*),o)
      }
    }
  }
  trait Scan extends super.Scan with Operator { self: O =>
    val delim: Char 
    def resultSchema = Vector()
    override def execOp(yld: Record => Unit) = processDSV(name,delim)(yld)
  }
  trait Print extends super.Print with Operator { self: O =>
    def resultSchema = Vector()
    override def execOp(yld: Record => Unit) {
      val schema = op.resultSchema
      printSchema(schema)
      op.execOp { r => printFields(r.fields) }
    }
  }
  trait Project extends super.Project with Operator { self: O =>
    def resultSchema = so
  }
  trait Filter extends super.Filter with Operator { self: O =>
    def resultSchema = op.resultSchema
  }
  trait Group extends Operator { self: O =>
    val keys, agg: Schema; val op: O
    def resultSchema = keys ++ agg
    def execOp(yld: Record => Unit) {
      val hm = new HashMap[Fields,Seq[Int]]
      op execOp { rec =>
        val kvs = rec(keys)
        val sums = hm.getOrElseUpdate(kvs,agg.map(_ => 0))
        hm(kvs) = (sums,rec(agg).map(_.toInt)).zipped map (_ + _) }
      hm foreach { case (k,a) =>
        yld(Record(k ++ a.map(_.toString), keys ++ agg)) }}
  }
  trait Join extends super.Join with Operator { self: O =>
    def resultSchema = op1.resultSchema ++ op2.resultSchema 
    override def execOp(yld: Record => Unit) {
      val keys = op1.resultSchema intersect op2.resultSchema
      val hm = new HashMap[Fields,ArrayBuffer[Record]]
      op1.execOp { rec1 =>
        val buf = hm.getOrElseUpdate(rec1(keys), new ArrayBuffer[Record])
        buf += rec1}
      op2.execOp { rec2 =>
        hm.get(rec2(keys)) foreach { _.foreach { rec1 =>
          yld(Record(rec1.fields ++ rec2.fields, rec1.schema ++ rec2.schema)) }}}
  }
}
  def SCAN(name: String, delim: Char): O
}

object SQLext2Syntax extends App with SQLext2 {
type O = Operator
type P = Predicate
type R = Ref

def SCAN(file: String, c: Char)         = new Scan {val name=file; val delim=c}
implicit def Scan(file: String)         = SCAN(file, ',')
def Print(o: O)                         = new Print   {val op=o}
def Project(x: Schema, y: Schema, o: O) = new Project {val si=x; val so=y; val op=o}
def Join(o1: O, o2: O)                  = new Join {val op1=o1; val op2=o2}
def Filter(p: P, o: O)                  = new Filter {val pred=p; val op=o}
def Group(x: Schema, y: Schema, o: O)   = new Group {val keys=x; val agg=y; val op=o}
def Eq(r1: R, r2: R)                    = new Eq {val ref1=r1; val ref2=r2}
def Ne(r1: R, r2: R)                    = new Ne {val ref1=r1; val ref2=r2}
implicit def Field(sym: Symbol)         = new Field  {val x=sym}
implicit def Value(x: String)           = new Value  {val v=x}
implicit def Value(x: Int)              = new Value  {val v=x}

val join = (SELECT ('time, 'room, 'title AS 'title1) FROM "talks.csv") JOIN (SELECT ('time, 'room, 'title AS 'title2) FROM "talks.csv")
val q3 = SELECT () FROM (join WHERE 'title1 <> 'title2)
val q4 = SELECT () FROM (SCAN("t1gram.tsv", '\t') WHERE 'Phrase==="Auswanderung")
val q5 = SELECT () FROM (SCAN("t1gram.tsv", '\t') GROUP_BY ('Phrase) SUM ('MatchCount))
val q6 = SELECT () FROM ("orders.csv" GROUP_BY ('Customer) SUM ('OrderPrice)) 
val q7 = SELECT () FROM ("orders.csv" GROUP_BY ('Customer,'OrderDate) SUM ('OrderPrice)) 
val q8 = SELECT () FROM ("orders.csv" GROUP_BY ('Customer) SUM ('OrderPrice, 'OrderAmount)) 

List(join,q3,q4,q5,q6,q7,q8).foreach(_.exec)
}
