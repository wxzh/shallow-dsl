%include lhs2TeX.fmt
%include polycode.fmt
%include def.fmt

%format q1
%format q2
%format q3
%format rec1
%format rec2
%format ref1
%format ref2
%format s_o
%format s_i
%format title1
%format title2
%format (="\!("
%format [="\!["
%format ^ = " "
%format ^^ = "\;"
%format of="of"

\section{An Embedded DSL for SQL Queries}
To further illustrate the applicability of shallow OO embeddings,
we refactored an existing \emph{deep external} DSL implementation for SQL queries
to make it more \emph{modular}, \emph{shallow} and \emph{embedded}.

\subsection{Overview}
SQL is one of the most well-known DSLs for data queries.
Consider a data file |talks.csv| that contains a list of talks:

\begin{spec}
1,09:00 AM,Erlang 101 - Actor and MultiCore-Programming,New York Central
2,09:00 AM,Program Synthesis Using miniKarnren,Illinois Central
...
16,03:00 PM,Welcome to the wonderful world of Sound!,Grand Ballroom E
\end{spec}

Each item in the file records the identity, time, title and room of a talk.
Here are some SQL queries on this file.
For example, a query to find all talks at 9am with their room and title selected is:

%format select = "\mathbf{select}"
%format as = "\mathbf{as}"
%format from = "\mathbf{from}"
%format join = "\mathbf{join}"
%format group = "\mathbf{group}"
%format by = "\mathbf{by}"
%format sum = "\mathbf{sum}"

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
But problems arise when the implementation evolves with new language constructs.
All existing interpretations have to be modified for dealing with these new constructs,
suffering from the Expression Problem.

Fortunately, it is possible to rewrite \citet{rompf15}
implementation as a shallow EDSL, because the original implementation
contains no transformations/optimizations on ASTs.\bruno{earlier in
the paper (prob intro) we need to mention that transformations are
still not supported.} Therefore, with only modest effort, we rewrote
their implementation using the approach presented in this pearl. The
resulting implementation is modular with almost the same source lines of code.
\bruno{need to be careful about performance claims. What exactly
is meant here}. \weixin{cite LINQ?} Moreover, it is common to embed SQL
into a general purpose language, for instance Circumflex
ORM\footnote{\url{http://circumflex.ru/projects/orm/index.html}} does this in
Scala. Thus, instead of providing an external DSL, we provide an embedded SQL EDSL.
To illustrate, let us rewrite the queries shown above using our SQL EDSL:

\weixin{should have some space before \textquotesingle}
%format ` = "\textquotesingle"

> val q1    =  SELECT (`room, `title) FROM ("talks.csv" WHERE ^^ `time === "09:00 AM")
> val q2    =  (SELECT (`time, `room, `title AS ^^ `title1) FROM "talks.csv") JOIN
>              (SELECT (`time, `room, `title AS ^^ `title2) FROM "talks.csv")
> val q3    =  SELECT () FROM (q2 WHERE ^^ `title1 <> ^^ `title2)

Thanks to Scala's concise syntax, we can hardly tell the difference
between SQL queries written in our EDSL and those written in an
external DSL.
%% The minor differences are that keywords are
%%captialized, fields are represented using Scala symbol
Moreover, the EDSL approach has the benefit of reusing the mechanisms
provided by the host language for free.  For example, through variable
declarations, we can build a complex query from parts (e.g. |q3|) or reuse common
queries to improve the readability and modularity of the embedded
programs.

The following subsections focus on rewriting the core of the original
implementation - the interpreter for relational algebra operations.
Similar rewritings are also applicable to staged versions derived
from this interpreter. % as well as other AST related definitions.

\subsection{A Relational Algebra Interpreter}
A SQL query can be represented using relational algebra:

\begin{spec}
trait Operator {
  def execOp(yld: Record => Unit)
  def exec = new Print{val op=Operator.this} execOp { _ => }
}
trait Scan extends Operator {
  val name: String
  def execOp(yld: Record => Unit) = processCSV(name)(yld)
}
trait Print extends Operator {
  val op: Operator
  def execOp(yld: Record => Unit) = op.execOp { rec => printFields(rec.fields) }
}
trait Project extends Operator {
  val s_o, s_i: Schema
  val op: Operator
  def execOp(yld: Record => Unit) = op.execOp {rec => yld(Record(rec(s_i), s_o))}
}
trait Filter extends Operator {
  val pred: Predicate
  val op: Operator
  def execOp(yld: Record => Unit) = op.execOp {rec => if (pred.eval(rec)) yld(rec)}
}
trait Join extends Operator {
  val op1, op2: Operator
  def execOp(yld: Record => Unit) = op1.execOp { rec1 =>
      op2.execOp { rec2 =>
        val keys = rec1.schema intersect rec2.schema
        if (rec1(keys) == rec2(keys))
        yld(Record(rec1.fields++rec2.fields, rec1.schema++rec2.schema)) }}
}
\end{spec}

The |Operator| hierarchy defines the supported relational algebra operators.
Concretely, |Project| rearranges the fields of a record;
|Filter| keeps a record that meets a certain predicate;
|Join| matches a record against to another, and combines the two records if their common fields share the same values.
Two extra utility operators are defined for dealing with inputs and outputs.
|Scan| processes a csv file and produces a record per line, and
|Print| prints out the fields of a record.
\bruno{scan is not a relational algebra operator!};

A \emph{context-sensitive interpretation} |execOp| is implemented
throughout the hierarchy.  It executes a SQL query by taking a
callback |yld| and accumulating what each operator does to records in
|yld|. The implementation of |execOp| for each operator is
straightforward, reflecting their respective meanings. Another
interpretation |exec| defined inside |Operator| is the interface to execute a query.
It first wraps an operator as a |Print| for displaying the result of execution,
and then calls |execOp| with a callback that does nothing as the initial value.

\weixin{TODO: override |==| and |!=| in lhs2tex}
\weixin{TODO: reduce space after |in|.}
Some auxiliary definitions that are used in defining the |Operator| hierarchy are given below:
\begin{spec}
trait Predicate {
  def eval(rec: Record): Boolean
}
trait Eq extends Predicate {
  val ref1, ref2: Ref
  def eval(rec: Record) = ref1.eval(rec) == ref2.eval(rec)
}
trait Ne extends Predicate {
  val ref1, ref2: Ref
  def eval(rec: Record) = ref1.eval(rec) != ref2.eval(rec)
}
trait Ref {
  def eval(r: Record): String
  def <>(that: Ref)   =  new Ne{val ref1=Ref.this; val ref2=that}
}
trait Field extends Ref {
  val name: String
  def eval(rec: Record) = rec(name)
}
trait Value extends Ref {
  val v: Any
  def eval(rec: Record) = v.toString
}

type Schema  =  Vector[String]
type Field   =  Vector[String]
case class Record(fields: Fields, schema: Schema) {
  def apply(name: String)   =  fields(schema indexOf name)
  def apply(names: Schema)  =  names map (apply _)
}
\end{spec}
\noindent |Predicate| captures conditions expressed in |where| clauses, e.g. equality tests (|Eq| and |Ne|).
|Ref| refers to the fields or literals used in those conditions.

\subsection{Syntax}
It would be cumbersome to directly write such a relational algebra operator to query the data file. That is why we need SQL as a surface language for queries.
In \citet{rompf15} implementation, SQL queries are encoded using strings, and a parser will parse a query string into an operator.
To simulate the syntax of SQL queries in our shallow EDSL implementation, we define
 some smart constructors:

\begin{spec}
case class SELECT(fields: Tuple2[String,String]*) {
  def FROM(o: Operator) =
    if (fields.isEmpty) o
    else {
      val (xs, ys) = fields.toVector.unzip
      new Project{val in=xs;val out=ys;val op=o}
    }
}
trait Operator {
  ...
  def WHERE(p: Predicate)   =  new Filter  {  val pred=p; val op=Operator.this}
  def JOIN(that: Operator)  =  new Join    {  val op1=Operator.this; val op2=that}
}
trait Ref {
  ...
  def ===(that: Ref)  =  new Eq  {  val ref1=Ref.this; val ref2=that}
  def <>(that: Ref)   =  new Ne  {  val ref1=Ref.this; val ref2=that}
}
trait Field extends Ref {
  val name: String
  def AS(sym: Symbol) = (name, sym.name)
}

implicit def file2scan(file: String)      =  new Scan   {val name=file}
implicit def sym2field(sym: Symbol)       =  new Field  {val name=sym.name}
implicit def str2value(x: String)         =  new Value  {val v=x}
implicit def int2value(x: Int)            =  new Value  {val v=x}
implicit def sym2pair(sym: Symbol)        =  (sym.name, sym.name)
\end{spec}
Every SQL query starts with a |SELECT| clause for projecting a sequence of fields (possibly renamed using |AS|) from the result.
An empty sequence of fields (|SELECT ()|) means every field is selected (equivalent to |select^^*|).
To obtain infix notations, some smart constructors such as |JOIN| are defined as member methods.
In the end, a series of |implicit methods| are defined, for automatically lifting fields or literals expressed in a SQL query.
To distinguish fields from string literals, Scala symbols (starting with a \textquotesingle) are used.
Consequently, for a condition like |`time === "09:00"|, |`time| will be lifted as a |Field| while "09:00" will be lifted as a |Value|.

With these definitions, we can write SQL queries (e.g. |q1|) in a way close to the original syntax.
Beneath the surface syntax, a relational algebra operator is actually constructed.
For example, we will get the following operator representation for |q3|:

> Filter(  Ne(Field("title1"),Field("title2")),
>          Join(  Project(Vector("time","room","title1"),Vector("time","room","title"),Scan("talks.csv")),
>                 Project(Vector("time","room","title2"),Vector("time","room","title"), Scan("talks.csv"))))

To actually run a query, we call the |exec| method.
For example, the execution result of |q2| is:

< scala > q2.exec
< New York Central,Erlang 101 - Actor and Multi-Core Programming
< Illinois Central,Program Synthesis Using miniKanren
< ...

where the room and title of the first two items from |talks.csv| are displayed.


\subsection{Extensions}
More benefits of our approach emerge when the DSL evolves.
To achieve better performance, Rompf and Amin extend the SQL processor.
Two new operators - aggregations and hash joins - are introduced.
The introduction of hash joins additionally requires a new interpretation on the relational algebra operators.
This new interpretation collects an auxiliary data structure that is needed in implementing a efficient join algorithm.
Therefore, two dimensions of extensibility are required.

However, due to the limited extensibility in their implementation,
extensions are actually done through modifying existing code.
In contrast, our implementation allows extensions to be introduced modularly:

\begin{spec}
// interpretation extension
trait Operator2 extends Operator {
  override def exec = new Print2{val op=Operator2.this} execOp { _ => }
  def resultSchema: Schema
}
trait Scan2 extends Scan with Operator2 {
  val delim: Char
  def resultSchema = Vector()
  override def execOp(yld: Record => Unit) = processDSV(name,delim)(yld)
}
trait Print2 extends Print with Operator2 {
  val op: Operator2
  def resultSchema = Vector()
  override def execOp(yld: Record => Unit) {
    val schema = op.resultSchema
    printSchema(schema)
    op.execOp { rec => printFields(r.fields) }}
}
trait Project2 extends Project with Operator2 {
  val op: Operator2
  def resultSchema = s_o
}
trait Filter2 extends Filter with Operator2 {
  val op: Operator2
  def resultSchema = op.resultSchema
}
// operator extension
trait Group extends Operator2 {
  val keys, agg: Schema
  val op: Operator2
  def resultSchema = keys ++ agg
  def execOp(yld: Record => Unit) {
    val hm = new HashMap[Fields,Seq[Int]]
    op execOp { rec =>
      val kvs = rec(keys)
      val sums = hm.getOrElseUpdate(kvs,agg.map(_ => 0))
      hm(kvs) = (sums,rec(agg).map(_.toInt)).zipped map (_ + _)}
    hm foreach { case (k,a) => yld(Record(k ++ a.map(_.toString), keys ++ agg)) }}
}
trait HashJoin extends Join with Operator2 {
  val op1, op2: Operator2
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
\end{spec}
\bruno{I don't feel very confident that invalid Scala code (i.e. code that does not type-check).
The code presented in the paper needs to be carefully checked; possibly pasting it back into Eclipse and
checking that that compiles.}
\weixin{All code has been checked}

The new trait |Operator2| extends |Operator| with a new interpretation |resultSchema| for collecting a schema from a operator.
All operators implement |Operator2| by inheriting their previous version and complementing |resultSchema|.
Besides, two new traits, |Group| and |HashJoin|, are defined.
|Group| is a new relational algebra for supporting |group by ... sum ^^ ...| clause in SQL.
It groups records and sums up according to the specified fields from the composed operator,
|HashJoin| is a replacement of |Join|, which overrides |execOp| with a more efficient implementation based on caching.
The reader may notice that the interpretation |execOp| becomes very much like the interpretation |tlayout| discussed in Section~\ref{sec:ctxsensitive}.
Like |tlayout|, |execOp| is both context-sensitive (taking a |yld|) and dependent (depending on |resultSchema|).

The extension illustrates yet another strength of our approach - \emph{field extensions}.
To support processing data from a more general format of files (delmiter-separated values), |Scan2| is extended with a new field |delim|.
The extended field would not affect existing interpretations that are not concerned with it.
This would not be possible in an approach using algebraic datatypes and pattern matching.
The pattern has to be changed even if an interpretation does not use these extended fields.

The implementation presented so far only supports a subset of SQL queries.
There is still plenty of room for extensions.
Not only operators, new predicates such as logical expressions can be modularly added in a similar way.

\paragraph{Syntax}
To support the syntax for the extended version of the relational operator interpreter, some extra smart constructors need to be defined. For example,

\begin{spec}
trait Operator2 extends Operator {
  ...
  override def WHERE(p: Predicate) = new Filter2{val pred=p; val op=Operator2.this}
  def JOIN(that: Operator2) = new HashJoin{val op1=Operator2.this; val op2=that}
  def GROUP_BY(xs: Field*) = SumClause(this,xs:_*)
  case class SumClause(o: Operator2, xs: Field*) {
    object SUM {
      def apply(ys: Field*) =
        new Group{val keys=xs.map{_.name}.toVector; val agg=ys.map(_.name).toVector; val op=o}
    }
  }
}
\end{spec}
\bruno{you mean for the syntax right? You can be more specific.}
|GROUP_BY| and |SumClause| are new smart constructors defined for |Group|.
Meanwhile, some existing smart constructors need to be redefined because of the explicit reference to the names in a older version.
However, smart constructors declared as member methods like |JOIN| may cause some troubles.
We cannot override |JOIN| because covariant refinement on arguments is not possible in our approach.
Instead, an overloaded |JOIN| that takes a |Operator2| is introduced.
As a result, the object interface |Operator2| is polluted and there is a risk that the wrong version is invoked.
To tackle this problem, we have also implemented another version of the SQL EDSL.
The implementation uses advanced type system features from Scala~\citep{zenger05independentlyextensible} and is more complicated than the version presented in this section.
