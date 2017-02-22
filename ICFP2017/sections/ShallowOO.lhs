%include lhs2TeX.fmt
%include polycode.fmt
%include def.fmt
\section{Shallow Object-Oriented Programming}\label{sec:oo}

This section shows that an OO approach and shallow embeddings using
procedural abstraction are closely related.  We use the same
DSL presented by ~\citet{gibbons2014folding} as
the running example.  We first give the original shallow embedded
implementation in Haskell, and rewrite it towards an ``OO style''.
Then translating the program into an OO language becomes straightforward.
We choose Scala to illustrate the code throughout this pearl 
because of its relatively elegant syntax and its support for multiple-inheritance
via traits. % None of Scala's advanced type system features is used.
%However the code can be adapted to any OO language that supports subtyping, 
%mulinheritance and type-refinements.

\subsection{\dsl: A DSL for Parallel Prefix Circuits}
%format * = "\bullet"
%format x1
%format x2
%format xn = "\Varid{x}_{n}"
\dsl~\citep{hinze2004algebra} is a DSL for describing parallel prefix circuits.
Given a associative binary operator |*|, the prefix sum of a non-empty sequence |x1,x2,...,xn| is |x1,x1*x2,...,x1*x2* ... *xn|. Such computation can be performed in parallel for a parallel prefix circuit.
Parallel prefix circuits have many applications, including binary addition and sorting algorithms.

The grammar of \dsl is given below:
\setlength{\grammarindent}{5em} % increase separation between LHS/RHS

\begin{grammar}
 <circuit> ::= `identity' <positive-number>
 \alt `fan' <positive-number>
 \alt `beside' <circuit> <circuit>
 \alt `above' <circuit> <circuit>
 \alt `stretch' <positive-numbers> <circuit>
\end{grammar}


\noindent \dsl has five constructs: two primitives
(|identity| and |fan|) and three combinators (|beside|, |above| and |stretch|).
Their meanings are: |identity n| contains |n| parallel wires;
|fan n| has |n| vertical wires with its first wire connected to
all the remaining wires from top to bottom; |beside c1 c2| joins two circuits
|c1| and |c2| horizontally; |above c1 c2| combines two circuits of the same width vertically;
|stretch ns c| inserts more wires into the circuit |c| by summing up |ns|.
For example, Fig.~\ref{fig:circuit} visualizes a circuit constructed using all these five constructs.
The construction of the circuit is explained as follows.
The whole circuit can be divided into three sub-circuits, vertically:
the top sub-circuit is a two 2-|fan| put side by side;
the middle sub-circuit is a 2-|fan| stretched by inserting a wire on the left hand side of its first and second wire;
the bottom sub-circuit is a 2-|fan| between two 1-|identity|.

\begin{figure}
  \center
  \includegraphics[width=.25\textwidth]{circuit}
  \caption{The Brent-Kung parallel prefix circuit of width 4}
  \label{fig:circuit}
\end{figure}

\subsection{Shallow Embeddings and OOP}\label{subsec:shallow}
Shallow embeddings define a language directly through encoding its semantics
using procedural abstraction. In the case of \dsl,
a shallowly embedded implementation (in Haskell) should conform to the following
types:

\begin{code}
type Circuit  =  ...
identity      ::  Int -> Circuit
fan           ::  Int -> Circuit
beside        ::  Circuit -> Circuit -> Circuit
above         ::  Circuit -> Circuit -> Circuit
stretch       ::  [Int] -> Circuit -> Circuit
\end{code}

\noindent The type |Circuit|, representing the semantic domain, is to be filled in with a concrete type according to the semantics.
Suppose that the semantics of \dsl is to calculate the width of a
circuit. The definitions are:

\begin{code}
type Circuit   =  Int
identity n     =  n
fan n          =  n
beside c1 c2   =  c1 + c2
above c1 c2    =  c1
stretch ns c   =  sum ns
\end{code}

\noindent Now we are able to construct the circuit in Fig.~\ref{fig:circuit} using these definitions:

> c  =  ( fan 2 `beside` fan 2) `above`
>       stretch [2,2] (fan 2) `above`
>       (identity 1 `beside` fan 2 `beside` identity 1)

Note that, for this simple interpretation, the Haskell domain is simply |Int|.
This means that we will get the width right after the construction of a circuit:

< Prelude > c
< 4

Note that the |Int| domain for |width| is a degenerate case of procedural abstraction, where |Int| can be viewed
as a no argument function. In Haskell, due to laziness, |Int|
is a good representation. In a call-by-value language,
a no-argument function |() -> Int| is more
appropriate to deal correctly with potential control-flow
language constructs. We will see an interpretation of a more complex domain in Section~\ref{sec:ctxsensitive}.
% More realistic shallow DSLs, such as parser combinators~\cite{leijen01parsec}, tend to have more complex functional domains.

\paragraph{Towards OOP}
A simple, \emph{semantics preserving}, rewriting of the |width| interpretation is given
below, where a record with a sole field captures the domain and is declared as a |newtype|:


%format Circuit1
%format identity1
%format fan1
%format beside1
%format above1
%format stretch1
%format width1

\begin{code}
newtype Circuit1   =  Circuit1 {width1  ::  Int}
identity1 n        =  Circuit1 {width1  =   n}
fan1 n             =  Circuit1 {width1  =   n}
beside1 c1 c2      =  Circuit1 {width1  =   width1 c1 + width1 c2}
above1 c1 c2       =  Circuit1 {width1  =   width1 c1}
stretch1 ns c      =  Circuit1 {width1  =   sum ns}
\end{code}

The implementation is still shallow because |newtype| does not add any operational
behaviour to the program, and hence the two programs are effectively the
same.  However, having fields makes the program look more like an
OOP program.

\paragraph{Porting to Scala}
Indeed, we can easily translate the Haskell program into a Scala program:

\begin{spec}
trait Circuit1 {
  def width: Int
}
trait Identity1 extends Circuit1 {
  val n: Int
  def width = n
}
trait Fan1 extends Circuit1 {
  val n: Int
  def width = n
}
trait Beside1 extends Circuit1 {
  val c1, c2: Circuit1
  def width = c1.width + c2.width
}
trait Above1 extends Circuit1 {
  val c1, c2: Circuit1
  def width = c1.width
}
trait Stretch1 extends Circuit1 {
  val ns: List[Int]
  val c: Circuit1
  def width = ns.sum
}
\end{spec}
Haskell's record type maps to an object interface (modelled as a |trait| in Scala) |Circuit1|, and Haskell's field
declarations become method declarations.
Each case in the semantic function corresponds to a trait, and its parameters are captured by fields of that trait.
All these traits are concrete implementations of |Circuit1| with the |width| method defined.

This implementation is essentially how we would model \dsl with an OO language in the first place, following the \interp pattern~\citep{gamma94design} (which uses \textsc{Composite} pattern to
organize classes). A minor difference is the use of
traits, instead of classes. Using traits instead of
classes enables some additional modularity via multiple (trait-)inheritance.
Therefore, shallow embeddings and straightforward OO programming are closely
related.

To use this Scala implementation in a manner similar to the Haskell implementation, we define some smart constructors:

\begin{spec}
def identity(x: Int)                     =  new Identity1  {val n=x}
def fan(x: Int)                          =  new Fan1       {val n=x}
def above(x: Circuit1, y: Circuit1)      =  new Above1     {val c1=x;   val c2=y}
def beside(x: Circuit1, y: Circuit1)     =  new Beside1    {val c1=x;   val c2=y}
def stretch(xs: List[Int], x: Circuit1)  =  new Stretch1   {val ns=xs;  val c=x}
\end{spec}

\noindent Now we are able to construct circuit shown in Fig.~\ref{fig:circuit} in Scala:

\begin{spec}
val c  = above(  beside(fan(2),fan(2)),
                 above(  stretch(List(2,2),fan(2)),
                         beside(beside(identity(1),fan(2)),identity(1))))
\end{spec}

\noindent Finally, the width of a circuit is computed by calling the |width| method.

< scala > c.width
< 4

The syntax of the Scala code is not as compact as the Haskell version.
There is some extra verbosity due to trait declarations and smart
constructors.  It would be nice if Scala directly supported
constructors for traits, but unfortunatelly this is not supported.
Nevertheless the code is still quite compact and elegant, and the
Scala implementation has advantages in terms of modularity, as we
shall see in later sections.
