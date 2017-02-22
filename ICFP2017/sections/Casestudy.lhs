%include lhs2TeX.fmt
%include polycode.fmt
%include def.fmt

%format q1
%format q2
%format rec1
%format rec2
%format ref1
%format ref2
%format title1
%format title2
%format (="\!("
%format [="\!["
%format - = "\!-"

\section{Case Study}
To further illustrate the applicability of shallow OO embeddings,
we refactored an existing \emph{external} DSL implementation to make it modular
and embedded.

\bruno{I think that in this section we need to tone done significantly on the code 
that we show. I suggest that we do not show code for their approach. Instead 
show code only for our approach. Even for the code of our approach we should tone 
down on the code and make the existing code pretty. 
Don't think of this section so much as a detailed comparison with their work. 
Instead focus on writing this section as a more practical illustration of our 
technqiues. 
}

\subsection{Overview}
SQL is one of the most well-known DSLs for data queries.
Consider a data file |talks.csv| that contains a list of talks:

> tid,  time,      title,                                         room
> 1,    09:00 AM,  Erlang 101 - Actor and MultiCore-Programming,  New York Central
> 2,    09:00 AM,  Program Synthesis Using miniKarnren,           Illinois Central
> ...

Each item in the file records the identity, time, title and room of a talk.
Here are some SQL queries on this file.
For example, a query to find all talks at 9am with their room and title selected is:

%format select = "\mathbf{select}"
%format as = "\mathbf{as}"
%format from = "\mathbf{from}"
%format join = "\mathbf{join}"

> select room, title from talks.csv where time='09:00 AM'

Another relatively complex query to find all unique talks happening at the same time in the same room is:

> select  *
> from    (    select time, room, title as title1 from talks.csv)
> join    (    select time, room, title as title2 from talks.csv)
> where   title1  <> title2

\citet{rompf15} present a SQL to C compiler in Scala.
Their implementation first parses a SQL query into a relational algebra AST,
and then executes the query based on that AST.
Based on the LMS framework~\citep{rompf2012lightweight},
the SQL compiler is simple as an intuitive interpreter while having performance comparable to hand-written C code.

However, the implementation uses deep embedding techniques such as algebraic datatypes (\emph{case classes} in Scala) and pattern matching, for encoding and interpreting ASTs.
These techniques are a natural choice as they make the implementation straightforward.
But problems arise when the implementation evolves with new constructs introduced.
All existing interpretations have to be modified for dealing with these new constructs,
suffering from the Expression Problem.

Fortunately, it is possible to rewrite the implementation as a shallow
EDSL, because: firstly, it is common to embed SQL
into a general purpose language, for instance Circumflex
ORM\footnote{\url{http://circumflex.ru/projects/orm/index.html}} and
VigSQL\footnote{\url{https://github.com/Kangmo/vigsql}} do this in
Scala; secondly, the original implementation contains no
transformations/optimizations on ASTs. Therefore, with only modest
effort, we rewrote the implementation using the approach presented in
this pearl.  The resulting implementation is modular without
comprimising the performance.

To illustrate, let us rewrite the queries shown above using the SQL EDSL:

\weixin{TODO: can not show not matched single quote for Scala symbols}
> val q1  =  SELECT (room, title) FROM ("talks.csv" WHERE time === "09:00 AM")
> val q2  =  (
>            SELECT ()
>            FROM  (SELECT (time, room, title AS title1) FROM "talks.csv"
>            JOIN  (SELECT (time, room, title AS title2) FROM "talks.csv")
>            WHERE title1 <> title2)
>            )

Thanks to Scala's concise syntax, we can hardly tell the difference between SQL queries written in our EDSL and those written in an external DSL.
% The minor differences are that keywords are captialized, fields are represented using Scala symbol
Moreover, the EDSL approach has benefits of reusing the mechanisms provided by the host language for free.
For example, through variable declarations, we can build a complex query from parts or reuse common queries to improve the readability and modularity of the embedded programs.

The following subsections focus on rewriting the core of the original
implementation - the interpreter for relational algebra operations.
Similar rewritings are also applicable to staged versions derived
from this interpreter. % as well as other AST related definitions.

\subsection{A Relational Algebra Interpreter}
A SQL query can be represented using relational algebras:

\begin{spec}
trait Operator {
  def execOp(yld: Record => Unit): Unit
  def exec = execOp { _ => }
}
class Scan(name: String) extends Operator {
  def execOp(yld: Record => Unit) = processCSV(name)(yld)
}
class Project(out: Schema, in: Schema, op: Operator) extends Operator {
  def execOp(yld: Record => Unit) = o.execOp {rec => yld(Record(rec(in), out))}
}
class Filter(pred: Predicate, op: Operator) extends Operator {
  def execOp(yld: Record => Unit) = o.execOp {rec => if (pred.eval(rec)) yld(rec) }
}
class Join(op1: Operator, op2: Operator) extends Operator {
  def execOp(yld: Record => Unit) = op1.execOp { rec1 =>
    op2.execOp { rec2 =>
      val keys = rec1.schema intersect rec2.schema
      if (rec1(keys) == rec2(keys))
      yld(Record(rec1.fields++rec2.fields, rec1.schema++rec2.schema)) }}
}
\end{spec}

The |Operator| hierarchy defines the supported relation algebra operators.
Concretely, |Scan| processes a csv file and produces a record line by line;
|Project| rearranges the fields of a record;
|Filter| keeps only records that meet a certain predicate;
|Join| matches a record against to another, and combines them if their common fields share the same values.

A context-sensitive interpretation |execOp| is implemented throughout the hierarchy.
It executes a SQL query through taking a callback |yld| and accumulating what each operator does to records in |yld|.
The implementation of |execOp| for each operator is straightward, reflecting their respective meanings.
Another interpretation |exec| defined inside |Operator| is a wrapper of |execOp|, which supplies |execOp| with a callback that does nothing as the initial value.

\weixin{TODO: override |==| and |!=| in lhs2tex}
Some auxiliary definitions that are used in defining the |Operator| hierarchy are given below:
\begin{spec}
trait Predicate {
  def eval(rec: Record): Boolean
}
class Eq(ref1: Ref, ref2: Ref) extends Predicate {
  def eval(rec: Record) = ref1.eval(rec) == ref2.eval(rec)
}
class Ne(rec1: Ref, rec2: Ref) extends Predicate {
  def eval(rec: Record) = ref1.eval(rec) != ref2.eval(rec)
}

trait Ref {
  def eval(rec: Record): String
}
class Field(name: String) extends Ref {
  def eval(rec: Record) = rec(name)
}
class Value(x: Any) extends Ref {
  def eval(rec: Record) = x.toString
}

type Schema  =  Vector[String]
type Field   =  Vector[String]
case class Record(fields: Fields, schema: Schema) {
  def apply(name: String)   =  fields(schema indexOf name)
  def apply(names: Schema)  =  names map (apply _)
}
\end{spec}
|Predicate| captures conditions expressed in |where| clauses, e.g. equality tests (|Eq| and |Ne|).
|Ref| refers to the fields or literals used in those conditions.

\subsection{Syntax}
It would be cumbersome to directly write such a relational algebra operator to query the data file. That is why we need SQL as a surface language for queries.
In the original implementation, SQL queries are encoded using strings, and a parser will parse a query string into an operator.
To simulate the syntax of SQL queries in our shallow EDSL implementation, we define
 some smart constructors:

\begin{spec}
case class SELECT(fields: Tuple2[String,String]*) {
  def FROM(op: Operator) =
    if (fields.nonEmpty) {
      val (xs, ys) = fields.toVector.unzip
      new Project(xs,ys,op)
    }
    else op
}

trait Operator {
  ...
  def WHERE(pred: Predicate)  =  new Filter(pred, this)
  def JOIN(that: Operator)    =  new Join(this, that)
}

implicit def scan(file: String)  =  new Scan(file)
implicit def field(sym: Symbol)  =  new Field(sym.toString)
implicit def value(x: Any)       =  new Value(x)
implicit def noAS(sym: Symbol)   =  (sym.toString, sym.toString)

trait Ref {
  ...
  def ===(that: Ref)  =  new Eq(this,that)
  def <>(that: Ref)   =  new Ne(this,that)
}

class Field(name: String) extends Ref {
  ...
  def AS(sym: Symbol) = (name, sym.toString)
}
\end{spec}

Some smart constructors such as |JOIN| are defined as member methods to obtain infix notation.
We use Scala's implicit methods for automic lifting on the literals expressed in a SQL query.
To distinguish fields from string literals, Scala symbols are used.

With these definitions, we can write SQL queries (e.g. |q1| and |q2|) in a way close to the original syntax.
Beneath the surface syntax, a relational algebra operator is actually constructed.
For example, we will get the following relational algebra operator representation for |q2|:

> Filter(  Ne(Field("title1"),Field("title2")),
>          Join(  Project(Vector("time","room","title1"),Vector("time","room","title"),Scan("talks.csv")),
>                 Project(Vector("time","room","title2"),Vector("time","room","title"), Scan("talks.csv"))))

To actually run a query, we call the |exec| method:

> q2.exec

\subsection{Extensions}
More benefits of our approach emerge when the DSL evolves.
The achieve better performance, \citet{rompf15} extend the SQL processor in Section 4 of their paper.
Two new operators - aggregations and hash joins - are introduced:
the former caches the records from the composed operator;
the latter implements a more efficient join algorithm.
The introduction of hash joins further requires a new interpretation on the relational algebra operators.
This new interpretation collects an auxiliary data structure that is needed in implementing the hash join algorithm.
Therefore, two dimensions of extension are required.

However, due to the limited extensibility in their implementation,
extensions are actually done through modifying existing code.
In contrast, our implementation allow these extensions to be introduced modularly:

\begin{spec}
// interpretation extension
trait Operator2 extends Operator {
  def resultSchema: Schema
}
class Scan2(name: Table, s: Schema, delim: Char, b: Boolean) extends Scan(name) with Operator2 {
  def resultSchema = schema
}
class Project2(op: Operator2) extends Project(o) with Operator2 {
  def resultSchema = out
}
trait Filterec2(p: Predicate, op: Operator2) extends Filter(op) with Operator2 {
  def resultSchema = op.resultSchema
}
trait Join2(op1: Operator2, op2: Operator2) extends Join(op1,op2) with Operator2 {
  def resultSchema = op1.resultSchema ++ op2.resultSchema
}
// operator extension
trait Group(keys: Schema, agg: Schema, o: Operator2) extends Operator2 {
  def resultSchema = keys ++ agg
  def exec(yld: Record => Unit) {
    val hm = new HashMapAgg(keys, agg)
    o.exec { rec => hm(rec(keys)) += rec(agg) }
    hm.foreach { (k,a) => yld(Record(k ++ a, keys ++ agg)) }}
}
trait HashJoin(op1: Operator2, op2: Operator2) extends Join2 {
  override def exec(yld: Record => Unit) {
    val keys = op1.resultSchema intersect op2.resultSchema
    val hm = new HashMapBuffer(keys, op1.resultSchema)
    op1.exec { rec1 => hm(rec1(keys)) += rec1.fields }
    op2.exec { rec2 =>
      hm(rec2(keys)) foreach { rec1 =>
          yld(Record(rec1.fields ++ rec2.fields, rec1.schema ++ rec2.schema)) }}}
}
\end{spec}

The new trait |Operator2| extends |Operator| with a new interpretation |resultSchema| for collecting a schema from a operator.
All operators implement |Operator2| by inheritating their previous version and complementing |resultSchema|.
Two new objectors, |Group| and |HashJoin|, are defined.
As |HashJoin| is a specialized version of |Join|, we implement it following the definition of |RStretch| in Section~\ref{sec:construct}.
The reader may have noticed that the interpretation |execOp| becomes very much like the  interpretation |tlayout| discussed in Section~\ref{sec:ctxsensitive}.
Like |tlayout|, |execOp| is both context-sensitive (taking a |yld|) and dependent (depending on |resultSchema|).

The extension illustrates yet another strength of our approach - \emph{field extensions}.
To support processing data from a richer format of files, |Scan2| is extended with new fields.
The extended fields would not affect existing interpretations that are not concerned with them.
This would not be possible in an approach using algebraic datatypes and pattern matching.
The pattern has to be changed even if an interpretation does not use these extended fields.

The implementation presented so far only supports a subset of SQL queries.
There is plenty of room for extensions.
Not only operators, new predicates such as logical expressions can be modularly extended in a similar way.
However, to actually use the extensions, a set of smart constructors has to be defined for each version.
These smart constructors are not modular because of the explicit reference to the names from |Operator| hierarchy.
With advanced type system features from Scala~\citep{zenger05independentlyextensible},
these smart constructors can be made modular at the cost of making the implementation complicated.
