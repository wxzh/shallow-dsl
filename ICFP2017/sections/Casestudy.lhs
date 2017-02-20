%include lhs2TeX.fmt
%include polycode.fmt
%include def.fmt

%format rec1
%format rec2
%format title1
%format title2
%format (= "\!("

\section{Case Study}
To further illustrate the applicability of our OO approach, we refactored an existing DSL implementation to make it modular.

\subsection{Overview}
SQL is one of the most well-known DSLs for data queries.
To illustrate, suppose that there is a data file, |talks.csv|, containing a list of talks:

> tid,time,title,room
> 1,09:00 AM,Erlang 101 - Actor and MultiCore-Programming,New York Central
> 2,09:00 AM,Program Synthesis Using miniKarnren,Illinois Central
> ...

Each item in the file records the identity, time, title and room of a talk.
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

\citet{rompf15} present a SQL to C compiler in Scala.
Their implementation first parses a SQL query into a relational algebra AST,
and then executes the query based on that AST.
By using the LMS framework~\citep{rompf2012lightweight}, the SQL compiler is simple as an intuitive interpreter while having performance comparable to hand-written C code.

Algebraic datatypes (\emph{case classes} in Scala) and pattern matching are used under the hood for encoding and interpreting ASTs.
These techniques are a natural choice as they make the implementation straightforward.
However, a problem arises when the implementation evolves with new constructs introduced.
All existing interpretations have to be modified for dealing with these new constructs,
suffering from the Expression Problem.

Fortunately, we found that it is possible to rewrite the implementation as a shallow EDSL.
Firstly, it is common to embed SQL into a general purpose language, for instance Circumflex ORM\footnote{\url{http://circumflex.ru/projects/orm/index.html}} and VigSQL\footnote{\url{https://github.com/Kangmo/vigsql}} in Scala.
Secondly, the original implementation contains no transformation/optimization.
With only modest effort, we rewrote the implementation using the approach presented in this pearl.
The resulting implementation is modular without comprimising the performance.

The following subsections focuse on rewriting the core of the original implementation - the interpreter for relational algebra operations.
Similar rewriting is also applicable to the staged version derived from this interpreter as well as other AST related definitions.

%Sealed case classes forces definitions for new constructs appeared on the same file and modifications on existing interpretations to avoid pattern matching failures.
%In other words, sealed case classes suffer from the Expression Problem.

\begin{figure}
  \begin{tabular}{ll}
\begin{minipage}{.55\textwidth}
\begin{spec}
sealed abstract class Op
case class Scan(name: Table) extends Op
case class Print(o: Op) extends Op
case class Project(s1: Schema, s2: Schema, o: Op) extends Op
case class Filter(p: Predicate, o: Op) extends Op
case class Join(o1: Op, o2: Op) extends Op

def execOp(o: Op)(yld: Record=>Unit): Unit = o match {
  case Scan(name) =>
    processCSV(name)(yld)
  case Print(op) =>
    execOp(op) { r => printFields(r.fields) }
  case Project(s1, s2, o) =>
    execOp(o) { r => yld(Record(r(s1), s2)) }
  case Filter(p, o) =>
    execOp(o) { r => if (evalPred(p)(r)) yld(r) }
  case Join(o1, o2) =>
    execOp(o1) { r1 =>
      execOp(o2) { r2 =>
        val keys = r1.schema intersect r2.schema
        if (r1(keys) == r2(keys))
          yld(Record(r1.fields++r2.fields,
            r1.schema++r2.schema)) }}
}
...
\end{spec}
\end{minipage}
&
\begin{minipage}{.5\textwidth}
\begin{spec}
trait Op {
  def exec(yld: Record => Unit) }
trait Scan extends Op {
  val name: Table
  def exec(yld: Record => Unit) =
    processCSV(name)(yld) }
trait Print extends Op {
  val o: Op
  def exec(yld: Record => Unit) =
    o exec { r => printFields(r.fields) }}
trait Project extends Op {
  val s1, s2: Schema; val o: Op
  def exec(yld: Record => Unit) =
    o exec {r => yld(Record(r(s1), s2))}}
trait Filter extends Op {
  val p: Predicate; val o: Op
  def exec(yld: Record => Unit) =
    o exec {r => if (p.eval(r)) yld(r) }}
trait Join extends Op {
  val o1, o2: Op
  def exec(yld: Record => Unit) =
    o1 exec { r1 =>
      o2 exec { r2 =>
        val keys = r1.schema intersect r2.schema
        if (r1(keys) == r2(keys))
        yld(Record(r1.fields++r2.fields,
          r1.schema++r2.schema)) }}}
...
\end{spec}
\end{minipage}\\
\end{tabular}
\caption{A comparison of implementations}
\label{comparison}
\end{figure}

\subsection{Initial Implementation}

\paragraph{Their implementation}
A SQL query can be represented using an relational algebra AST.
The five case classes that extend |Op| defines the operators supported by the relational algebra, as shown on the left-hand side of Fig.~\ref{comparison}.
Concretely, |Scan| processes a csv file and produces a record line by line;
|Print| prints the fields of a record;
|Project| rearranges the fields of a record;
|Filter| filters out a record that does not meet the predicate;
|Join| matches a record from |o1| against to another from |o2|, and combines them if their common fields are of the same values.

%|Operator| captures the supported in relation algebras,
%|Predicate| captures conditions in a |where| clause of a query, and
%|Ref| captures the fields and literals used in those conditions.

\weixin{Include other auxilary definitions for completeness?}
%if False
Some auxiliary definitions are required:

> type Table   =  String
> type Schema  =  Vector[String]
> type Field   =  Vector[String]
> case class Record(fields: Fields, schema: Schema) {
>   def apply(name: String)   =  fields(schema indexOf name)
>   def apply(names: Schema)  =  names map (apply _)
> }
%endif

Feeding a SQL query to the parser, e.g. the second one discussed above,  we will get an AST like this:

> Filter(Ne(Field("title1"),Field("title2")),
>   Join(Project(Vector("time","room","title"),Vector("time","room","title1"),Scan("talks.csv")),
>     Project(Vector("time","room","title"),Vector("time","room","title2"), Scan("talks.csv"))))

Then the execution of a SQL query can be given by an interpretation on that AST, as done by |execOp|.
To give each operator a definition, |execOp| pattern matches on the given relational algebra AST |o|.
It additionally takes a parameter |yld|, which is a callback accumulating what each operator does to the records.
The implementation for each case is a straightward translation from their meanings.

\paragraph{Our Implementation} The corresponding implementation using our approach is shown on the right-hand side of Fig.~\ref{comparison}.
The case class hierarchy is replaced with a trait hierarchy.
The stand-alone method |execOp| becomes a trait method |exec| implemented by each operation.
The implementation of |exec| for each operator is almost identical to the corresponding case in |execOp|. One small difference is that we now do |o exec {...}| rather than |execOp (o) {...}| for recursive calls.

\subsection{Extensions}
More benefits of our approach emerge when the DSL evolves.
%Though the implementation presented so far is fairly simple, it is not efficient.
The achieve better performance,
\cite{rompf15} extended the SQL processor in Section 4.
Two new operators aggregations and hash joins are introduced:
the former caches the records from the composed operator;
the latter implements a more efficient join algorithm.
The introduction of hash joins further requires a new interpretation on the relational algebra operators.
The new interpretation collects an auxiliary data structure needed in implementing the hash join algorithm.
In other words, two dimensions of extension are required.

\paragraph{Their Implmenetation}
%The use of sealed case classes in the orginal implementation disallows modular extensions on both dimensions.
Due to the lack of modularity in the original implementation,
extensions were actually done through modifying existing code:

\begin{spec}
sealed abstract class Op
...
case class HashJoin(left: Op, right: Op) extends Op
case class Group(keys: Schema, agg: Schema, parent: Op) extends Op

def execOp(o: Op)(yld: Record => Unit): Unit = o match {
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
Two new case classes |HashJoin| and |Group| are added to |Op|.
The definition of |execOp| is modified for giving interpretations to the two new cases.
For the case of |HashJoin|, an interpretation |resultSchema| is invoked
for retrieving the schema from the operators it composes.
Luckily, such new interpretation can be added modularly:

\begin{spec}
def resultSchema(o: Op): Schema = o match {
  case Scan(_, schema, _, _)     =>  schema
  case Print(parent)             =>  Schema()
  case Project(schema, _, _)     =>  schema
  case Filter(pred, parent)      =>  resultSchema(parent)
  case Join(left, right)         =>  resultSchema(left) ++ resultSchema(right)
  case Group(keys, agg, parent)  =>  keys ++ agg
  case HashJoin(left, right)     =>  resultSchema(left) ++ resultSchema(right)
}
\end{spec}

The reader may have noticed that |execOp| becomes very much like the |tlayout| interpretation discussed in Section~\ref{sec:ctxsensitive}, which is both context-sensitive (taking a |yld|) and dependent (depending on |resultSchema|).

\paragraph{Our implementation}
In contrast, our approach allows modular extensions on both dimensions:
\begin{spec}
trait Op2 extends Op {
  def resultSchema: Schema }
trait Scan2 extends Scan with Op2 {
  val s: Schema; val delim: Char; val b: Boolean
  def resultSchema = schema }
trait Print2 extends Print with Op2 {
  val o: Op2
  def resultSchema = Schema()
  override def exec(yld: Record => Unit) {
    val schema = o.resultSchema
    printSchema(schema)
    o exec { r => printFields(r.fields) }}}
trait Project2 extends Project with Op2 {
  val o: Op2
  def resultSchema = s2 }
trait Filter2 extends Filter with Op2 {
  val o: Op2
  def resultSchema = o.resultSchema }
trait Join2 extends Join with Op2 {
  val o1, o2: Op2
  def resultSchema = o1.resultSchema ++ o2.resultSchema }
trait Group extends Op2 {
  val keys, agg: Schema; val o: Op2
  def resultSchema = keys ++ agg
  def exec(yld: Record => Unit) {
    val hm = new HashMapAgg(keys, agg)
    o exec { r => hm(r(keys)) += r(agg) }
    hm foreach { (k,a) => yld(Record(k ++ a, keys ++ agg)) }}}
trait HashJoin extends Join2 with Op2 {
  override def exec(yld: Record => Unit) {
    val keys = o1.resultSchema intersect o2.resultSchema
    val hm = new HashMapBuffer(keys, o1.resultSchema)
    o1 exec { r1 => hm(r1(keys)) += r1.fields }
    o2 exec { r2 =>
      hm(r2(keys)) foreach { r1 =>
          yld(Record(r1.fields ++ r2.fields, r1.schema ++ r2.schema)) }}}}
\end{spec}
The new trait |Op2| extends |Op1| with a new method |resultSchema|.
All operators now implements |Op2| by inheritating their existing implementation and complementing |resultSchema|.
Two new operators, |Group| and |HashJoin|, are added modularly.
As |HashJoin| is a specialized version of |Join|, we hence implement it following the definition of |RStretch| in Section~\ref{sec:construct}.
Moreover, adding new fields can be simply done via some more |val| declarations, as illustrated by |Scan2|.
If we would like to do this in the original implementation, the case class definition and every pattern clause referring to this case clas have to be modified.

Finally, we can define some smart constructors that play the role of a parser:
\weixin{TODO}

%if False
\subsection{Discussion}
Extensions on |Predicate|, such as adding new predicates like |LessThan|, |And| or |Or|, are left as exercises
on the companion website\footnote{\url{http://scala-lms.github.io/tutorials/query.html}}.
Such extensions can also be modularly introduced.
%endif
