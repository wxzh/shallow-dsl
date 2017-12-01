/**
Query Compiler II (Scala)
========================

Outline:
<div id="tableofcontents"></div>

  */
package scala.lms.tutorial

import scala.lms.common._

  trait QueryScalaCompiler extends StagedQueryProcessor with ScannerBase {
    def version = "query_staged"

    /**
    Low-Level Processing Logic
--------------------------
      */
    type Fields = Vector[Rep[String]]

    case class Record(fields: Fields, schema: Schema) {
      def apply(key: String): Rep[String] = fields(schema indexOf key)
      def apply(keys: Schema): Fields = keys.map(this apply _)
    }

    def processCSV(filename: Rep[String], schema: Schema, fieldDelimiter: Char, externalSchema: Boolean)(yld: Record => Rep[Unit]): Rep[Unit] = {
      val s = newScanner(filename)
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

    def fieldsEqual(a: Fields, b: Fields) = (a zip b).foldLeft(unit(true)) { (a,b) => a && b._1 == b._2 }

    def fieldsHash(a: Fields) = a.foldLeft(unit(0L)) { _ * 41L + _.HashCode }

    /**
    Query Interpretation = Compilation
----------------------------------
      */

    trait Predicate extends super.Predicate {
      def eval(rec: Record): Rep[Boolean]
    }

    trait Eq extends Predicate with super.Eq {
      override val ref1, ref2: Reference
      def eval(rec: Record) = ref1.eval(rec) == ref2.eval(rec)
    }

    trait Reference extends super.Reference {
      def eval(rec: Record): Rep[String]
    }

    trait Field extends Reference with super.Field {
      def eval(rec: Record) = rec(name)
    }
    trait Value extends Reference with super.Value {
      def eval(rec: Record) = x.toString
    }

    trait Operator extends super.Operator {
      def execOp(yld: Record => Rep[Unit]): Rep[Unit]
      def exec = execOp { _ => }
    }

    trait Scan extends Operator with super.Scan {
      def execOp(yld: Record => Rep[Unit]): Rep[Unit] = processCSV(filename,schema,fieldDelimiter,externalSchema)(yld)
    }

    trait Print extends Operator with super.Print {
      override val op: Operator
      def execOp(yld: Record => Rep[Unit]) = {
        val schema = op.resultSchema
        printSchema(schema)
        op.execOp { rec => printFields(rec.fields) }
      }
    }

    trait Project extends Operator with super.Project {
      override val op: Operator
      def execOp(yld: Record => Rep[Unit]) = op.execOp {rec => yld(Record(rec(si), so))}
    }

    trait Filter extends Operator with super.Filter {
      override val op: Operator; override val pred: Predicate
      def execOp(yld: Record => Rep[Unit]) = op.execOp { rec => if (pred.eval(rec)) yld(rec)}
    }

    trait Join extends Operator with super.Join {
      override val op1, op2: Operator
      def execOp(yld: Record => Rep[Unit]) = op1.execOp { rec1 =>
        op2.execOp { rec2 =>
          val keys = rec1.schema.intersect(rec2.schema)
          if (fieldsEqual(rec1(keys), rec2(keys)))
            yld(Record(rec1.fields++rec2.fields, rec1.schema++rec2.schema)) }}
    }

    trait Group extends Operator with super.Group {
      override val op: Operator
      def execOp(yld: Record => Rep[Unit]) = {
        val hm = new HashMapAgg(keys, agg)
        op.execOp { rec =>
          hm(rec(keys)) += rec(agg)
        }
        hm.foreach { (k, a) =>
          yld(Record(k ++ a, keys ++ agg))
        }
      }
    }

    trait HashJoin extends Join {
      override def execOp(yld: Record => Rep[Unit]) = {
        val keys = op1.resultSchema intersect op2.resultSchema
        val hm = new HashMapBuffer(keys, op1.resultSchema)
        op1.execOp { rec1 =>
          hm(rec1(keys)) += rec1.fields
        }
        op2.execOp { rec2 =>
          hm(rec2(keys)) foreach { rec1 =>
            yld(Record(rec1.fields ++ rec2.fields, rec1.schema ++ rec2.schema))
          }
        }
      }
    }

    /**
    Data Structure Implementations
------------------------------
      */

    // defaults for hash sizes etc

    object hashDefaults {
      val hashSize   = (1 << 8)
      val keysSize   = hashSize
      val bucketSize = (1 << 8)
      val dataSize   = keysSize * bucketSize
    }

    // common base class to factor out commonalities of group and join hash tables

    class HashMapBase(keySchema: Schema, schema: Schema) {
      import hashDefaults._

      val keys = new ArrayBuffer[String](keysSize, keySchema)
      val keyCount = var_new(0)

      val hashMask = hashSize - 1
      val htable = NewArray[Int](hashSize)
      for (i <- 0 until hashSize) { htable(i) = -1 }

      def lookup(k: Fields) = lookupInternal(k,None)
      def lookupOrUpdate(k: Fields)(init: Rep[Int]=>Rep[Unit]) = lookupInternal(k,Some(init))
      def lookupInternal(k: Fields, init: Option[Rep[Int]=>Rep[Unit]]): Rep[Int] =
        comment[Int]("hash_lookup") {
          val h = fieldsHash(k).toInt
          var pos = h & hashMask
          while (htable(pos) != -1 && !fieldsEqual(keys(htable(pos)),k)) {
            pos = (pos + 1) & hashMask
          }
          if (init.isDefined) {
            if (htable(pos) == -1) {
              val keyPos = keyCount: Rep[Int] // force read
              keys(keyPos) = k
              keyCount += 1
              htable(pos) = keyPos
              init.get(keyPos)
              keyPos
            } else {
              htable(pos)
            }
          } else {
            htable(pos)
          }
        }
    }

    // hash table for groupBy, storing sums

    class HashMapAgg(keySchema: Schema, schema: Schema) extends HashMapBase(keySchema: Schema, schema: Schema) {
      import hashDefaults._

      val values = new ArrayBuffer[Int](keysSize, schema) // assuming all summation fields are numeric

      def apply(k: Fields) = new {
        def +=(v: Fields) = {
          val keyPos = lookupOrUpdate(k) { keyPos =>
            values(keyPos) = schema.map(_ => 0:Rep[Int])
          }
          values(keyPos) = (values(keyPos), v.map(_.toInt)).zipped map (_ + _)
        }
      }

      def foreach(f: (Fields,Fields) => Rep[Unit]): Rep[Unit] = {
        for (i <- 0 until keyCount) {
          f(keys(i),values(i).map(_.ToString))
        }
      }

    }

    // hash table for joins, storing lists of records

    class HashMapBuffer(keySchema: Schema, schema: Schema) extends HashMapBase(keySchema: Schema, schema: Schema) {
      import hashDefaults._

      val data = new ArrayBuffer[String](dataSize, schema)
      val dataCount = var_new(0)

      val buckets = NewArray[Int](dataSize)
      val bucketCounts = NewArray[Int](keysSize)

      def apply(k: Fields) = new {
        def +=(v: Fields) = {
          val dataPos = dataCount: Rep[Int] // force read
          data(dataPos) = v
          dataCount += 1

          val bucket = lookupOrUpdate(k)(bucket => bucketCounts(bucket) = 0)
          val bucketPos = bucketCounts(bucket)
          buckets(bucket * bucketSize + bucketPos) = dataPos
          bucketCounts(bucket) = bucketPos + 1
        }

        def foreach(f: Record => Rep[Unit]): Rep[Unit] = {
          val bucket = lookup(k)

          if (bucket != -1) {
            val bucketLen = bucketCounts(bucket)
            val bucketStart = bucket * bucketSize

            for (i <- bucketStart until (bucketStart + bucketLen)) {
              f(Record(data(buckets(i)),schema))
            }
          }
        }
      }
    }

    class ArrayBuffer[T:Typ](dataSize: Int, schema: Schema) {
      val buf = schema.map(f => NewArray[T](dataSize))
      var len = 0
      def +=(x: Seq[Rep[T]]) = {
        this(len) = x
        len += 1
      }
      def update(i: Rep[Int], x: Seq[Rep[T]]) = {
        (buf,x).zipped.foreach((b,x) => b(i) = x)
      }
      def apply(i: Rep[Int]) = {
        buf.map(b => b(i))
      }
    }
  }
