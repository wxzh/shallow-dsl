%include lhs2TeX.fmt
%include polycode.fmt
%include def.fmt

%format q0
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
%format += = "\mathrel{+}="
%format != = "\neq"
%format ` = "\textquotesingle"
%format MultiCore = "Multi\text{-}Core"

\invisiblecomments

\section{An Embedded DSL for SQL Queries}
To further illustrate the applicability of shallow OO embeddings,
we refactored an existing \emph{deep external} DSL implementation for SQL queries
to make it more \emph{modular}, \emph{shallow} and \emph{embedded}.
The full implementation can be found online at:
\url{http://fill.me}\footnote{{\bf Note to reviewers:}
Following this link will reveal the identity of the paper authors.}
\bruno{Add url here.}

\subsection{Overview}
SQL is one of the most well-known DSLs for data queries.
Consider a data file |talks.csv| that contains a list of talks,
where each item  records the identity, time, title and room of a talk:

\begin{spec}
1,09:00 AM,Erlang 101 - Actor and MultiCore Programming,New York Central
...
16,03:00 PM,Welcome to the wonderful world of Sound!,Grand Ballroom E
\end{spec}

%% 16,03:00 PM,Welcome to the wonderful world of Sound!,Grand Ballroom E

%format select = "\mathbf{select}"
%format as = "\mathbf{as}"
%format from = "\mathbf{from}"
%format join = "\mathbf{join}"
%format group = "\mathbf{group}"
%format by = "\mathbf{by}"
%format sum = "\mathbf{sum}"

\noindent We can write some SQL queries on this file.
A simple query to list all the items in |talks.csv| is:

> select * from talks.csv

\noindent Another query to find all talks at 9am with their room and title selected is:

> select room, title from talks.csv where time='09:00 AM'

Yet another relatively complex query to find all unique talks happening at the same time in the same room is:

> select  *
> from    (    select time, room, title as title1 from talks.csv)
> join    (    select time, room, title as title2 from talks.csv)
> where   title1  <> title2

\indent \citet{rompf15} present a SQL to C compiler in Scala.
Their implementation first parses a SQL query into a relational algebra AST,
and then executes the query based on that AST.
Using the LMS framework~\citep{rompf2012lightweight},
the SQL compiler is nearly as simple as an intuitive interpreter while having the performance comparable to hand-written C code.

However, the implementation uses deep embedding techniques such as algebraic datatypes (\emph{case classes} in Scala) and pattern matching, for encoding and interpreting ASTs.
These techniques are a natural choice as they make the implementation straightforward.
But problems arise when the implementation evolves with new language constructs.
All existing interpretations have to be modified for dealing with these new constructs,
suffering from the Expression Problem.

Fortunately, it is possible to rewrite \citet{rompf15} implementation
as a shallow EDSL, because the original implementation contains no
transformations/optimizations on ASTs, which would be another
motivation to use a deep embedding. Therefore, with only modest
effort, we refactored their implementation using the approach
presented in this pearl. The resulting implementation is modular
without increasing the source lines of code.  Moreover, it is common
to embed SQL into a general purpose language, for instance Circumflex
ORM\footnote{\url{http://circumflex.ru/projects/orm/index.html}} does
this in Scala. Thus, instead of providing an external DSL, we provide
an embedded SQL EDSL. The queries shown above can be written in our SQL EDSL:

> val q0     =  FROM ("talks.csv")
> val q1     =  q0 WHERE ^^ `time === "09:00 AM" SELECT (`room, `title)
> val q2     =  q0 SELECT (`time, `room, `title AS ^^ `title1)    JOIN
>               (q0 SELECT (`time, `room, `title AS ^^ `title2))  WHERE
>               `title1 <> `title2

Thanks to the good support for EDSL in Scala, we can precisely model the syntax of SQL.
In fact, the syntax of our EDSL is closer to the syntax of LINQ~\citep{meijer2006linq}, where |select| is a terminating rather than a beginning clause of a query.
Compared to an external DSL approach, our EDSL approach has the benefit of reusing the mechanisms
provided by the host language for free.  For example, through variable
declarations, we can build a complex query from parts or reuse common
queries to improve the readability and modularity of the embedded
programs, as illustrated by |q2|.

The following subsections focus on rewriting the core of the original
implementation - the interpreter for relational algebra operations.
Similar rewritings are also applicable to staged versions derived
from this interpreter.

\subsection{A Relational Algebra Interpreter}
\begin{figure}
\begin{tabular}{ll}
\begin{minipage}{.5\textwidth}
\begin{spec}
trait Semantics {
{- // relational algebra operators -}
trait Operator {
  def execOp(yld: Record => Unit)
  def exec: Unit =
    new Print{val op=Operator.this}.execOp { _ => }
}
trait Scan extends Operator {
  val name: String
  def execOp(yld: Record => Unit) =
    processCSV(name)(yld)
}
trait Print extends Operator {
  val op: Operator
  def execOp(yld: Record => Unit) =
    op.execOp { rec => printFields(rec.fields) }
}
trait Project extends Operator {
  val s_o, s_i: Schema
  val op: Operator
  def execOp(yld: Record => Unit) =
    op.execOp {rec => yld(Record(rec(s_i), s_o))}
}
trait Filter extends Operator {
  val pred: Predicate
  val op: Operator
  def execOp(yld: Record => Unit) =
    op.execOp {rec => if (pred.eval(rec)) yld(rec)}
}
trait Join extends Operator {
  val op1, op2: Operator
  def execOp(yld: Record => Unit) =
    op1.execOp { rec1 =>
      op2.execOp { rec2 =>
        val keys = rec1.schema.intersect(rec2.schema)
        if (rec1(keys) == rec2(keys))
        yld(Record(rec1.fields++rec2.fields,
          rec1.schema++rec2.schema)) }}
}
\end{spec}
\end{minipage}
&
\begin{minipage}{.5\textwidth}
\begin{spec}
{- // continue here \ldots -}
{- // filter predicates -}
trait Predicate {
  def eval(rec: Record): Boolean
}
trait Eq extends Predicate {
  val ref1, ref2: Ref
  def eval(rec: Record) =
    ref1.eval(rec) == ref2.eval(rec)
}
trait Ne extends Predicate {
  val ref1, ref2: Ref
  def eval(rec: Record) =
    ref1.eval(rec) != ref2.eval(rec)
}

{- // literals -}
trait Ref {
  def eval(rec: Record): String
}
trait Field extends Ref {
  val name: String
  def eval(rec: Record) = rec(name)
}
trait Value extends Ref {
  val v: Any
  def eval(rec: Record) = v.toString
}

{- // auxiliary definitions -}
type Schema  =  Vector[String]
type Field   =  Vector[String]
case class Record(fields: Fields, schema: Schema) {
  def apply(name: String) = fields(schema.indexOf(name))
  def apply(names: Schema) = names.map(apply(_))
}
def processCSV(file: String)(yld: Record => Unit) = ...
def printFields(fields: Fields) = ...
}
\end{spec}
\end{minipage}
\\
\end{tabular}
\caption{A relational algebra interpreter.}
\label{interp}
\end{figure}

\bruno{too much code here: pick Operator and 2 more traits and put ... for the rest.
Explain in text that implement traits for various operators for relational algebra.
Mention at the start of this section that full code is available online.
}

Fig.~\ref{interp} shows the refactored relational algebra interpreter.
The |Operator| hierarchy defines the supported relational algebra operators.
Concretely, |Project| rearranges the fields of a record;
|Filter| keeps a record only when it meets a certain predicate;
|Join| matches a record against to another, and combines the two records if their common fields share the same values.
Two extra utility operators are defined for dealing with inputs and outputs:
|Scan| processes a csv file and produces a record per line;
|Print| prints out the fields of a record.

A \emph{context-sensitive interpretation} |execOp| is implemented
throughout the hierarchy.  It executes a SQL query by taking a
callback |yld| and accumulating what each operator does to a record in
|yld|. The implementation of |execOp| for each operator is
straightforward, reflecting their respective meanings. Another
interpretation |exec| defined inside |Operator| is the user interface to execute a query.
It first wraps an operator into a |Print| for displaying the result of execution,
and then calls |execOp| with a callback that does nothing as the initial value.

Two auxilary hierarchies are needed: |Predicate| captures the predicate used in a |Filter| operator; |Ref| refers to literals used in predicates.
An interpretation |eval| is defined in these two hierarchies.


\bruno{Don't show the auxiliary definitions (unless there's a strong reason to); 
again this can be mentioned in text.}

\subsection{Syntax}
It would be cumbersome to directly write such a relational algebra operator to query data files. That is why we need SQL as a surface language for queries.
In \citet{rompf15} implementation, SQL queries are encoded using strings, and a parser will parse a query string into an operator.
We employ well-established Scala techniques to simulate the syntax of SQL queries in our shallow EDSL implementation.
Details of the syntax implementation is beyond the scope of this pearl.
The interested reader can view them in our online implementation.
\bruno{Here you should say remark that the syntax is implemented using mostly well-established Scala techniques;
describe them briefly in text. Remark that the syntax techniques are beyound the scope of this pearl, but the interested reader 
can view them in our online implementation. Don't show the code for syntax}

With the syntax defined, we are able to write SQL queries in a concise way, as illustrated by |q0|, |q1| and |q2|.
Beneath the surface syntax, a relational algebra operator object is constructed indeed.
For example, we will get the following operator object for |q2|:

> Filter(  Ne(Field("title1"),Field("title2")),
>          Join(  Project(Vector("time","room","title1"),Vector("time","room","title"),Scan("talks.csv")),
>                 Project(Vector("time","room","title2"),Vector("time","room","title"), Scan("talks.csv"))))

To actually run a query, we call the |exec| method.
For example, the execution result of |q2| is:

< scala > q2.exec
< New York Central,Erlang 101 - Actor and MultiCore Programming
< ...

\noindent where the first item from |talks.csv| is selected with its room and title displayed while the last item is excluded.

\subsection{Extensions}
More benefits of our approach emerge when the DSL evolves.
Rompf and Amin extend the SQL processor in various ways to achieve better expressiveness, performance and flexibility.
The extensions include a new operator |Group| for aggregations, a efficient implementation of |Join| and a more flexible |Scan| that can deal with more forms of files.

However, due to the limited extensibility in their implementation,
extensions are actually done through modifying existing code.
In contrast, our implementation allows extensions to be introduced modularly:
\begin{spec}
trait SemanticsExt extends Semantics {
  {- // interpretation extension -}
  trait Operator extends super.Operator {
    override def exec = new Print{val op=Operator.this}.execOp { _ => }
    def resultSchema: Schema
  }
  trait Scan extends super.Scan with Operator {
    val delim: Char ^^ {- // field extensions -}
    def resultSchema = Schema()
    override def execOp(yld: Record => Unit) = processDSV(name,delim)(yld)
  }
  ...
  {- // operator extension -}
  trait Group extends Operator {...}
  trait Join extends super.Join with Operator {
    val op1, op2: Operator ^^ {- // type refinement -}
    def resultSchema = op1.resultSchema ++ op2.resultSchema
    override def execOp(yld: Record => Unit) {
      val keys = op1.resultSchema.intersect(op2.resultSchema)
      val hm = new HashMap[Fields,ArrayBuffer[Record]]
      op1.execOp { rec1 =>
        val buf = hm.getOrElseUpdate(rec1(keys), new ArrayBuffer[Record])
        buf += rec1 }
      op2.execOp { rec2 =>
        hm.get(rec2(keys)).foreach { _.foreach { rec1 =>
          yld(Record(rec1.fields ++ rec2.fields, rec1.schema ++ rec2.schema)) }}}
    }
  }
}
\end{spec}
\noindent The interface |Operator| is extended with a new interpretation |resultSchema| for collecting a schema.
All operators implement the extended interface by inheriting their previous version and complementing |resultSchema|.
|Join| overrides |execOp| to replace naive nested loop with an efficient hash map based algorithm, where the new interpretation |resultSchema| is called for .
The reader may notice that the interpretation |execOp| becomes very much like the interpretation |tlayout| discussed in Section~\ref{sec:ctxsensitive}.
Like |tlayout|, |execOp| is both context-sensitive (taking a |yld|) and dependent (depending on |resultSchema|).
Besides, a new operator |Group| is defined for supporting |group by| clause in SQL.
Note that |execOp| needs to be overridden, as a new version of |Print| is implemented.

\bruno{Again, here you should pick Operator2 and one or two more of the traits that illustrate 
interesting code. The rest should be ...}
\bruno{I don't feel very confident that invalid Scala code (i.e. code that does not type-check).
The code presented in the paper needs to be carefully checked; possibly pasting it back into Eclipse and
checking that that compiles.}
\weixin{All code has been checked}

The extension illustrates yet another strength of our approach - \emph{field extensions}.
To support processing data from a more general format of files (delmiter-separated values), |Scan| is extended with a new field |delim|.
The extended field would not affect existing interpretations that are not concerned with it.
This would not be possible in an approach using algebraic datatypes and pattern matching.
The pattern has to be changed even if an interpretation does not use these extended fields.

To run SQL queries on top of this extended version of relational algebra interpreter,
we need to define the syntax again.
Similar to |execOp|, some old syntax implementations can not be reused because they refer to outdated names for creating objects.
This may cause some code duplication in the extended syntax.
This problem can be partly solved by using some advanced type system features from Scala~\citep{zenger05independentlyextensible}.
The resulting syntax is modular and is decoupled from the semantics, which can also be found online.
\bruno{you mean for the syntax right? You can be more specific.}

\begin{comment}
\paragraph{Syntax}
To support the syntax for the extended version of the relational operator interpreter, a new set of smart constructors need to be defined.
We not only need to define a new smart construtor for |Group| but also redefine
existing smart constructors because they refer to outdated names.
Smart constructors declared as member methods may cause some troubles:

\begin{spec}
trait Operator extends super.Operator {
  ...
  override def WHERE(p: Predicate)  =  new Filter2   {val pred=p; val op=Operator2.this}
  def JOIN(that: Operator2)         =  new HashJoin  {val op1=Operator2.this; val op2=that}
}
\end{spec}

Covariant type refinements can be performed on return types but not on argument types.
Therefore, |WHERE| is overridable and |JOIN| is not.
This is a limitation of the approach we adopted~\citep{eptrivially16}.
A workaround here is to overload another |JOIN| method.
But this will pollute the object interface |Operator| and has a risk that a wrong version of |JOIN| is invoked.
This problem can be tackled with advanced type system features from Scala~\citep{zenger05independentlyextensible}.
The price to pay is the complication of the implementation.
We also provide such a version for reference.
\end{comment}
