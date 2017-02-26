package sql

import Utils._

trait Syntax {
  type O <: Operator
  type R <: Ref
  type P

  trait Operator { self: O =>
    def WHERE(p: P): O = Filter(p,this)
    def JOIN(that: O): O = Join(this,that)
    def SELECT(fields: Field*) = {
      val (in,out) = fields.unzip(f => (f.name,f.alias))
      Project(Schema(in:_*), Schema(out:_*), this)
    }
  }
  trait Ref { self: R =>
    def ===(that: R): P  =  Eq(this,that)
    def <>(that: R): P   =  Ne(this,that)
  }
  trait Field { self: R =>
    val name: String
    var alias: String
    def AS(sym: Symbol) = { alias = sym.name; this }
  }
  def FROM(file: String): O
  def Print(op: O): O
  def Project(out: Schema, in: Schema, o: O): O
  def Join(o1: O, o2: O): O
  def Filter(p: P, o: O): O
  def Eq(r1: R, r2: R): P
  def Ne(r1: R, r2: R): P
}

// merging syntax and semantics
object SQL2 extends Syntax with Semantics with App {
  trait Operator extends super[Syntax].Operator with super[Semantics].Operator { self: O => }
  trait Print extends super.Print with Operator { self: O => }
  trait Scan extends super.Scan with Operator { self: O => }
  trait Project extends super.Project with Operator { self: O => }
  trait Join extends super.Join with Operator { self: O => }
  trait Filter extends super.Filter with Operator { self: O => }

  trait Ref extends super[Syntax].Ref with super[Semantics].Ref
  trait Field extends super[Syntax].Field with super[Semantics].Field with Ref
  trait Value extends super.Value with Ref

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