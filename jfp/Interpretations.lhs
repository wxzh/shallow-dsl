\section{Interpretations in Shallow Embeddings}

An often stated limitation of shallow embeddings is that they allow only a single
interpretation. Gibbons and Wu~\cite{gibbons2014folding} work around this problem by using tuples. However, their encoding needs to modify
the original code, and thus is non-modular. This section illustrates how various type of
interpretations can be \emph{modularly} defined in OOP.
\begin{comment}
Although a modular solution based on \cite{swierstra2008data}
is also presented, it complicates the encoding dramatically and may prevent pratical use.
OO approach, on the contrary, provides modular yet simple solution of defining
multiple interpretations. 
\end{comment}

\subsection{Multiple Interpretations}\label{subsec:multiple}

\paragraph{Multiple Interpretations in Haskell}
Suppose that we want to have an additional function that checks whether a circuit is
constructed correctly. Gibbons and Wu's solution is:
\begin{code}
type Circuit3  =  (Int,Int)
identity3 n    =  (n,0)
fan3 n         =  (n,1)
above3 c1 c2   =  (width3 c1,depth c1 + depth c2)
beside3 c1 c2  =  (width3 c1 + width3 c2, depth c1 `max` depth c2)
stretch3 ns c  =  (sum ns,depth c)

width3  =  fst
depth   =  snd
\end{code}

\noindent This solution is not modular because it relies
on defining the two interpretations (|width| and
|wellSized|) simultaneously, using a tuple. It is not
possible reuse the independently defined |width| function in
Section~\ref{subsec:shallow}.
Whenever a new interpretation is needed (e.g. |wellSized|), the
original code has to be revised:
the arity of the tuple must be incremented and the new interpretation has to be
appended to each case.
%we add the definition of |wellSized| by modifying the original code.
\begin{spec}
package depth
trait Circuit extends width.Circuit {
  def depth: Int
}
trait Id extends width.Id with Circuit {
  def depth = 0
}
trait Fan extends width.Fan with Circuit {
  def depth = 1
}
trait Above extends width.Above with Circuit {
  val c1, c2: Circuit
  def depth = c1.depth + c2.depth
}
trait Beside extends width.Beside with Circuit {
  val c1, c2: Circuit
  def depth = Math.max(c1.depth, c2.depth)
}
trait Stretch extends width.Stretch with Circuit {
  val c: Circuit
  def depth = c.depth
}
\end{spec}

\paragraph{Multiple Interpretations in Scala}
In contrast, Scala allows new interpretations to be introduced in a
modular way, as shown in Figure~\ref{code:operation}.
%Instead of modifying the original code, we define |wellSized| modularly.
The encoding relies on three OOP abstraction mechanisms:
\emph{inheritance}, \emph{subtyping} and \emph{type-refinement}.
Specifically, the new |Circuit| is a subtype of
|width.Circuit| and declares a new method |depth|.
The hierarchy implements the new |Circuit| by inheriting the corresponding trait from |width| and
implementing |depth|.
Also, fields of |Beside| are refined with the new |Circuit| type
to avoid type mismatches in methods~\cite{eptrivially16}.

\subsection{Dependent Interpretations}
\emph{Dependent interpretations} are a generalization of multiple
interpretations. A dependent interpretation does not only itself but also other interpretations.
An instance of such interpretation is |wellSized| which checks whether a circuit is constructed correctly:
\begin{code}
type Circuit  =  (Int,Bool)
identity n    =  (n,True)
fan n         =  (n,True)
above c1 c2   =  (width c1,wellSized c1&&wellSized c2&&width c1==width c2)
beside c1 c2  =  (width c1 + width c2,wellSized c1 && wellSized c2)
stretch ns c  =  (sum ns,wellSized c&&length ns==width c)

width      =  fst
wellSized  =  snd
\end{code}
$above$ and $stretch$ require dependent interpretations.

In Haskell, dependent interpretations are again defined with tuples in a non-modular way:
This prevents a new interpretation that depends on existing
interpretations from being defined modularly.

\paragraph{Dependent Interpretations in Scala}
Fortunately, OO approach does not have such restriction:
\begin{spec}
package wellsized
trait Circuit extends width.Circuit {
  def wellSized: Boolean
}
trait Id extends width.Id with Circuit {
  def wellSized = n > 0
}
trait Fan extends width.Fan with Circuit {
  def wellSized = n > 0
}
trait Beside extends width.Beside with Circuit {
  val c1, c2: Circuit
  def wellSized = c1.wellSized && c2.wellSized
}
\end{spec}
Note that |width| and |wellSized| are defined separately.
Essentially, it is sufficient to define |wellSized| while
knowing only the signature of |width| in |Circuit|.

\subsection{Context-Sensitive Interpretations}
Interpretations may rely on some mutable contexts.
Consider an interpretation that simplifies the representation of a circuit.
A circuit can be divided horizontally into layers.
Each layer can be represented as a sequence of pairs $(i,j)$, denoting the connection from wire $i$ to wire $j$.
For instance, circuit
$$
|(fan 2 `beside` fan 2) `above` stretch [2,2] (fan 2)|
$$
can be represented as:
$$[[(0,1), (2,3)], [(1,3)]]$$
It has two layers: the first layer has connections from
the first wire to the second, and from the second to the third; the second layer has
only one connection from the first wire to the third one.

\paragraph{Context-sensitive Interpretations in Haskell}
The following Haskell code models the interpretation described above:
%{
%format . = "\circ"
\begin{code}
lzw                      ::  (a -> a -> a) -> [a] -> [a] -> [a]
lzw f [ ] ys             =  ys
lzw f xs [ ]             =  xs
lzw f (x : xs) (y : ys)  =  f x y : lzw f xs ys

type Layout    = [[(Int, Int)]]
type Circuit4  =  (Int,(Int -> Int) -> Layout)
id4 n          =  (n,\f -> [])
fan4 n         =  (n,\f -> [[(f 0,f j) | j <- [1..n-1]]])
above4 c1 c2   =  (width4 c1,\f -> tlayout c1 f ++ tlayout c2 f)
beside4 c1 c2  =  (width4 c1 + width c2,
                   \f -> lzw (++) (tlayout c1 f) (tlayout c2 ((width4 c1+) . f)))
stretch4 ns c  =  (sum ns,\f -> tlayout c (pred . (vs!!) . f))
  where vs = scanl1 (+) ns

width4  = fst
tlayout = snd
\end{code}
%}
|tlayout| is firstly a dependent interpretation, relying on the
previously defined |width| interpretation.
More importantly, it is a context-sensitive interpretation.
The domain |tlayout| is not a direct value but a function that takes a transformation function on wires (|Int -> Int|) and then produces a layout (|Layout|).
The transformation function is accumulated in function varies in recursive calls for accumulating
on wires and hence is context-sensitive.

\paragraph{Context-sensitive Interpretations in Scala}
Context-sensitive interpretations in our OO approach are unproblematic as well.
Mutable contexts can be captured as arguments of methods:
\begin{spec}
type Layout = List[List[Tuple2[Int,Int]]]

def lzw[A](xs: List[A], ys: List[A])(f: (A, A) => A): List[A] = (xs, ys) match {
  case (Nil,_) => ys
  case (_,Nil) => xs
  case (x::xs,y::ys) => f(x,y)::lzw(xs,ys)(f)
}
def partialSum(ns: List[Int]): List[Int] = ns.scanLeft(0)(_ + _).tail

trait Circuit extends width.Circuit {
  def tlayout(f: Int => Int): Layout
}
trait Id extends Circuit with width.Id {
  def tlayout(f: Int => Int) = List()
}
trait Fan extends Circuit with width.Fan {
  def tlayout(f: Int => Int) = List(for (i <- List.range(1,n)) yield (f(0),f(i)))
}
trait Above extends Circuit with width.Above {
  val c1, c2: Circuit
  def tlayout(f: Int => Int) = c1.tlayout(f) ++ c2.tlayout(f)
}
trait Beside extends Circuit with width.Beside {
  val c1, c2: Circuit
  def tlayout(f: Int => Int) =
    lzw (c1.tlayout(f), c2.tlayout(f.andThen(c1.width + _))) (_ ++ _)
}
trait Stretch extends Circuit with width.Stretch {
  val c: Circuit
  def tlayout(f: Int => Int) = c.tlayout(f.andThen(partialSum(ns)(_) - 1))
}
\end{spec}

\subsection{Discussion}
Gibbons and Wu claim that in shallow
embeddings new language constructs are easy to add, but new
interpretations are hard. As our OOP approach shows, in OOP both
language constructs and new interpretations are easy to add in shallow
embeddings. In other words, the circuit DSL presented so far does not
suffer from the Expression Problem. The key point is that procedural
abstraction combined with OOP features (subtyping, inheritance and
type-refinement) adds expressiveness over traditional procedural
abstraction. Gibbons and Wu do discuss a number of advanced techniques that 
can solve some of the modularity problems. For example, using type
classes, \emph{finally
  tagless}~\cite{carette2009finally} can deal with the example in
Section~\ref{subsec:multiple}. However
tuples are still needed 
to deal with dependent interpretations. In contrast the approach
proposed here is just straightforward OOP, and dependent
interpretations are not a problem.
\begin{comment}
and \emph{data types a la
  carte}~\cite{swierstra2008data} (DTC).
Finally tagless approach uses a type class to abstract over all interpretations
of the language. Concrete interpretations are given through creating a data type and
making it an instance of that type. However, it forces dependent interpretations to be defined along with what they depend on.
DTC represents language constructs separately and composes them together using
extensible sums. However, not like OO languages which come with subtyping, one
has to manually implement the subtyping machinery for variants.
\end{comment}
Gibbons and Wu also show some different variants of interpretations,
such as context-sensitive interpretations. 
These interpretations are unproblematic as well.
Implementation details can be found online.

\begin{comment}
Unlike |width| and |wellSized| which can be defined with
only the given circuit, context-dependent interpretations may need some context.
These contexts can be captured by arguments of the method. For example, a
function that collects all the connections between wires inside a circuit would have
the following signature:
\begin{lstlisting}
type Layout = List[List[Tuple2[Int,Int]]]
def tlayout(f: Int => Int): Layout
\end{lstlisting}
where the context |f| may vary in recursive
calls. Context-sensitive transformations do not pose any particular
challenge. For space reasons, we omit the implementation details here. Full details
are available online.
\end{comment}

\subsection{Parameterized Interpretations}
% Object Algebras
% fold


\subsection{Implicitly Parameterized Interpretations}
% type class
% tagless final

\subsection{Intermediate Interpretations}
Core language
The core language is represented using deep embedding (algebraic datatypes).
Desugaring from
% CoreCircuit
% Desugaring

\subsection{Modular Interpretations}
As Gibbons and Wu noticed that
\begin{quote}
(Providing mutiple interpretations via tuples) is still a bit clumsy: it entails revising existing code each time a new interpretation is added, and wide
tuples generally lack good language support.
\end{quote}

Type classes

\paragraph{Modular Interpretations in Haskell}
%right stretch combinator
% new constructs that can be desugared to core constructs can easily be added
%
% DTC


\paragraph{Modular Interpretations in Scala}

Figure~\ref{code:variant} shows the Scala implementation, which
\emph{modularly} defines new traits implementing |Circuit|.
