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

%%\weixin{Isn't staging transformation?}
\vspace{-15pt}
\section{Case Study: A Shallow EDSL for SQL Queries}
%Performance is critical for realistic DSLs. Transformation
% AST rewriting vs. staging
%hurt compositionality
%Program transformation is frequently used in optimizing DSLs, which becomes
%another important reason to prefer deep embeddings over shallow embeddings.

A common motivation for using deep embeddings is performance. Deep
embeddings enable complex transformations to be defined over the AST,
which is useful to implement optimizations that improve the
performance. An alternative way to obtain performance is to use
staging frameworks, such as Lightweight Modular Staging (LMS)~\cite{rompf2012lightweight}.
As illustrated by Rompf and Amin~\shortcite{rompf15} staging can preclude
the need for manual optimizations based on user-defined transformations
over the AST for a realistic query DSL. To further illustrate the applicability
of shallow OO embeddings, we refactored Rompf and Amin's deep, external DSL implementation
to make it more \emph{modular}, \emph{shallow} and \emph{embedded}.
The shallow DSL retains the performance of the original deep DSL.

\begin{comment}
Representing embedded programs concretely as an AST and equipped with
pattern matching, deep embeddings greatly simplify AST rewritings.
Although simple transformations can be simulated with shallow
embeddings, more complex transformations that require.  more complex
program transformations decrease the simplicity and modularity of a
shallow embedding.  Staging, as an alternative approach to performant
EDSLs, suits better for shallow embeddings.  This section presents a
shallow EDSL for SQL queries based on staging.
\end{comment}

%To further illustrate the applicability of shallow OO embeddings,
%we refactored an existing \emph{deep external} DSL implementation
%to make it more \emph{modular}, \emph{shallow} and \emph{embedded}.

\subsection{Overview}
SQL is the most well-known DSL for data queries.
Rompf and Amin~\shortcite{rompf15} present a SQL query processor implementation in Scala.
Their implementation is an \emph{external} DSL,
which first parses a SQL query into a relational algebra AST and then executes the query in terms of that AST.
%Three backends are provided: a SQL interpreter, a SQL to Scala compiler and a SQL to C compiler.
Based on the LMS framework~\cite{rompf2012lightweight},
the SQL compilers are nearly as simple as an interpreter while having performance comparable to hand-written code.
The implementation uses deep embedding techniques such as algebraic datatypes (\emph{case classes} in Scala) and pattern matching for representing and interpreting ASTs.
These techniques are a natural choice as multiple interpretations are needed for supporting different backends.
But problems arise when the implementation evolves with new language constructs.
All existing interpretations have to be modified for dealing with these new cases,
suffering from the Expression Problem.

We refactored Rompf and Amin~\shortcite{rompf15}'s implementation into a shallow EDSL for the following reasons.
Firstly, multiple interpretations are no longer a problem for our shallow OO embedding techinique.
Secondly, the original implementation contains no hand-coded transformations over AST, due to the use of staging.
Thirdly, it is common to embed SQL into a general purpose language,
for instance Circumflex ORM. %%\footnote{\url{http://circumflex.ru/projects/orm/index.html}} does this in Scala.
% while almost the same source lines of code.

To illustrate our shallow EDSL, imagine there is a data file |talks.csv| that contains a list of talks with time, title and room. We can write several sample queries on this file written with our EDSL.
A simple query that lists all items in |talks.csv| is:

> def q0     =  FROM ("talks.csv")

\noindent Another query that finds all talks at 9 am with their room and title selected is:

> def q1     =  q0 WHERE ^^ `time === "09:00 AM" SELECT (`room, `title)

Yet another relatively complex query to find all unique talks happening at the same time in the same room is:

> def q2     =  q0 SELECT (`time, `room, `title AS ^^ `title1)    JOIN
>               (q0 SELECT (`time, `room, `title AS ^^ `title2))  WHERE
>               `title1 <> `title2

Compared to an external implementation, our embedded implementation has the benefit of reusing the mechanisms provided by the host language for free.
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
The syntax of our EDSL is close to that of LINQ~\cite{meijer2006linq}, where |select| is a optional, terminating the clause of a query.
We employ well-established OO and Scala techniques to simulate the syntax of SQL queries in our shallow EDSL implementation.
Specifically, we use the \emph{Pimp my Library} pattern~\cite{odersky06pimp} for lifting field names and literals implicitly.
For the syntax of combinators such as |where| and |join|, we adopt a fluent interface style.
Fluent interfaces enable writing something like ``|FROM(...).WHERE(...).SELECT(...)|''.
Scala's infix notation further allows to omit ``|.|'' in chaining these methods.
Other famous embedded SQL implementations in OOP such as LINQ~\cite{meijer2006linq} also adopt similar techniques in designing their syntax.
The syntax is implemented in a pluggable way, in the sense that the semantics is decoupled from the syntax.
Details of the syntax implementation are beyond the scope of this pearl.
The interested reader can consult the companion code.

Beneath the surface syntax, a relational algebra operator structure is constructed.
For example, we will get the following operator structure for |q1|:

> Project(  Schema("room", "title"),
>           Filter(  Eq(Field("time"),Value("09:00 AM")),
>                    Scan("talks.csv")))

%%whose meaning will be explained next.

\subsection{A Relational Algebra Interpreter}
A SQL query can be represented by a relational algebra operator.
The basic interface of operators is modeled as follows:

> trait Operator {
>   def resultSchema: Schema
>   def execOp(yld: Record => Unit): Unit
> }

Two interpretations, |resultSchema| and |execOp|, need to be implemented for each concrete operator: the former collects a schema for projection; the latter executes actions to the records of the table.
Very much like the interpretation |tlayout| discussed in Section~\ref{sec:ctxsensitive},
|execOp| is both \emph{context-sensitive} and \emph{dependent}:
|tlayout| takes a callback |yld| and accumulates what the operator does to records into |yld| and uses |resultSchema| in displaying execution results.
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
There are also two utility operators, |Print| and |Scan|, for processing inputs and outputs, whose definitions are omitted for space reasons.

%By calling |execOp| on an operator, we execute a query
%To actually run a query, we call the  method.
%For example, the execution result of |q1| is:
%
%< scala > q1.exec
%< New York Central,Erlang 101 - Actor and MultiCore Programming
%< ...
%
%\noindent where the room and title of the first item from |talks.csv| is printed.

% TODO: Generate to different targets as new interpretations


\paragraph{From an Interpreter to a Compiler}
The query interpreter presented so far is elegant but unfortunately slow.
To achieve better performance, Rompf and Amin extend the SQL processor in various ways.
The first extension is to turn the slow query interpreter into a fast query compiler.
The idea is to generate specialized low-level code for a given query.
With the help of the LMS framework, this task becomes rather easy.
LMS provides a type constructor |Rep| for annotating computations that are to be performed in the next stage. The signature of the staged |execOp| is:

> def execOp(yld: Record => Rep[Unit]): Rep[Unit]

where |Unit| is lifted as |Rep[Unit]| for delaying the actions on records to the generated code.
By using the techinique presented in Section~\ref{sec:interp}, the staged version of |execOp| is introduced as an extension so as to reuse exisitng interpretations such as |resultSchema|.
The concrete definition of the staged |execOp| is almost identical to the corresponding unstaged implementation except for minor API differences on staged and unstaged types.
Hence the simplicity of the implementation remains. At the same time, dramatic speedups are obtained by switching from interpretation to compilation.

\paragraph{Language Extensions}
Rompf and Amin also extend the query processor with two new language constructs, hash joins and aggregates.
Differently from the original implementation, the introduction of these constructs can be done in a modular manner with our shallow OO embedding:

\begin{spec}
trait Group extends Operator {
  val keys, agg: Schema; val op: Operator
  def resultSchema = keys ++ agg
  def execOp(yld: Record => Unit) { ... }
}
trait HashJoin extends Join {
  override def execOp(yld: Record => Unit) = {
    val keys = op1.resultSchema intersect op2.resultSchema
    val hm = new HashMapBuffer(keys, op1.resultSchema)
    op1.execOp { rec1 =>
      hm(rec1(keys)) += rec1.fields }
    op2.execOp { rec2 =>
      hm(rec2(keys)) foreach { rec1 =>
        yld(Record(rec1.fields ++ rec2.fields, rec1.schema ++ rec2.schema)) }}}
}
\end{spec}

\noindent |Group| supports SQL's |group by| clause, which partitions records and sums up specified fields from the composed operator.
|HashJoin| is a replacement of |Join|, which uses an hash-based implementation instead of naive nested loops. With inheritance and method overridding, we are able to reuse the field declarations and other interpretations from |Join|.

\paragraph{Evaluation}
\begin{wraptable}{r}{.42\textwidth}
\vspace{-15pt}
\begin{tabular}{lcc}
                        & \text{Deep } & \text{ Shallow}\\
\hline
SQL interpreter         & 83   & 82 \\
SQL to Scala compiler   & 179  & 191 \\
SQL to C compiler       & 245  & 259 \\
\hline
\end{tabular}
\caption{Number of SLOC for the original (Deep) and the refactored (Shallow) implementations.}
\end{wraptable}
We evaluate our refactored shallow implementation with respect to the original deep implementation.
Both implementations of the DSL (the original and our refactored version) \emph{generate the same code}: thus the performance of the two implementations is the same.
We hence compare the two implementations only in terms of the source lines of code (SLOC). To make the comparison fair, only the code for
the interpretations are compared (code related to surface syntax is excluded).
The SLOC of the two implementations are close, as seen in the table.
