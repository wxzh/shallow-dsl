%include lhs2TeX.fmt
%include polycode.fmt
%include def.fmt
\section{Shallow Object-Oriented Programming}\label{sec:oo}

\weixin{TODO: Cite circuit figure and SQL examples more properly}
This section shows that an OOP approach and a shallow embedding using
procedural abstraction are closely related.  We use the same
DSL presented by Gibbons and Wu~\shortcite{gibbons2014folding} as
a running example.  We first give the original shallow embedded
implementation in Haskell, and rewrite it towards an ``OOP style''.
Then translating the program into an OOP language like Scala becomes straightforward.
% We choose Scala to present the OOP code throughout this pearl.
% because of its relatively elegant syntax and its support for multiple-inheritance
% via traits.  None of Scala's advanced type system features is used.
%However the code can be adapted to any OOP language that supports subtyping,
%mulinheritance and type-refinements.

\subsection{\dsl: A DSL for Parallel Prefix Circuits}
%format @ = "\bullet"
%format x1
%format x2
%format x_n
\dsl~\cite{hinze2004algebra} is a DSL for describing parallel prefix circuits.
Given an associative binary operator |@|, the prefix sum of a non-empty sequence |x1,x2,...,x_n| is |x1,x1@x2,...,x1@x2@ ... @x_n|. Such computation can be performed in parallel for a parallel prefix circuit.
Parallel prefix circuits have many applications, including binary addition and sorting algorithms.
The grammar of \dsl is given below:
\setlength{\grammarindent}{5em} % increase separation between LHS/RHS

\begin{grammar}
 <circuit> ::= `id' <positive-number>
 \alt `fan' <positive-number>
 \alt `beside' <circuit> <circuit>
 \alt `above' <circuit> <circuit>
 \alt `stretch' <positive-numbers> <circuit>
\end{grammar}


\noindent \dsl has five constructs: two primitives
(|id| and |fan|) and three combinators (|beside|, |above| and |stretch|).
Their meanings are: |id n| contains |n| parallel wires;
|fan n| has |n| parallel wires with its first wire connected to
all the remaining wires from top to bottom; |beside c1 c2| joins two circuits
|c1| and |c2| horizontally; |above c1 c2| combines two circuits of the same width vertically;
|stretch ns c| inserts wires into the circuit |c| by summing up |ns|.
Fig.~\ref{fig:circuit} visualizes a circuit constructed using all these five constructs.
The structure of this circuit is explained as follows.
The whole circuit is composed by three sub-circuits, vertically:
the top sub-circuit is a two 2-|fan|s put side by side;
the middle sub-circuit is a 2-|fan| stretched by inserting a wire on the left-hand side of its first and second wire;
the bottom sub-circuit is a 2-|fan| in the middle of two 1-|id|s.

\begin{figure}
  \center
  \includegraphics[width=.25\textwidth]{circuit}
  \caption{The Brent-Kung parallel prefix circuit of width 4}
  \label{fig:circuit}
\end{figure}

\subsection{Shallow Embeddings and OOP}\label{subsec:shallow}
Shallow embeddings define a language directly through encoding its semantics
using procedural abstraction. In the case of \dsl,
a shallow embedded implementation (in Haskell) conforms to the following
types:

\begin{code}
type Circuit  =  ...
id            ::  Int -> Circuit
fan           ::  Int -> Circuit
beside        ::  Circuit -> Circuit -> Circuit
above         ::  Circuit -> Circuit -> Circuit
stretch       ::  [Int] -> Circuit -> Circuit
\end{code}

\noindent The type |Circuit|, representing the semantic domain, is to be filled with a concrete type according to the semantics. Each construct is declared as a function that produces a |Circuit|.
Suppose that the semantics of \dsl calculates the width of a
circuit. The definitions are:

> type Circuit   =  Int
> id n     =  n
> fan n          =  n
> beside c1 c2   =  c1 + c2
> above c1 c2    =  c1
> stretch ns c   =  sum ns

\indent Now we are able to construct the circuit in Fig.~\ref{fig:circuit} using these definitions:

>  (fan 2 `beside` fan 2) `above` stretch [2,2] (fan 2) `above` (id 1 `beside` fan 2 `beside` id 1)

\noindent For this simple interpretation, the Haskell domain is simply |Int|.
This means that we will get the width right after the construction of a circuit (4 for this case)
Note that the |Int| domain for |width| is a degenerate case of procedural abstraction: |Int| can be viewed
as a no argument function. In Haskell, due to laziness, |Int|
is a good representation. In a call-by-value language,
a no-argument function |() -> Int| is more
appropriate to deal correctly with potential control-flow
language constructs.
% Interpretations of a more complex domain will be shown in Section~\ref{sec:interp}.
% More realistic shallow DSLs, such as parser combinators~\cite{leijen01parsec}, tend to have more complex functional domains.

\paragraph{Towards OOP}
A simple, \emph{semantics preserving} rewriting of |width| is given
below, where a record with one field captures the domain and is declared as a |newtype|:


%format Circuit1
%format id1
%format fan1
%format beside1
%format above1
%format stretch1
%format width1

\begin{code}
newtype Circuit1   =  Circuit1 {width1  ::  Int}
id1 n        =  Circuit1 {width1  =   n}
fan1 n             =  Circuit1 {width1  =   n}
beside1 c1 c2      =  Circuit1 {width1  =   width1 c1 + width1 c2}
above1 c1 c2       =  Circuit1 {width1  =   width1 c1}
stretch1 ns c      =  Circuit1 {width1  =   sum ns}
\end{code}

The implementation is still shallow because |newtype| does not add any operational
behavior to the program, and hence the two programs are effectively the
same.  However, having fields makes the program look more like an
OO program.

\paragraph{Porting to Scala}
Indeed, we can easily translate the program from Haskell to Scala:

%format (="\!("
%format [="\!["

\begin{minipage}{.5\textwidth}
\begin{spec}
trait Circuit1 {
  def width: Int
}
trait Id1 extends Circuit1 {
  val n: Int
  def width = n
}
trait Fan1 extends Circuit1 {
  val n: Int
  def width = n
}
\end{spec}
\end{minipage}
%
\begin{minipage}{.5\textwidth}
\begin{spec}
trait Beside1 extends Circuit1 {
  val c1, c2: Circuit1
  def width = c1.width + c2.width
}
trait Above1 extends Circuit1 {
  val c1, c2: Circuit1
  def width = c1.width
}
trait Stretch1 extends Circuit1 {
  val ns: List[Int]; val c: Circuit1
  def width = ns.sum
}
\end{spec}
\end{minipage}
%  \end{figure}
Haskell's record type maps to an object interface (modeled as a |trait| in Scala) |Circuit1|, and Haskell's field
declarations become method declarations.
Each case in the semantic function corresponds to a concrete implementation of |Circuit1|, where function parameters are captured as fields.
% a class is a procedure that returns a value satisfying an interface
% All these classes are concrete implementations of |Circuit1| with the |width| method defined.

This implementation is essentially how we would model \dsl with an OOP language in the first place. A minor difference is the use of
traits, instead of classes. For example, an equivalent class implementation of |Id1| is:

> class Id1(n: Int) extends Circuit1 { def width = n }

Although such a class definition better distinguishes itself with an object interface and simplifies field declarations, it loses some additional modularity offered by the trait version.
% discuss the meaning of different use of traits

To use this Scala implementation in a manner similar to the Haskell implementation, we define some smart constructors for creating objects:

\begin{spec}
def id(x: Int)                        =  new Id1        {val n=x}
def fan(x: Int)                       =  new Fan1       {val n=x}
def above(x: Circuit1, y: Circuit1)   =  new Above1     {val c1=x; val c2=y}
def beside(x: Circuit1, y: Circuit1)  =  new Beside1    {val c1=x; val c2=y}
def stretch(x: Circuit1, xs: Int*)    =  new Stretch1   {val ns=xs.toList; val c=x}
\end{spec}

\noindent Now we are able to construct the circuit shown in Fig.~\ref{fig:circuit} in Scala:

\begin{spec}
val c  = above(  beside(fan(2),fan(2)),
                 above(  stretch(fan(2),2,2),
                         beside(beside(id(1),fan(2)),id(1))))
\end{spec}

\noindent Finally, calling |c.width| will return 4.

As this example illustrates, shallow embeddings and straightforward OO
programming are closely related. The syntax of the Scala code is not
as concise as the Haskell version due to some extra verbosity caused by
trait declarations and smart constructors.
%It would be nice if Scala directly supported constructors for traits, but unfortunately this is not supported.
Nevertheless, the code is still quite compact
and elegant, and the Scala implementation has advantages in terms of
modularity, as we shall see next.

% Characteristics of pure OOP: "object interfaces do not use type abstraction (from known types to known types)"
