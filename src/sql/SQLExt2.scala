package sql

import Utils._

trait SyntaxExt extends Syntax {
  type O <: Operator

  def FROM(file: String, c: Char)                 = Scan(file,None,c)
  def FROM(file: String, schema: Schema, c: Char) = Scan(file,Some(schema),c)
  trait Operator extends super.Operator { self: O =>
    def GROUP_BY(xs: Field*) = SumClause(this,xs:_*)
      case class SumClause(o: O, xs: Field*) {
        object SUM {
          def apply(ys: Field*) = Group(Schema(xs.map(_.name):_*),Schema(ys.map(_.name):_*),o)
      }
    }
  }
  def Scan(file: String) = Scan(file,None,',')
  def Scan(file: String, schema: Option[Schema], delim: Char): O
  def Group(x: Schema, y: Schema, o: O): O
}

object SQLExt2 extends SyntaxExt with SemanticsExt with App {
  trait Operator extends super[SyntaxExt].Operator with super[SemanticsExt].Operator { self: O => }
  trait Print extends super.Print with Operator { self: O => }
  trait Scan extends super.Scan with Operator { self: O => }
  trait Project extends super.Project with Operator { self: O => }
  trait Join extends super.Join with Operator { self: O => }
  trait Filter extends super.Filter with Operator { self: O => }
  trait Group extends super.Group with Operator { self: O => }

  trait Ref extends super[SyntaxExt].Ref with super[SemanticsExt].Ref
  trait Field extends super[SyntaxExt].Field with super[SemanticsExt].Field with Ref
  trait Value extends super.Value with Ref

  type O = Operator
  type P = Predicate
  type R = Ref

  def Scan(f: String, s: Option[Schema], c: Char) = new Scan {val name=f; val schema=s; val delim=c}
  def Print(o: O)                         = new Print   {val op=o}
  def Project(x: Schema, y: Schema, o: O) = new Project {val si=x; val so=y; val op=o}
  def Join(o1: O, o2: O)                  = new Join    {val op1=o1; val op2=o2}
  def Filter(p: P, o: O)                  = new Filter  {val pred=p; val op=o}
  def Group(x: Schema, y: Schema, o: O)   = new Group   {val keys=x; val agg=y; val op=o}
  def Eq(r1: R, r2: R)                    = new Eq      {val ref1=r1; val ref2=r2}
  def Ne(r1: R, r2: R)                    = new Ne      {val ref1=r1; val ref2=r2}
  implicit def Field(sym: Symbol)         = new Field   {val name=sym.name; var alias=name}
  implicit def Value(x: String)           = new Value   {val v=x}
  implicit def Value(x: Int)              = new Value   {val v=x}


  val join = FROM ("talks.csv") SELECT ('time, 'room, 'title AS 'title1) JOIN (FROM ("talks.csv") SELECT ('time, 'room, 'title AS 'title2))
  val q3 = join WHERE 'title1 <> 'title2
  val q4 = FROM ("t1gram.tsv", '\t') WHERE 'Phrase==="Auswanderung"
  val q5 = FROM ("t1gram.tsv", '\t') GROUP_BY ('Phrase) SUM ('MatchCount)
  val q6 = FROM ("orders.csv") GROUP_BY ('Customer) SUM ('OrderPrice)
  val q7 = FROM ("orders.csv") GROUP_BY ('Customer,'OrderDate) SUM ('OrderPrice)
  val q8 = FROM ("orders.csv") GROUP_BY ('Customer) SUM ('OrderPrice, 'OrderAmount)

  List(join,q3,q4,q5,q6,q7,q8).foreach(_.exec)
}
