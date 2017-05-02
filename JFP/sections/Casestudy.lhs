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
\url{https://github.com/wxzh/shallow-dsl/tree/master/src/sql}.\footnote{{\bf Note to reviewers:}
Following this link will reveal the identity of the paper authors.}

\subsection{Overview}
SQL is one of the most well-known DSLs for data queries.
Consider a data file |talks.csv| that contains a list of talks,
where each item  records the identity, time, title and room of a talk:

\begin{spec}
tid,  time,      title,                                         room
1,    09:00 AM,  Erlang 101 - Actor and MultiCore Programming,  New York Central
...
16,   03:00 PM,  Welcome to the wonderful world of Sound!,      Grand Ballroom E
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

\noindent Another query to find all talks at 9 am with their room and title selected is:

> select room, title from talks.csv where time='09:00 AM'

Yet another relatively complex query to find all unique talks happening at the same time in the same room is:

> select  *
> from    (    select time, room, title as title1 from talks.csv)
> join    (    select time, room, title as title2 from talks.csv)
> where   title1  <> title2

\indent \cite{rompf15} present a SQL to C compiler in Scala.
Their implementation first parses a SQL query into a relational algebra AST,
and then executes the query based on that AST.
Using the LMS framework~\cite{rompf2012lightweight},
the SQL compiler is nearly as simple as an intuitive interpreter while having the performance comparable to hand-written C code.

However, the implementation uses deep embedding techniques such as algebraic datatypes (\emph{case classes} in Scala) and pattern matching, for encoding and interpreting ASTs.
These techniques are a natural choice as they make the implementation straightforward.
But problems arise when the implementation evolves with new language constructs.
All existing interpretations have to be modified for dealing with these new constructs,
suffering from the Expression Problem.

Fortunately, it is possible to rewrite \cite{rompf15} implementation
as a shallow EDSL, because the original implementation contains no
transformations/optimizations on ASTs, which would be another
motivation to use a deep embedding. Therefore, with only modest
effort, we refactored their implementation using the approach
presented in this pearl. Using almost the same source lines of code, the implementation is made modular.  Moreover, it is common
to embed SQL into a general purpose language, for instance Circumflex
ORM\footnote{\url{http://circumflex.ru/projects/orm/index.html}} does
this in Scala. Thus, instead of providing an external DSL, we provide
an embedded SQL EDSL. The queries shown above can be written in our SQL EDSL:

> val q0     =  FROM ("talks.csv")
> val q1     =  q0 WHERE ^^ `time === "09:00 AM" SELECT (`room, `title)
> val q2     =  q0 SELECT (`time, `room, `title AS ^^ `title1)    JOIN
>               (q0 SELECT (`time, `room, `title AS ^^ `title2))  WHERE
>               `title1 <> `title2

Thanks to the good support for EDSLs in Scala, we can precisely model the syntax of SQL.
In fact, the syntax of our EDSL is closer to the syntax of LINQ~\cite{meijer2006linq}, where |select| is a terminating rather than a beginning clause of a query.
Compared to an external DSL approach, our EDSL approach has the benefit of reusing the mechanisms
provided by the host language for free.  For example, through variable
declarations, we can build a complex query from parts or reuse common
queries to improve the readability and modularity of the embedded
programs, as illustrated by |q2|.

The following subsections give an overview of rewriting the core of the original
implementation - the interpreter for relational algebra operations.
Similar rewritings are also applicable to staged versions derived
from this interpreter.

\subsection{A Relational Algebra Interpreter}
A SQL query can be represented using a relational algebra operator.
The basic interface of operators is modeled in Scala as a |trait|:

> trait Operator {
>   def execOp(yld: Record => Unit)
>   def exec: Unit = new Print{val op=Operator.this}.execOp { _ => }
> }

A \emph{context-sensitive interpretation} |execOp| should be implemented in concrete operators.
The method |execOp| executes a SQL query by taking a callback |yld| and accumulating what each concrete operator does to a record in
|yld|. The interpretation |exec| is a wrapper of |execOp|, supplying a callback that does nothing as the initial value.

Concrete operators implement |Operator| through defining |execOp|:

> trait Join extends Operator {
>   val op1, op2: Operator
>   def execOp(yld: Record => Unit) =
>     op1.execOp { rec1 =>
>       op2.execOp { rec2 =>
>         val keys = rec1.schema.intersect(rec2.schema)
>         if (rec1(keys) == rec2(keys))
>           yld(Record(rec1.fields++rec2.fields,rec1.schema++rec2.schema)) }}
> }
> trait Filter extends Operator {
>   val pred: Predicate
>   val op: Operator
>   def execOp(yld: Record => Unit) = op.execOp {rec => if (pred.eval(rec)) yld(rec)}
> }

|Join| matches a record against another and combines the two records if their common fields share the same values.
|Filter| keeps a record only when it meets a certain predicate.
There are also other operators, such as |Project|, which rearranges the fields of a record.
Besides these relational algebra operators, we define two utility operators, |Print| and |Scan|,
for dealing with inputs and outputs. |Print| prints out the fields of a record and is used in the definition of |exec| for
displaying the execution result at last. |Scan| processes a CSV file and produces a record per line.
The implementation of |Scan| is shown next:

> trait Scan extends Operator {
>   val file: String
>   def execOp(yld: Record => Unit) = processCSV(file)(yld)
> }

\subsection{Syntax}
It would be cumbersome to directly write such a relational algebra operator to query data files. That is why we need SQL as a surface language for queries.
In \cite{rompf15} implementation, SQL queries are encoded using strings, and a parser will parse a query string into an operator.
We employ well-established OO and Scala techniques to simulate the syntax of SQL queries in our shallow EDSL implementation.
Specifically, we use the \emph{Pimp my Library} pattern~\cite{odersky06pimp} in implementing smart constructors for primitives to lift field names and literals implicitly.
For the syntax of combinators such as |Filter| and |Project|, we adopt fluent interface style~\cite{fowler2005fluent}.
Fluent interface style allows us to write something like ``|q0.WHERE(...).SELECT(...)|''.
Scala's infix notation further allows us to write this query as
``|q0 WHERE ... SELECT ...|''.
Other famous embedded SQL implementations in OOP such as LINQ~\cite{meijer2006linq} also adopt similar techniques in designing their syntax.
We implement the syntax in a pluggable way, in the sense that the semantics is decoupled from the syntax (the |Operator| hierarchy).
Details of the syntax implementation are beyond the scope of this pearl.
The interested reader can view the code in our online implementation.

With the syntax defined, we are able to write SQL queries in a concise way, as illustrated by |q0|, |q1| and |q2|.
Beneath the surface syntax, a relational algebra operator object is constructed.
For example, we will get the following operator structure for |q1|:

> Project(  Schema("room", "title"),
>           Filter(  Eq(Field("time"),Value("09:00 AM")),
>                    Scan("talks.csv")))

To actually run a query, we call the |exec| method.
For example, the execution result of |q1| is:

< scala > q1.exec
< New York Central,Erlang 101 - Actor and MultiCore Programming
< ...

\noindent where the room and title of the first item from |talks.csv| is printed.

\subsection{Extensions}
More benefits of our approach emerge when the DSL evolves.
Rompf and Amin extend the SQL processor in various ways to achieve better expressiveness, performance, and flexibility.
% The extensions include a new operator |Group| for aggregations, an efficient implementation of |Join| and a more flexible |Scan| that can deal with more forms of files.
However, due to the limited extensibility in their implementation,
extensions are actually done through modifying existing code.
In contrast, our implementation allows extensions to be introduced modularly.

The implementation presented so far can only process data files of format csv (comma-separated values).
The first extension is to let it support DSV (delimiter-separated values) files
with an optional header schema describing the names of fields.

We first extend the |Operator| interface with a new interpretation |resultSchema| for collecting the schema to be projected:
\begin{spec}
trait Operator2 extends Operator {
  override def exec = new Print2{val op=Operator2.this}.execOp { _ => }
  def resultSchema: Schema
}
\end{spec}
Concrete operators, including |Print|, need to implement this new interface through complementing |resultSchema|.
Accordingly, |exec| is overridden as there is a new version of |Print|.

Then, we can extend |Scan| with the ability to deal with DSV files:
\begin{spec}
trait Scan2 extends Scan with Operator2 {
  val delim: Char
  val schema: Option[Schema]
  def resultSchema = schema.getOrElse(loadSchema(file,delim))
  override def execOp(yld: Record => Unit) = processDSV(file,resultSchema,delim,schema.isDefined)(yld)
}
\end{spec}
|Scan| has two extra fields, |delim| and |schema|, for storing the delimiter and the optional header schema.
These fields are used in implementing |resultSchema| and overriding |execOp|.
Here, yet another advantage of our approach - \emph{field extensions} - has been illustrated.
The extended fields would not affect existing interpretations that do not use these extended fields.
This would not be possible in an approach using algebraic datatypes and pattern matching.
All interpretations have to be modified anyway, as the pattern has been changed.

The reader may notice that the interpretation |execOp| becomes very much like the interpretation |tlayout| discussed in Section~\ref{sec:ctxsensitive}.
Like |tlayout|, |execOp| is both context-sensitive (taking a |yld|) and dependent (depending on |resultSchema|).

Other similar extensions are also possible. For example to boost the
performance of |Join| by replacing naive loops with an efficient
implementation based on hash maps.  Similar to |Scan|, this is done
through overriding |execOp|.

\paragraph{New Language Constructs}
A second extension is to support more SQL clauses in the implementation.
A new operator |Group| is defined for partitioning records and summing up specified fields from the composed operator.
It simulates |group by ... sum ^^ ...| clauses in SQL.
We add |Group| through defining a new trait that implements |Operator2|:

\begin{spec}
trait Group extends Operator2 {
  val keys, agg: Schema
  val op: Operator2
  def resultSchema = keys ++ agg
  def execOp(yld: Record => Unit) { ... }
}
\end{spec}

\indent The implementation still has plenty of room for extensions - only a subset of SQL is supported currently.
As our shallow OO embedding illustrates, both new relational algebra operators and new interpretations can be modularly added.
