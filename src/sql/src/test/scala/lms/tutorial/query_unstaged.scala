/**
Query Interpreter
=================
*/
package scala.lms.tutorial

import scala.collection.mutable.{ArrayBuffer,HashMap}

trait QueryInterpreter extends PlainQueryProcessor {
  type P <: Predicate
  type R <: Reference
  type O <: Operator
  def version = "query_unstaged"

/**
Low-Level Processing Logic
--------------------------
*/
  type Fields = Vector[String]

  case class Record(fields: Fields, schema: Schema) {
    def apply(key: String): String = fields(schema indexOf key)
    def apply(keys: Schema): Fields = keys.map(this apply _)
  }

  def processCSV(filename: String, schema: Schema, fieldDelimiter: Char, externalSchema: Boolean)(yld: Record => Unit): Unit = {
    val s = new Scanner(filename)
    val last = schema.last
    def nextRecord = Record(schema.map{x => s.next(if (x==last) '\n' else fieldDelimiter)}, schema)
    if (!externalSchema) {
      // the right thing would be to dynamically re-check the schema,
      // but it clutters the generated code
      // schema.foreach(f => if (s.next != f) println("ERROR: schema mismatch"))
      nextRecord // ignore csv header
    }
    while (s.hasNext) yld(nextRecord)
    s.close
  }

  def printSchema(schema: Schema) = println(schema.mkString(defaultFieldDelimiter.toString))

  def printFields(fields: Fields) = printf(fields.map{_ => "%s"}.mkString("", defaultFieldDelimiter.toString, "\n"), fields: _*)

/**
Query Interpretation
--------------------
*/

  trait Predicate extends super.Predicate {
    def eval(rec: Record): Boolean
  }

  trait Eq extends Predicate with super.Eq {
    def eval(rec: Record) = ref1.eval(rec) == ref2.eval(rec)
  }

  trait Reference extends super.Reference {
    def eval(rec: Record): String
  }
  trait Field extends Reference with super.Field {
    def eval(rec: Record) = rec(name)
  }
  trait Value extends Reference with super.Value {
    def eval(rec: Record) = x.toString
  }

  trait Operator extends super.Operator {
    def execOp(yld: Record => Unit): Unit
    def exec = execOp { _ => }
  }

  trait Scan extends Operator with super.Scan {
    def execOp(yld: Record => Unit) = processCSV(filename,schema,fieldDelimiter,externalSchema)(yld)
  }

  trait Print extends Operator with super.Print {
    def execOp(yld: Record => Unit) = {
      val schema = op.resultSchema
      printSchema(schema)
      op.execOp { rec => printFields(rec.fields) }
    }
  }

  trait Project extends Operator with super.Project {
    def execOp(yld: Record => Unit) = op.execOp {rec => yld(Record(rec(si), so))}
  }

  trait Filter extends Operator with super.Filter{
    def execOp(yld: Record => Unit) = op.execOp { rec => if (pred.eval(rec)) yld(rec)}
  }

  trait Join extends Operator with super.Join {
    def execOp(yld: Record => Unit) = op1.execOp { rec1 =>
      op2.execOp { rec2 =>
        val keys = rec1.schema.intersect(rec2.schema)
        if (rec1(keys) == rec2(keys))
          yld(Record(rec1.fields++rec2.fields, rec1.schema++rec2.schema)) }}
  }

  trait Group extends Operator with super.Group {
    def execOp(yld: Record => Unit) = {
      val hm = new HashMap[Fields,Seq[Int]]
      op.execOp { rec =>
        val kvs = rec(keys)
        val sums = hm.getOrElseUpdate(kvs,agg.map(_ => 0))
        hm(kvs) = (sums,rec(agg).map(_.toInt)).zipped map (_ + _)
      }
      hm foreach { case (k,a) =>
        yld(Record(k ++ a.map(_.toString), keys ++ agg))
      }
    }
  }
  trait HashJoin extends Join {
    override def execOp(yld: Record => Unit) = {
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
}
