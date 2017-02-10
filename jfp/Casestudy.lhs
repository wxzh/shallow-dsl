\section{Case Study}
To further illustrate the applicability of our OO approach, we took an existing real-world DSL and rewrote .

The original implementation is an external DSL that first parses an SQL query into an relational algebra AST and then executes the query by interpreting that AST.
By using the LMS framework~\cite{}, the implementation has performance comparable to the hand-written C code while nearly as simple as an intuitive interpreter.
However, the encoding employs deep embedding techniques such as algebraic datatypes (sealed case classes in Scala) and pattern matching.
As a result, the implementation suffers from the Expression Problem for adding new constructs.
We found that it is possible to make the implementation as a shallow EDSL: 1) it is common to embed SQL queries into a general purpose language\cite{} \url{http://circumflex.ru/projects/orm/index.html} \url{https://github.com/Kangmo/vigsql};
2) there is no transformation/optimization in the original ;
With modest effort, we are able to rewrite the implementation using the approach presented in this pearl.
The resulting implementation is modular without comprimising the performance.
This section focuses on the interpreter. Staged compiler based on this interpreter is omitted as LMS-related stuff is out of the concern of this pearl.
Nevertheless, similar rewriting can also apply to the

%Although adding new interpretations is easy for such encoding, adding new constructs become hard.
%Sealed case classes forces definitions for new constructs appeared on the same file and modifications on existing interpretations to avoid pattern matching failures.
%In other words, sealed case classes suffer from the Expression Problem.

%We found that the implementation is not necessarily to be deep since it does not contain any transformation/optimization.
%Hence, with modest effort, we can recode that DSL using our approach without comprimising.
%More importantly, the resulting implementation is modular and extensible,
%allowing both new constructs and new interpretations to be introduced.
%deep embedding

\subsection{SQL Query Processor}
~\cite{} presented an external DSL for processing SQL queries in Scala.
To demonstrate the DSL, suppose that there is a csv file that contains a list of talks:

> tid,time,title,room
> 1,09:00 AM,Erlang 101 - Actor and MultiCore Programming,New York Central
> 2,09:00 AM,Program Synthesis Using miniKarnren,Illinois Central
> ...

Each item records the id, time, title and room of a talk.
Here are some SQL queries on this file.
For example, a query to find all talks at 9am with their room and title printed is:

%format select = "\mathbf{select}"
%format as = "\mathbf{as}"
%format from = "\mathbf{from}"
%format join = "\mathbf{join}"

> select room, title from talks.csv from talks.csv where time='09:00 AM'

Another relative complex query to find all unique talks happening at the same time in the same room is:

> select *
> from (select time, room, title as title1 from talks.csv)
> join (select time, room, title as title2 from talks.csv)
> where title1 <> title2


\subsection{Initial Implementation}
\paragraph{Their Implementation}
In the original implementation, SQL queries are firstly parsed as relational algebra ASTs.
The definition of |Operator|

%\begin{figure}
\begin{spec}
// relational algebra ops
sealed abstract class Operator
case class Scan(name: Table) extends Operator
case class Print(parent: Operator) extends Operator
case class Project(out: Schema, in: Schema, parent: Operator) extends Operator
case class Filter(pred: Predicate, parent: Operator) extends Operator
case class Join(parent1: Operator, parent2: Operator) extends Operator

// filter predicates
sealed abstract class Predicate
case class Eq(a: Ref, b: Ref) extends Predicate
case class Ne(a: Ref, b: Ref) extends Predicate

sealed abstract class Ref
case class Field(name: String) extends Ref
case class Value(x: Any) extends Ref
\end{spec}
%\caption{Relation algebra AST}
%\end{figure}

Some auxilary AST definitions are needed:
|Predicate| captures conditions (e.g. equal and not equal) in a |where| clause of a query;
|Ref| captures the fields and literals used in those conditions.

For example, after parsing, we will get the following relational algebra AST for the complex query shown above:

> Filter(Ne(Field("title1"),Field("title2")),
>   Join(
>     Project(Vector("time","room","title"),Vector("time","room","title1"),
>       Scan("talks.csv")),
>     Project(Vector("time","room","title"),Vector("time","room","title2"),
>       Scan("talks.csv"))))

The result of a query can then be given by interpreting the relational algebra AST:

\begin{spec}
def execOp(o: Operator)(yld: Record => Unit): Unit = o match {
  case Scan(filename) =>
    processCSV(filename)(yld)
  case Print(parent) =>
    execOp(parent) { rec =>
      printFields(rec.fields) }
  case Filter(pred, parent) =>
    execOp(parent) { rec =>
      if (evalPred(pred)(rec)) yld(rec) }
  case Project(newSchema, parentSchema, parent) =>
    execOp(parent) { rec =>
      yld(Record(rec(parentSchema), newSchema)) }
  case Join(left, right) => execOp(left) { rec1 =>
    execOp(right) { rec2 =>
      val keys = rec1.schema intersect rec2.schema
      if (rec1(keys) == rec2(keys))
        yld(Record(rec1.fields ++ rec2.fields, rec1.schema ++ rec2.schema)) }}
}

def evalRef(p: Ref)(rec: Record) = p match {
  case Value(a: String) => a
  case Field(name) => rec(name)
}

def evalPred(p: Predicate)(rec: Record) = p match {
  case Eq(a,b) => evalRef(a)(rec) == evalRef(b)(rec)
  case Ne(a,b) => evalRef(a)(rec) != evalRef(b)(rec)
}
\end{spec}
|execOp| is a context-sensitive interpretation pretty much like |tlayout| discussed in Section~\ref{}, where |yld| is a callback that accumulates what each operator does to the records.
|Scan| processes a csv file and produces a record line by line;
|Print| prints the fields of a record;
|Filter| filter out a record that does not meet the predicate;
|Project| rearranges the fields of a record;
|Join| matches a record from left against to another from right and combines them if their common fields have the same values.
  With modest modifications on this simple interpreter,
  The LMS~\cite{} related stuff is not a concern of this pearl

\paragraph{Our Implementation}
Here is our implementation:
%\begin{figure}
\begin{spec}
trait Operator {
  def exec(yld: Record => Unit): Unit
  def exec: Unit = exec { _ => }
}
trait Scan extends Operator {
  val name: Table
  def exec(yld: Record => Unit) = processCSV(name)(yld)
}
trait Print extends Operator {
  val parent: Operator
  def exec(yld: Record => Unit) =
    parent.exec { rec => printFields(rec.fields) }
}
trait Project extends Operator {
  val in, out: Schema
  val parent: Operator
  def exec(yld: Record => Unit) = parent.exec { rec => yld(Record(rec(in), out)) }
}
trait Filter extends Operator {
  val pred: Predicate
  val parent: Operator
  def exec(yld: Record => Unit) = parent.exec { rec => if (pred.eval(rec)) yld(rec) }
}
trait Join extends Operator {
  val left, right: Operator
  def exec(yld: Record => Unit) =
    left.exec { rec1 =>
      right.exec { rec2 =>
        val keys = rec1.schema intersect rec2.schema
        if (rec1(keys) == rec2(keys))
          yld(Record(rec1.fields ++ rec2.fields, rec1.schema ++ rec2.schema)) }}
}

trait Predicate {
  def eval(rec: Record): Boolean
}
trait Eq extends Predicate {
  val left, right: Ref
  def eval(rec: Record) = left.eval(rec) == right.eval(rec)
}

trait Ref {
  def eval(rec: Record): String
}
trait Field extends Ref {
  val name: String
  def eval(rec: Record) = rec(name)
}
trait Value extends Ref {
  val x: Any
  def eval(rec: Record) = x.toString
}
\end{spec}
%\caption{Our SQL engine}
%\end{figure}

\subsection{Extensions}
More benefits of our approach emerge when the DSL evolves.
In Section 4 of ~\cite{}, Rompf and Amin extended their SQL processor for better performance.
Two new operators, aggregations and hash joins, are added.
The former caches the records from the composed operator; the latter implements a more efficient join algorithm.
The algorithm further requires a new interpretation to calculate an auxiliary data structure on operators.
In other words, two dimensions of extension are required.
However, the use of sealed case classes in the orginal implementation disallows modular extensions on both dimensions.
Whereas our approach

\paragraph{Their Implmenetation}
In the original implementation, extending constructs is done through adding new case classes to the |Operator| hierarchy.
However, the definition of |execOp| has to be modified to avoid runtime pattern matching failures.

\begin{spec}
sealed abstract class Operator
...
case class HashJoin(parent1: Operator, parent2: Operator) extends Operator
case class Group(keys: Schema, agg: Schema, parent: Operator) extends Operator

def resultSchema(o: Operator): Schema = o match {
  case Scan(_, schema, _, _)     =>  schema
  case Print(parent)             =>  Schema()
  case Project(schema, _, _)     =>  schema
  case Filter(pred, parent)      =>  resultSchema(parent)
  case Join(left, right)         =>  resultSchema(left) ++ resultSchema(right)
  case Group(keys, agg, parent)  =>  keys ++ agg
  case HashJoin(left, right)     =>  resultSchema(left) ++ resultSchema(right)
}

def execOp(o: Operator)(yld: Record => Unit): Unit = o match {
  ...
  case Group(keys, agg, parent) =>
    val hm = new HashMapAgg(keys, agg)
    execOp(parent) { rec => hm(rec(keys)) += rec(agg) }
    hm foreach { (k,a) => yld(Record(k ++ a, keys ++ agg)) }
  case HashJoin(left, right) =>
    val keys = resultSchema(left) intersect resultSchema(right)
    val hm = new HashMapBuffer(keys, resultSchema(left))
    execOp(left) { rec1 => hm(rec1(keys)) += rec1.fields }
    execOp(right) { rec2 =>
      hm(rec2(keys)) foreach { rec1 =>
        yld(Record(rec1.fields ++ rec2.fields, rec1.schema ++ rec2.schema))
      }
    }
}
\end{spec}

An auxiliary interpretation, |resultSchema|, is needed for complementing the |HashJoin| case.

% Very much like |tlayout| discussed in Section~\ref{}, |execOp| is a non-trivial interpretation - both dependent (depending on |resultSchema|) and context-sensitive (taking a |yld|).

\paragraph{Our Implementation}
Our approach makes it simple to add new constructs (|Group| and |HashJoin|) as well as new interpretations (|resultSchema|):
\begin{spec}
trait Operator2 extends Operator {
  def resultSchema: Schema
}
trait Scan2 extends Scan with Operator2 {
  val schema: Schema
  val delim: Char
  val extSchema: Boolean
  def resultSchema = schema
  override def exec(yld: Record => Unit) = processCSV(name, schema, delim, extSchema)(yld)
}
trait Print2 extends Print with Operator2 {
  val parent: Operator2
  def resultSchema = Schema()
  def exec(yld: Record => Unit) = {
    val schema = parent.resultSchema
    printSchema(schema)
    parent.exec { rec => printFields(rec.fields) }
  }
}
trait Project2 extends Project with Operator2 {
  val parent: Operator2
  def resultSchema = out
}
trait Filter2 extends Filter with Operator2 {
  val parent: Operator2
  def resultSchema = parent.resultSchema
}
trait Join2 extends Join with Operator2 {
  val left, right: Operator2
  def resultSchema = left.resultSchema ++ right.resultSchema
}
trait Group extends Operator2 {
  val keys: Schema
  val agg: Schema
  val parent: Operator2
  def resultSchema = keys ++ agg
  def exec(yld: Record => Unit) = {
    val hm = new HashMapAgg(keys, agg)
    parent.exec { rec =>
      hm(rec(keys)) += rec(agg)
    }
    hm foreach { case (k,a) =>
      yld(Record(k ++ a, keys ++ agg))
    }
  }
}
trait HashJoin extends Join2 {
  override def exec(yld: Record => Unit) = {
    val keys = left.resultSchema intersect right.resultSchema
    val hm = new HashMapBuffer(keys, left.resultSchema)
    left.exec { rec1 =>
      hm(rec1(keys)) += rec1.fields
    }
    right.exec { rec2 =>
      hm(rec2(keys)) foreach { rec1 =>
          yld(Record(rec1.fields ++ rec2.fields, rec1.schema ++ rec2.schema))
      }
    }
  }
}
\end{spec}
The definition of |HashJoin| shows some extra modularity provided by OOP.
Instead of directly implementing |Operators|, |HashJoin| extends |Join| and overrides the definition of |exec|. This way |resultSchema| as well as field declaration would not be duplicated.

Extensions on |Predicate|, such as adding new predicates like |LessThan|, |And| or |Or|, are left as exercises
on the companion website\footnote{\url{http://scala-lms.github.io/tutorials/query.html}}.
Such extensions can also be modularly introduced by adding new traits that implement |Predicate|.

% wrappers & client code
