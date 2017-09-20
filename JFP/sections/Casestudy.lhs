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

\section{A Shallow EDSL for SQL Queries}
Another important reason to prefer deep embeddings over shallow embeddings is the simplicity of performing program transformations.
A deep embedding using algebraic datatype and pattern matching greatly simplify program transformations.
Although simple program transformations without the need of deep patterns can be simulated with a shallow embedding, more complex program transformations decrease the simplicity and modularity of a shallow embedding.
An alternative approach to performant EDSLs is
Nevertheless, staging is , which suits better for shallow embeddings.
This section presents a shallow EDSL for SQL queries based on staging.

%To further illustrate the applicability of shallow OO embeddings,
%we refactored an existing \emph{deep external} DSL implementation
%to make it more \emph{modular}, \emph{shallow} and \emph{embedded}.

\subsection{Overview}
SQL is one of the most well-known DSLs for data queries.
Rompf and Amin~\shortcite{rompf15} present a SQL query processor implementation in Scala.
Their implementation is an \emph{external} DSL,
which first parses a SQL query into a relational algebra AST and then executes the query in terms of that AST.
Three backends are provided: a SQL interpreter, a SQL to Scala compiler and a SQL to C compiler.
Based on the LMS framework~\cite{rompf2012lightweight},
the SQL compilers are nearly as simple as an interpreter while having performance comparable to hand-written code.
The implementation uses deep embedding techniques such as algebraic datatypes (\emph{case classes} in Scala) and pattern matching for representing and interpreting ASTs.
These techniques are a natural choice as multiple interpretations are needed for supporting different backends.
But problems arise when the implementation evolves with new language constructs.
All existing interpretations have to be modified for dealing with these new cases,
suffering from the Expression Problem.

We refactored Rompf and Amin~\shortcite{rompf15}'s implementation into a shallow EDSL for the following reasons.
First, multiple interpretation is not a problem for our shallow OO embedding techinique;
Second, the original implementation contains no hand-coded transformation, which is better supported in a deep embedding;
Third, it is common to embed SQL into a general purpose language,
for instance Circumflex ORM\footnote{\url{http://circumflex.ru/projects/orm/index.html}} does this in Scala.
% while almost the same source lines of code.

To illustrate our shallow EDSL, imagine there is a data file |talks.csv| that contains a list of talks with time, title and room. Here are several sample queries on this file written with our EDSL.
A simple query that lists all items in |talks.csv| is:

> def q0     =  FROM ("talks.csv")

\noindent Another query to find all talks at 9 am with their room and title selected is:

> def q1     =  q0 WHERE ^^ `time === "09:00 AM" SELECT (`room, `title)

Yet another relatively complex query to find all unique talks happening at the same time in the same room is:

> def q2     =  q0 SELECT (`time, `room, `title AS ^^ `title1)    JOIN
>               (q0 SELECT (`time, `room, `title AS ^^ `title2))  WHERE
>               `title1 <> `title2

Compared to the original external implementation, our embedded implementation has benefits of reusing the mechanisms provided by the host language for free.
As illustrated by the sample queries above, we are able to reuse common subqueries (|q0|) in building complex queries (|q1| and |q2|).
This improves the readability and modularity of the embedded programs.

%\begin{spec}
%tid,  time,      title,                                         room
%1,    09:00 AM,  Erlang 101 - Actor and MultiCore Programming,  New York Central
%...
%16,   03:00 PM,  Welcome to the wonderful world of Sound!,      Grand Ballroom E
%\end{spec}


%format select = "\mathbf{select}"
%format as = "\mathbf{as}"
%format from = "\mathbf{from}"
%format join = "\mathbf{join}"
%format group = "\mathbf{group}"
%format by = "\mathbf{by}"
%format sum = "\mathbf{sum}"



\subsection{Embedded Syntax}
Thanks to the good support for EDSLs in Scala, we can precisely model the syntax of SQL.
The syntax of our EDSL is close to that of LINQ~\cite{meijer2006linq}, where |select| is a optional, terminating clause of a query.
We employ well-established OO and Scala techniques to simulate the syntax of SQL queries in our shallow EDSL implementation.
Specifically, we use the \emph{Pimp my Library} pattern~\cite{odersky06pimp} lifting field names and literals implicitly.
For the syntax of combinators such as |where| and |join|, we adopt fluent interface style~\cite{fowler2005fluent}.
Fluent interface style enables writing something like ``|FROM(...).WHERE(...).SELECT(...)|''.
Scala's infix notation further allows to omit ``|.|'' in method chains.
Other famous embedded SQL implementations in OOP such as LINQ~\cite{meijer2006linq} also adopt similar techniques in designing their syntax.
The syntax is implemented in a pluggable way, in the sense that the semantics is decoupled from the syntax.
Details of the syntax implementation are beyond the scope of this pearl.
The interested reader can consult the companion code.

Beneath the surface syntax, a relational algebra operator structure is constructed.
For example, we will get the following operator structure for |q1|:

> Project(  Schema("room", "title"),
>           Filter(  Eq(Field("time"),Value("09:00 AM")),
>                    Scan("talks.csv")))

whose meaning will be explained next.
% Type safety

%The following subsections give an overview of rewriting the core of the original
%implementation - the interpreter for relational algebra operations.
%Similar rewritings are also applicable to staged versions derived
%from this interpreter.

% string embedded: the syntax of string encoded DSL programs is not statically checked but parsed at runtime; hence, syntactic errors are not detected during compilation and can occur after deploying the software.
% static safety

\subsection{A Relational Algebra Interpreter}
A SQL query can be represented by a relational algebra operator.
The basic interface of operators is modeled as follows:

> trait Operator {
>   def resultSchema: Schema
>   def execOp(yld: Record => Unit): Unit
> }

Two interpretations, |resultSchema| and |execOp|, need to be implemented for each concrete operator: the former collects a schema for projection; the latter executes actions to the records of the table.
Very much like the interpretation |tlayout| discussed in Section~\ref{sec:ctxsensitive},
|execOp| is \emph{context-sensitive}, which takes a callback |yld| and accumulates what the operator does to records into |yld|.
% |exec| is just a wrapper of |execOp|, supplying a callback that does nothing as the initial value.

Here are some core concrete relational algebra operators:

> trait Project extends Operator {
>   val out, in: Schema; val op: Operator
>   def resultSchema = out
>   def execOp(yld: Record => Unit) = op.execOp {rec => yld(Record(rec(in), out))}
> }
> trait Join extends Operator {
>   val op1, op2: Operator
>   def resultSchema = op1.resultSchema ++ op2.resultSchema
>   def execOp(yld: Record => Unit) =
>     op1.execOp { rec1 =>
>       op2.execOp { rec2 =>
>         val keys = rec1.schema intersect rec2.schema
>         if (rec1(keys) == rec2(keys))
>           yld(Record(rec1.fields++rec2.fields,rec1.schema++rec2.schema)) }}
> }
> trait Filter extends Operator {
>   val pred: Predicate; val op: Operator
>   def resultSchema = op.resultSchema
>   def execOp(yld: Record => Unit) = op.execOp {rec => if (pred.eval(rec)) yld(rec)}
> }
|Project| rearranges the fields of a record;
|Join| matches a record against another and combines the two records if their common fields share the same values;
|Filter| keeps a record only when it meets a certain predicate.
There are also two utility operators, |Print| and |Scan|, for processing data files and displaying results. % Their definitions are omitted for space reasons.

%Then calling |exec| on an operator inside
%To actually run a query, we call the  method.
%For example, the execution result of |q1| is:
%
%< scala > q1.exec
%< New York Central,Erlang 101 - Actor and MultiCore Programming
%< ...
%
%\noindent where the room and title of the first item from |talks.csv| is printed.

% TODO: Generate to different targets as new interpretations


\subsection{Extensions}
Rompf and Amin extend the SQL processor in various ways to achieve better expressiveness and performance.
% The extensions include a new operator |Group| for aggregations, an efficient implementation of |Join| and a more flexible |Scan| that can deal with more forms of files.
%However, due to the limited extensibility in their implementation,
%extensions are actually done through modifying existing code.
%In contrast, our implementation allows extensions to be introduced modularly.

\paragraph{From Interpreter to Compiler}
The query interpreter is elegant but slow.
Fortunately, it is easy to convert the slow query interpreter to a fast query compiler
with the help of the LMS framework.
The idea is to generate specialized code for a given the given query.
LMS provides a type constructor |Rep| for annotating computations that are to be performed in the next stage. Here comes the signature of the staged |execOp|:

> def execOp(yld: Record => Rep[Unit]): Rep[Unit]

where |Unit| is lifted as |Rep[Unit]| for delaying the actions on records to the generated code. Similar liftings are performed elsewhere.
The new version of |execOp| is introduced as an extension so that exisitng interpretations like |resultSchema| can be reused.
The implementation of the staged |execOp| is almost identical to the previous version except for minor API differences on staged types.
As it turns out, switching frow interpretation to compilation achieves dramatic speedups without comprising the elegance of the implementation.

%\indent The implementation still has plenty of room for extensions - only a subset of SQL is supported currently.
%As our shallow OO embedding illustrates, both new relational algebra operators and new interpretations can be modularly added.

\paragraph{New Language Constructs}
To further accelarte the query compiler, Rompf and Amin extended the query processor with two new language constructs, hash joins and aggregates. Due to the use algebraic datatypes and pattern matching in their implementation, the support for these new constructs are actually done by modifying existing interpretations with cases. On the other hand, our shallow OO embedding facilitates modular additions of language constructs:

\begin{spec}
trait Group extends Operator {
  val keys, agg: Schema; val op: Operator
  def resultSchema = keys ++ agg
  def execOp(yld: Record => Unit) { ... }
}
trait HashJoin extends Join {
  override def execOp(yld: Record => Unit) = {
    val keys = op1.resultSchema intersect op2.resultSchema
    val hm = new HashMap(keys, op1.resultSchema)
    op1.execOp { rec1 =>
      hm(rec1(keys)) += rec1.fields }
    op2.execOp { rec2 =>
      hm(rec2(keys)) foreach { rec1 =>
        yld(Record(rec1.fields ++ rec2.fields, rec1.schema ++ rec2.schema)) }}}
}
\end{spec}

\noindent |Group| deals with |group by| clause in SQL, which partitions records and sums up specified fields from the composed operator.
|HashJoin| overrides the naive nested loop |execOp| with an efficient hash-based implementation while reusing field declarations and other interpretations from |Join|.

\subsection{Evaluation}
We evaluate our refactored shallow implementation with respect to the original deep implementation. As the same code is generated, the performance difference is insignificant.
We hence compare the two implementations only in terms of the source lines of code (SLOC). To make the comparison fair, only the semantics part are compared.
The SLOC of the two implementations are close, which are given in the table below:

\begin{table}[h]
\begin{tabular}{lcc}
                        & \text{Deep } & \text{ Shallow}\\
\hline
SQL interpreter         & 83   & 82 \\
SQL to Scala compiler   & 179  & 191 \\
SQL to C compiler       & 245  & 259 \\
\hline
\end{tabular}
\end{table}

