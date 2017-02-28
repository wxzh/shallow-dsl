package sql

import Utils._
import scala.collection.mutable.{HashMap, ArrayBuffer}

trait SemanticsExt extends Semantics {
  // interpretation extension 
  trait Operator extends super.Operator {
    def resultSchema: Schema
    override def exec = new Print{val op=Operator.this}.execOp { _ => }
  }
  trait Scan extends super.Scan with super.Operator {
    val delim: Char 
    val schema: Option[Schema]
    def resultSchema = schema.getOrElse(loadSchema(name,delim))
    override def execOp(yld: Record => Unit) = processDSV(name,resultSchema,delim,schema.isDefined)(yld)
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
}

trait SyntaxExt extends Syntax {
  type O <: Operator

  trait Operator extends super.Operator { self: O =>
    def GROUP_BY(xs: Field*) = SumClause(this,xs:_*)
      case class SumClause(o: O, xs: Field*) {
        object SUM {
          def apply(ys: Field*) = Group(Schema(xs.map(_.name):_*),Schema(ys.map(_.name):_*),o)
      }
    }
  }

  def FROM(file: String, c: Char)                  = Scan(file,None,c)
  def FROM(file: String, c: Char, fields: Symbol*) = Scan(file,Some(Schema(fields.map(_.name):_*)),c)

  def Scan(file: String) = Scan(file,None,',')
  def Scan(file: String, schema: Option[Schema], delim: Char): O
  def Group(x: Schema, y: Schema, o: O): O
}

object SQLExt extends SyntaxExt with SemanticsExt with App {
  trait Operator extends super[SyntaxExt].Operator with super[SemanticsExt].Operator
  trait Print extends super.Print with Operator
  trait Scan extends super.Scan with Operator
  trait Project extends super.Project with Operator
  trait Join extends super.Join with Operator
  trait Filter extends super.Filter with Operator
  trait Group extends super.Group with Operator

  trait Ref extends super[SyntaxExt].Ref with super[SemanticsExt].Ref
  trait Field extends super[SyntaxExt].Field with super[SemanticsExt].Field with Ref
  trait Value extends super.Value with Ref

  type O = Operator
  type P = Predicate
  type R = Ref

  def Scan(f: String, s: Option[Schema], c: Char) = new Scan    {val name=f; val schema=s; val delim=c}
  def Print(o: O)                                 = new Print   {val op=o}
  def Project(x: Schema, y: Schema, o: O)         = new Project {val si=x; val so=y; val op=o}
  def Join(o1: O, o2: O)                          = new Join    {val op1=o1; val op2=o2}
  def Filter(p: P, o: O)                          = new Filter  {val pred=p; val op=o}
  def Group(x: Schema, y: Schema, o: O)           = new Group   {val keys=x; val agg=y; val op=o}
  def Eq(r1: R, r2: R)                            = new Eq      {val ref1=r1; val ref2=r2}
  def Ne(r1: R, r2: R)                            = new Ne      {val ref1=r1; val ref2=r2}
  implicit def Field(sym: Symbol)                 = new Field   {val name=sym.name}
  def Value(x: Any)                               = new Value   {val v=x}

  val join = FROM ("talks.csv") SELECT ('time, 'room, 'title AS 'title1) JOIN (FROM ("talks.csv") SELECT ('time, 'room, 'title AS 'title2))
  val q3 = join WHERE 'title1 <> 'title2
  val t1gram = FROM ("t1gram.tsv", '\t', 'Phrase, 'Year, 'MatchCount, 'VolumeCount)
  val q4 = t1gram WHERE 'Phrase==="Auswanderung"
  val q5 = t1gram GROUP_BY ('Phrase) SUM ('MatchCount)
  val q6 = FROM ("orders.csv") GROUP_BY ('Customer) SUM ('OrderPrice)
  val q7 = FROM ("orders.csv") GROUP_BY ('Customer,'OrderDate) SUM ('OrderPrice)
  val q8 = FROM ("orders.csv") GROUP_BY ('Customer) SUM ('OrderPrice, 'OrderAmount)
  List(join,q3,q4,q5,q6,q7,q8).foreach(_.exec)
}
