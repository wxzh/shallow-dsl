\section{Shallow Object-Oriented Programming}\label{sec:oo}

This section shows that an OO approach and shallow embeddings using
procedural abstraction are closely related.  We use the same
DSL presented in Gibbons and Wu's paper~\cite{gibbons2014folding} as
the running example.  We first give the original shallow embedded
implementation in Haskell and rewrite it towards an ``OO style''.
Then translating the program into an OO language becomes straightforward.

\weixin{Explain \dsl in more depth, e.g. show some figures }

\subsection{Scans}
\emph{Scans}~\cite{hinze2004algebra} is a DSL for parallel prefix circuits.
Its BNF grammar is given below:
% BNF grammar should not contain left recursion and left factor, rewrite it
% using descent recursion
% \setlength{\grammarparsep}{20pt plus 1pt minus 1pt} % increase separation between rules
\setlength{\grammarindent}{5em} % increase separation between LHS/RHS

\begin{grammar}
 <circuit> ::= `identity' <positive-number>
 \alt `fan' <positive-number>
 \alt `beside' <circuit> <circuit>
 \alt `above' <circuit> <circuit>
 \alt `stretch' <positive-numbers> <circuit>
\end{grammar}

\noindent \dsl has 5 constructs: two primitives
\emph{identity} and \emph{fan} and three combinators \emph{beside}, \emph{above} and \emph{stretch}.
Their meanings are: \emph{id n} contains \emph{n} isolated vertical wires;
\emph{fan n} has \emph{n} vertical wires with its first wire connected to
all the remaining wires from top to bottom; $beside\ c_1\ c_2$ joins two circuits
$c_1$ and $c_2$ horizontally; $above\ c_1\ c_2$ combines two circuits of the same width vertically;
\emph{stretch ns c} inserts more wires into the circuit \emph{c} by
summing up \emph{ns}.
Simple circuits can be described with these three constructs.
%For example, Figure~\ref{} visualize the circuit \emph{beside (fan 3) (id 3)}.

\subsection{Shallow Embeddings and OOP}\label{subsec:shallow}
Shallow embeddings define a language directly through encoding its semantics
using procedural abstraction. In the case of \dsl,
an shallow embedded implementation should conform to the following
types:

\begin{spec}
type Circuit  =  ...
identity      ::  Int -> Circuit
fan           ::  Int -> Circuit
beside        ::  Circuit -> Circuit -> Circuit
above         ::  Circuit -> Circuit -> Circuit
stretch       ::  [Int] -> Circuit -> Circuit
\end{spec}

The type |Circuit|, representing the semantic domain, is to be filled in with a concrete type according to the semantics.
Suppose that the semantics of \dsl is to calculate the width of a
circuit. The definitions would be:

\begin{code}
type Circuit1  =  Int
identity n     =  n
fan n          =  n
beside c1 c2   =  c1 + c2
above c1 c2    =  c1
stretch ns c   =  sum ns

width  ::  Circuit1 -> Int
width  =  id
\end{code}

Note that, for this tiny DSL, the Haskell domain is simply
|Int|. This domain is a degenerate case of
procedural abstraction, where |Int| can be viewed
as a no argument function. In Haskell, due to laziness, |Int|
is a good representation. In a call-by-value language 
a no-argument function |() -> Int| would be more
appropriate to deal correctly with potential control-flow 
language constructs. More realistic shallow DSLs, such as parser 
combinators~\cite{leijen01parsec}, tend to have more complex functional domains.

\paragraph{Towards OOP}
A simple, \emph{semantics preserving}, rewriting of the above program is given
below, where a record with a sole field captures the domain and is declared as a |newtype|:
\begin{code}
newtype Circuit2   =  Circuit2 {width2 :: Int}
identity2 n        =  Circuit2 {width2 = n}
fan2 n             =  Circuit2 {width2 = n}
beside2 c1 c2      =  Circuit2 {width2 = width2 c1 + width2 c2}
above2 c1 c2       =  Circuit2 {width2 = width2 c1}
stretch2 ns c      =  Circuit2 {width2 = sum ns}
\end{code}
The implementation is still shallow because |newtype| does not add any operational
behaviour to the program, and hence the two programs are effectively the
same.  However, having fields makes the program look more like an 
OOP program.

\paragraph{Porting to Scala}
Indeed, we can easily translate the Haskell program into an OO
language like Scala:
\begin{spec}
package width
trait Circuit { def width: Int }
trait Fan extends Circuit {
  val n: Int
  def width = n
}
trait Identity extends Circuit {
  val n: Int
  def width = n
}
trait Beside extends Circuit {
  val c1, c2: Circuit
  def width = c1.width + c2.width
}
trait Above extends Circuit {
  val c1, c2: Circuit
  def width = c1.width
}
trait Stretch extends Circuit {
  val ns: List[Int]
  val c: Circuit
  def width = ns.sum
}
\end{spec}
The record type maps to the trait |Circuit| and field
declaration becomes a method declaration.
Each case in the semantic function corresponds to a trait and its parameters become fields of that trait.
And these traits extend |Circuit| and implement |width|.

This implementation is essentially how we would model \dsl with an OO language in the first
place, following the \interp pattern (which uses \textsc{Composite} pattern to
organize classes). A minor difference is the use of
traits, instead of classes. Using traits instead of
classes enables some additional modularity via multiple (trait-)inheritance.
In summary, shallow embeddings and straightforward OO programming are closely
related.
%It may worth mentioning that deep embedding is closely related to the \textsc{Visitor} pattern.
