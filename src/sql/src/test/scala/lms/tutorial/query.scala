package scala.lms.tutorial

import scala.lms.common._

trait Syntax {
  type O
  type R
  type P
  type Table
  type Schema
  def Schema(schema: String*): Schema

  implicit class PimpOperator(o1: O) {
    def WHERE(p: P): O = Filter(p,o1)
    def JOIN(o2: O): O = HashJoin(o1,o2)
    def SELECT(fields: (String,String)*) = {
      val (in,out) = fields.unzip
      Project(Schema(out:_*), Schema(in:_*), o1)
    }
    def GROUP_BY(keys: String*) = SumClause(o1,Schema(keys:_*))
    case class SumClause(o: O, keys: Schema) {
      object SUM {
        def apply(agg: String*) = Group(keys,Schema(agg: _*),o)
      }
    }
  }
  implicit class PimpReference(r1: R) {
    def ===(r2: R): P = Eq(r1,r2)
  }

  implicit class PimpField(s1: Symbol) extends PimpReference(Field(s1.name)) {
    def AS(s2: Symbol) = (s1.name, s2.name)
  }

  implicit def syms2string(s: Symbol) = s.name
  implicit def sym2pair(sym: Symbol)  = (sym.name, sym.name)
  implicit def str2Value(x: String)   = Value(x)
  implicit def int2Value(x: Int)      = Value(x)

  // factory methods
  def FROM(file: String) = Scan(file)
  def FROM(file: String, c: Char, fields: Symbol*) = Scan(file,Some(Schema(fields.map(_.name):_*)),Some(c))

  def Scan(name: Table, schema: Schema, delim: Char, extSchema: Boolean): O
  def PrintCSV(parent: O): O
  def Project(outSchema: Schema, inSchema: Schema, parent: O): O
  def Filter(pred: P, parent: O): O
  def Join(parent1: O, parent2: O): O
  def Group(keys: Schema, agg: Schema, parent: O): O
  def HashJoin(parent1: O, parent2: O): O

  // filter predicates
  def Eq(a: R, b: R): P
  def Value(x: Any): R
  def Field(x: String): R

  // some smart constructors
  def Scan(tableName: String): O = Scan(tableName, None, None)
  def Scan(tableName: String, schema: Option[Schema], delim: Option[Char]): O
}

trait FullQueryInterpreter extends QueryInterpreter {
  type O = Operator
  type P = Predicate
  type R = Reference

  def Scan(name: Table, s: Schema, delim: Char, extSchema: Boolean) = new Scan {
    val schema = s
    val fieldDelimiter = delim
    val filename = name
    val externalSchema = extSchema
  }

  def PrintCSV(parent: O) = new Print { val op = parent }
  def Project(outSchema: Schema, inSchema: Schema, parent: O) = new Project {
    val op = parent
    val si = inSchema
    val so = outSchema
  }
  def Filter(p: P, parent: O) = new Filter { val op = parent; val pred = p }
  def Join(parent1: O, parent2: O) = new Join { val op1 = parent1; val op2 = parent2 }
  def Group(s1: Schema, s2: Schema, parent: O) = new Group { val keys = s1; val agg = s2; val op = parent }
  def HashJoin(parent1: O, parent2: O) = new HashJoin { val op1 = parent1; val op2 = parent2 }
  def Eq(a: R, b: R) = new Eq { val ref1 = a; val ref2 = b }
  def Field(s: String) = new Field { val name = s }
  def Value(v: Any) = new Value { val x = v }
  def Field(x: Symbol) = new Field  {val name=x.name}
}

trait FullQueryScalaCompiler extends QueryScalaCompiler {
  type O = Operator
  type P = Predicate
  type R = Reference

  def Scan(name: Table, s: Schema, delim: Char, extSchema: Boolean) = new Scan {
    val schema = s
    val fieldDelimiter = delim
    val filename = name
    val externalSchema = extSchema
  }

  def PrintCSV(parent: O) = new Print { val op = parent }
  def Project(outSchema: Schema, inSchema: Schema, parent: O) = new Project {
    val op = parent
    val si = inSchema
    val so = outSchema
  }
  def Filter(p: P, parent: O) = new Filter { val op = parent; val pred = p }
  def Join(parent1: O, parent2: O) = new Join { val op1 = parent1; val op2 = parent2 }
  def Group(s1: Schema, s2: Schema, parent: O) = new Group { val keys = s1; val agg = s2; val op = parent }
  def HashJoin(parent1: O, parent2: O) = new HashJoin { val op1 = parent1; val op2 = parent2 }
  def Eq(a: R, b: R) = new Eq { val ref1 = a; val ref2 = b }
  def Field(s: String) = new Field { val name = s }
  def Value(v: Any) = new Value { val x = v }
  def Field(x: Symbol) = new Field  {val name=x.name}
}

trait FullQueryCCompiler extends QueryCCompiler {
  type O = Operator
  type P = Predicate
  type R = Reference

  def Scan(name: Table, s: Schema, delim: Char, extSchema: Boolean) = new Scan {
    val schema = s
    val fieldDelimiter = delim
    val filename = name
    val externalSchema = extSchema
  }

  def PrintCSV(parent: O) = new Print { val op = parent }
  def Project(outSchema: Schema, inSchema: Schema, parent: O) = new Project {
    val op = parent
    val si = inSchema
    val so = outSchema
  }
  def Filter(p: P, parent: O) = new Filter { val op = parent; val pred = p }
  def Join(parent1: O, parent2: O) = new Join { val op1 = parent1; val op2 = parent2 }
  def Group(s1: Schema, s2: Schema, parent: O) = new Group { val keys = s1; val agg = s2; val op = parent }
  def HashJoin(parent1: O, parent2: O) = new HashJoin { val op1 = parent1; val op2 = parent2 }
  def Eq(a: R, b: R) = new Eq { val ref1 = a; val ref2 = b }
  def Field(s: String) = new Field { val name = s }
  def Value(v: Any) = new Value { val x = v }
  def Field(x: Symbol) = new Field  {val name=x.name}
}
/**
Interactive Mode
----------------

Examples:

    test:run unstaged "select * from ? schema Phrase, Year, MatchCount, VolumeCount delim \\t where Phrase='Auswanderung'" src/data/t1gram.csv
    test:run c        "select * from ? schema Phrase, Year, MatchCount, VolumeCount delim \\t where Phrase='Auswanderung'" src/data/t1gram.csv
*/


/**

Unit Tests
----------

*/

trait QueryProcessor {
  type Table
  type Schema = Vector[String]
  type P <: Predicate
  type R <: Reference
  type O <: Operator

  val defaultFieldDelimiter = ','

  def Schema(schema: String*): Schema = schema.toVector

  trait Predicate {
    def show: String
  }
  trait Eq extends Predicate {
    val ref1, ref2: R
    def show = s"Eq(${ref1.show},${ref2.show})"
  }

  trait Reference {
    def show: String
  }
  trait Field extends Reference {
    val name: String
    def show = s"Field($name)"
  }
  trait Value extends Reference {
    val x: Any
    def show = s"Value($x)"
  }

  trait Operator {
    def resultSchema: Schema
    def show: String
    def exec: Unit
  }
  trait Scan extends Operator {
    val filename: Table
    val schema: Schema
    val fieldDelimiter: Char
    val externalSchema: Boolean
    def resultSchema = schema
    def show = s"Scan($filename,$schema,$externalSchema)"
  }
  trait Print extends Operator {
    val op: O
    def resultSchema = Schema()
    def show = s"Print(${op.show})"
  }
  trait Project extends Operator {
    val so, si: Schema; val op: O
    def resultSchema = so
    def show = s"Project($so,$si,${op.show})"
  }
  trait Filter extends Operator {
    val pred: P; val op: O
    def resultSchema = op.resultSchema
    def show = s"Filter(${pred.show},${op.show})"
  }
  trait Join extends Operator {
    val op1, op2: O
    def resultSchema = op1.resultSchema ++ op2.resultSchema
    def show = s"Join(${op1.show},${op2.show})"
  }

  trait Group extends Operator {
    val keys, agg: Schema
    val op: O
    def resultSchema = keys ++ agg
    def show = s"Group($keys,$agg,${op.show})"
  }
  def filePath(table: String) = if (table == "?") throw new Exception("file path for table ? not available") else table

  def dynamicFilePath(table: String): Table

  def Scan(tableName: String, schema: Option[Schema], delim: Option[Char]): O = {
    val dfile = dynamicFilePath(tableName)
    val (schema1, externalSchema) = schema.map(s=>(s,true)).getOrElse((loadSchema(filePath(tableName)),false))
    Scan(dfile, schema1, delim.getOrElse(defaultFieldDelimiter), externalSchema)
  }
  def Scan(name: Table, schema: Schema, delim: Char, extSchema: Boolean): O

  def loadSchema(filename: String): Schema = {
    val s = new Scanner(filename)
    val schema = Schema(s.next('\n').split(defaultFieldDelimiter): _*)
    s.close
    schema
  }
}

trait PlainQueryProcessor extends QueryProcessor {
  type Table = String
}

trait StagedQueryProcessor extends QueryProcessor with Dsl {
  type Table = Rep[String] // dynamic filename
  override def filePath(table: String) = if (table == "?") throw new Exception("file path for table ? not available") else super.filePath(table)
}


class QueryTest extends TutorialFunSuite {
  val under = "query_"

  trait TestDriver extends QueryProcessor with Syntax {
    type O <: Operator
    type R <: Reference
    type P <: Predicate
    def name: String
    def query: O
    def expected: O
    override def filePath(table: String) = dataFilePath(table)

    def t1 = FROM("t.csv")
    def t2 = t1 SELECT 'Name
    def t3 = t1 WHERE 'Flag === "yes" SELECT 'Name
    def t4h = t1 JOIN (t1 SELECT ('Name AS 'Name1))
    def t5h = t1 JOIN t2
    def t6 = t1 GROUP_BY 'Name SUM 'Value

    def t1gram1 = FROM("?", '\t', 'Phrase, 'Year, 'MatchCount, 'VolumeCount)
    def t1gram2 = FROM("?", '\t', 'Phrase, 'Year, 'MatchCount, 'VolumeCount) WHERE 'Phrase === "Auswanderung"
  }

  trait PlainTestDriver extends TestDriver with PlainQueryProcessor {
    override def dynamicFilePath(table: String): Table = if (table == "?") defaultEvalTable else filePath(table)
    def eval(fn: Table): Unit =
      PrintCSV(query).exec
  }

  trait StagedTestDriver extends TestDriver with StagedQueryProcessor {
    var dynamicFileName: Table = _
    override def dynamicFilePath(table: String): Table = if (table == "?") dynamicFileName else unit(filePath(table))
    def snippet(fn: Table): Rep[Unit] = {
      dynamicFileName = fn
      PrintCSV(query).exec
    }
  }

  trait ScalaPlainQueryDriver extends PlainTestDriver with FullQueryInterpreter { q =>
    def runtest: Unit = {
      test(version + " " + name + ": " + query.show) {
        assert(query.show == expected.show)
        checkOut(name, "csv", eval(defaultEvalTable))
      }
    }
  }

  trait ScalaStagedQueryDriver extends DslDriver[String,Unit] with StagedTestDriver with ScannerExp with FullQueryScalaCompiler { q =>
    override val codegen = new DslGen with ScalaGenScanner {
      val IR: q.type = q
    }
    def runtest = {
      test(version + " " + name + ": " + query.show) {
        assert(query.show == expected.show)
        check(name, code)
        precompile
        checkOut(name, "csv", eval(defaultEvalTable))
      }
    }
  }

  trait CStagedQueryDriver extends DslDriverC[String,Unit] with ScannerLowerExp with StagedTestDriver with FullQueryCCompiler { q =>
    override val codegen = new DslGenC with CGenScannerLower {
      val IR: q.type = q
    }
    def runtest = {
      test(version + " " + name + ": " + query.show) {
        assert(query.show == expected.show)
        check(name, code, "c")
        //precompile
        checkOut(name, "csv", eval(defaultEvalTable))
      }
    }
    // FIXME: hack so i don't need to replace Value -> #Value in all the files right now
    override def isNumericCol(s: String) = s == "Value" || super.isNumericCol(s)
  }

  trait T1 extends TestDriver {
    def name = "t1"
    def query = t1
    def expected = Scan("t.csv")
  }

  trait T2 extends TestDriver {
    def name = "t2"
    def query = t2
    def expected = Project(Schema("Name"), Schema("Name"), Scan("t.csv"))
  }

  trait T3 extends TestDriver {
    def name = "t3"
    def query = t3
    def expected = Project(Schema("Name"), Schema("Name"), Filter(Eq(Field("Flag"), Value("yes")), Scan("t.csv")))
  }

  trait T4 extends TestDriver {
    def name = "t4h"
    def query = t4h
    def expected = HashJoin(Scan("t.csv"), Project(Schema("Name1"), Schema("Name"), Scan("t.csv")))
  }

  trait T5 extends TestDriver {
    def name = "t5h"
    def query = t5h
    def expected = HashJoin(Scan("t.csv"), Project(Schema("Name"), Schema("Name"), Scan("t.csv")))
  }

  trait T6 extends TestDriver {
    def name = "t6"
    def query = t6
    def expected = Group(Schema("Name"), Schema("Value"), Scan("t.csv"))
  }

  trait T7 extends TestDriver {
    def name = "t1gram1"
    def query = t1gram1
    def expected = Scan("?",Some(Schema("Phrase", "Year", "MatchCount", "VolumeCount")),Some('\t'))
  }

  trait T8 extends TestDriver {
    def name = "t1gram2"
    def query = t1gram2
    def expected = Filter(Eq(Field("Phrase"), Value("Auswanderung")),Scan("?",Some(Schema("Phrase", "Year", "MatchCount", "VolumeCount")),Some('\t')))
  }

  new ScalaPlainQueryDriver with T1 {}.runtest
  new ScalaPlainQueryDriver with T2 {}.runtest
  new ScalaPlainQueryDriver with T3 {}.runtest
  new ScalaPlainQueryDriver with T4 {}.runtest
  new ScalaPlainQueryDriver with T5 {}.runtest
  new ScalaPlainQueryDriver with T6 {}.runtest
  new ScalaPlainQueryDriver with T7 {}.runtest
  new ScalaPlainQueryDriver with T8 {}.runtest

  new ScalaStagedQueryDriver with T1 {}.runtest
  new ScalaStagedQueryDriver with T2 {}.runtest
  new ScalaStagedQueryDriver with T3 {}.runtest
  new ScalaStagedQueryDriver with T4 {}.runtest
  new ScalaStagedQueryDriver with T5 {}.runtest
  new ScalaStagedQueryDriver with T6 {}.runtest
  new ScalaStagedQueryDriver with T7 {}.runtest
  new ScalaStagedQueryDriver with T8 {}.runtest

  new CStagedQueryDriver with T1 {}.runtest
  new CStagedQueryDriver with T2 {}.runtest
  new CStagedQueryDriver with T3 {}.runtest
  new CStagedQueryDriver with T4 {}.runtest
  new CStagedQueryDriver with T5 {}.runtest
  new CStagedQueryDriver with T6 {}.runtest
  new CStagedQueryDriver with T7 {}.runtest
  new CStagedQueryDriver with T8 {}.runtest

  val defaultEvalTable = dataFilePath("t1gram.csv")
}



/**
Suggestions for Exercises
-------------------------

The query engine we presented is decidedly simple, so as to present an
end-to-end system that can be understood in total. Below are a few
suggestions for interesting extensions.

- Implement a scanner that reads on demand from a URL.

  (Cool with: a new operator that only prints the first N results.)

- (easy) Implement a typed schema in the Scala version, so that the
  types of columns are statically known, while the values are not.

  (Hint: the C version already does this, but is also more involved
  because of the custom type representations.)

- (easy) Implement more predicates (e.g. `LessThan`) and predicate
  combinators (e.g. `And`, `Or`) in order to run more interesting
  queries.

- (medium) Implement a real column-oriented database, where each column has its
  own file so that it can be read independently.

- (hard) Implement an optimizer on the relational algebra before generating code.
  (Hint: smart constructors might help.)

  The query optimizer should rearrange query operator trees for a better join ordering, i.e. decide whether to execute joins on relations S0 x S1 x S2 as  (S0 x (S1 x S2)) vs ((S0 x S1) x S2).

  Use a dynamic programming algorithm, that for n joins on tables S0 x S1 x ...x Sn tries to find an optimal solution for S1 x .. x Sn first, and then the optimal combination with S0. 

  To find an optimal combination, try all alternatives and estimate the cost of each. Cost can be measured roughly as number of records processed. As a simple approximation, you can use the size of each input table and assume that all filter predicates match uniformly with probability 0.5.


*/
