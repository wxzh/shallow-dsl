package sql

import Utils._


trait Semantics {
  trait Operator { 
    def execOp(yld: Record => Unit) 
    def exec = new Print{val op=Operator.this}.execOp { _ => }
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
        val keys = rec1.schema.intersect(rec2.schema)
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
  }
  trait Field extends Ref {
    val name: String
    def show = s"Field(${name})"
    def eval(rec: Record) = rec(name) 
  }
  trait Value extends Ref {
    val v: Any
    def show = s"Value($v)"
    def eval(rec: Record) = v.toString 
  }
}

trait Syntax {
  type O <: Operator
  type R <: Ref
  type P

  def FROM(file: String) = Scan(file)
  trait Operator { self: O =>
    def WHERE(p: P): O = Filter(p,this)
    def JOIN(that: O): O = Join(this,that)
    def SELECT(fields: Tuple2[String,String]*) = {
      val (in,out) = fields.unzip
      Project(Schema(in:_*), Schema(out:_*), this)
    }
  }
  trait Ref { self: R =>
    def ===(that: R): P  =  Eq(this,that)
    def <>(that: R): P   =  Ne(this,that)
  }
  trait Field extends Ref { self: R =>
    val name: String
    def AS(sym: Symbol) = (name, sym.name)
  }

  implicit def sym2pair(sym: Symbol)  = (sym.name, sym.name)
  implicit def str2Value(x: String)   = Value(x)
  implicit def int2Value(x: Int)      = Value(x)

  def Scan(file: String): O
  def Print(op: O): O
  def Project(out: Schema, in: Schema, o: O): O
  def Join(o1: O, o2: O): O
  def Filter(p: P, o: O): O
  def Eq(r1: R, r2: R): P
  def Ne(r1: R, r2: R): P
  def Value(x: Any): R
}

object SQL extends Syntax with Semantics with App {
  trait Operator extends super[Syntax].Operator with super[Semantics].Operator 
  trait Print extends super.Print with Operator
  trait Scan extends super.Scan with Operator
  trait Project extends super.Project with Operator
  trait Join extends super.Join with Operator
  trait Filter extends super.Filter with Operator

  trait Ref extends super[Syntax].Ref with super[Semantics].Ref
  trait Field extends super[Syntax].Field with super[Semantics].Field with Ref
  trait Value extends super.Value with Ref

  type O = Operator
  type P = Predicate
  type R = Ref

  def Scan(file: String)                  = new Scan   {val name=file}
  def Print(o: O)                         = new Print  {val op=o}
  def Project(x: Schema, y: Schema, o: O) = new Project{val si=x; val so=y; val op=o}
  def Join(o1: O, o2: O)                  = new Join   {val op1=o1; val op2=o2}
  def Filter(p: P, o: O)                  = new Filter {val pred=p; val op=o}
  def Eq(r1: R, r2: R)                    = new Eq     {val ref1=r1; val ref2=r2}
  def Ne(r1: R, r2: R)                    = new Ne     {val ref1=r1; val ref2=r2}
  def Value(x: Any)                       = new Value  {val v=x}
  implicit def Field(x: Symbol)           = new Field  {val name=x.name}

  val q0  =  FROM ("talks.csv")
  val q1  =  q0 WHERE 'time === "09:00 AM" SELECT ('room, 'title) 
  val q2  =  q0 SELECT ('time, 'room, 'title AS 'title1) JOIN 
             (q0 SELECT ('time, 'room, 'title AS 'title2)) WHERE 
             'title1 <> 'title2

  List(q1,q2).foreach{ q =>
    println(q.show)
    q.exec
  }
}