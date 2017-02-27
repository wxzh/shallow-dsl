package sql

import scala.collection.mutable.{HashMap,ArrayBuffer}
import Utils._

trait SemanticsExt extends Semantics {
// interpretation extension 
trait Operator extends super.Operator {
  def resultSchema: Schema
  override def exec = new Print{val op=Operator.this}.execOp { _ => }
}
trait Scan extends super.Scan with super.Operator {
  val delim: Char 
  val schema: Option[Schema]
  def resultSchema = schema.getOrElse(Schema())
  override def execOp(yld: Record => Unit) = processDSV(name,schema,delim)(yld)
}
trait Print extends super.Print with Operator {
  val op: Operator
  def resultSchema = Schema()
  override def execOp(yld: Record => Unit) {
    val schema = op.resultSchema
    printSchema(schema)
    op.execOp{rec => printFields(rec.fields)}
  }
}
trait Project extends super.Project with Operator {
  val op: Operator
  def resultSchema = so
}
trait Filter extends super.Filter with Operator {
  val op: Operator
  def resultSchema = op.resultSchema
}
// operator extension
trait Group extends Operator {
  val keys, agg: Schema
  val op: Operator
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
trait Join extends super.Join with Operator {
  val op1, op2: Operator
  def resultSchema = op1.resultSchema ++ op2.resultSchema 
  override def execOp(yld: Record => Unit) {
    val keys = op1.resultSchema intersect op2.resultSchema
    val hm = new HashMap[Fields,ArrayBuffer[Record]]
    op1.execOp { rec1 =>
      val buf = hm.getOrElseUpdate(rec1(keys), new ArrayBuffer[Record])
      buf += rec1 }
    op2.execOp { rec2 =>
      hm.get(rec2(keys)) foreach { _.foreach { rec1 =>
        yld(Record(rec1.fields ++ rec2.fields, rec1.schema ++ rec2.schema)) }}}}
}
}

object SQLExt extends SemanticsExt with App {
  trait Operator extends super.Operator {
    def WHERE(p: Predicate) = new Filter {val pred=p; val op=Operator.this}
    def JOIN(that: Operator) = new Join{val op1=Operator.this; val op2=that}
    def SELECT(fields: Field*) = {
      val (in,out) = fields.unzip(f => (f.name,f.alias))
      new Project{val si=Schema(in:_*);val so=Schema(out:_*);val op=Operator.this}
    }
    def GROUP_BY(xs: Field*) = SumClause(this,Schema(xs.map(_.name):_*))

    case class SumClause(o: Operator, xs: Schema) {
      object SUM { 
        def apply(ys: Field*) = new Group{val keys=xs; val agg=Schema(ys.map(_.name):_*); val op=o}
      }
    }
  }
  trait Scan extends super.Scan with Operator
  trait Print extends super.Print with Operator
  trait Project extends super.Project with Operator
  trait Join extends super.Join with Operator
  trait Filter extends super.Filter with Operator
  trait Group extends super.Group with Operator


  trait Ref extends super.Ref {
    def ===(that: Ref)  =  new Eq  {  val ref1=Ref.this; val ref2=that}
    def <>(that: Ref)   =  new Ne  {  val ref1=Ref.this; val ref2=that}
  }
  trait Field extends super.Field with Ref {
    var alias: String
    def AS(sym: Symbol) = { alias = sym.name; this }
  }
  trait Value extends super.Value with Ref

  def FROM(file: String): Operator                   =  Scan(file,None,',')
  def FROM(file: String, s: Schema, c: Char)         =  Scan(file,Some(s),c)
  def FROM(file: String, c: Char)                    =  Scan(file,None,c)
  def Scan(file: String, s: Option[Schema], c: Char) = new Scan  {val name=file; val schema=s; val delim=c}

  implicit def Field(sym: Symbol)       =  new Field {val name=sym.name; var alias=name}
  implicit def Value(x: String)         =  new Value {val v=x}
  implicit def Value(x: Int)            =  new Value {val v=x}

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

