package sql

import Utils._
import scala.collection.mutable.{HashMap,ArrayBuffer}

trait SQLext2 extends SQL2 {
  type O <: Operator
  def Group(x: Schema, y: Schema, o: O): O
  trait Operator extends super.Operator { self: O =>
    def resultSchema: Schema
    override def JOIN(that: O) = Join(this, that)
    def GROUP_BY(xs: Field*) = SumClause(this,xs:_*)
      case class SumClause(o: O, xs: Field*) {
        object SUM {
          def apply(ys: Field*) = Group(Schema(xs.map(_.name):_*),Schema(ys.map(_.name):_*),o)
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
}

object SQLext2Syntax extends App with SQLext2 {
type O = Operator
type P = Predicate
type R = Ref


def FROM(file: String)                  = FROM(file,',')
def FROM(file: String, c: Char)         = new Scan {val name=file; val delim=c}
def Print(o: O)                         = new Print   {val op=o}
def Project(x: Schema, y: Schema, o: O) = new Project {val si=x; val so=y; val op=o}
def Join(o1: O, o2: O)                  = new Join {val op1=o1; val op2=o2}
def Filter(p: P, o: O)                  = new Filter {val pred=p; val op=o}
def Group(x: Schema, y: Schema, o: O)   = new Group {val keys=x; val agg=y; val op=o}
def Eq(r1: R, r2: R)                    = new Eq {val ref1=r1; val ref2=r2}
def Ne(r1: R, r2: R)                    = new Ne {val ref1=r1; val ref2=r2}
implicit def Field(sym: Symbol)         = new Field  {val name=sym.name; var alias=name}
implicit def Value(x: String)           = new Value  {val v=x}
implicit def Value(x: Int)              = new Value  {val v=x}


val join = FROM ("talks.csv") SELECT ('time, 'room, 'title AS 'title1) JOIN (FROM ("talks.csv") SELECT ('time, 'room, 'title AS 'title2))
val q3 = join WHERE 'title1 <> 'title2
val q4 = FROM ("t1gram.tsv", '\t') WHERE 'Phrase==="Auswanderung"
val q5 = FROM ("t1gram.tsv", '\t') GROUP_BY ('Phrase) SUM ('MatchCount)
val q6 = FROM ("orders.csv") GROUP_BY ('Customer) SUM ('OrderPrice)
val q7 = FROM ("orders.csv") GROUP_BY ('Customer,'OrderDate) SUM ('OrderPrice)
val q8 = FROM ("orders.csv") GROUP_BY ('Customer) SUM ('OrderPrice, 'OrderAmount)

List(join,q3,q4,q5,q6,q7,q8).foreach(_.exec)
}
