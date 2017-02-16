%include lhs2TeX.fmt
%include polycode.fmt
%include def.fmt
\section{Interpretations in Shallow Embeddings}

An often stated limitation of shallow embeddings is that they allow only a single
interpretation. ~\citet{gibbons2014folding} work around this problem by using tuples. However, their encoding needs to modify
the original code, and thus is non-modular. This section illustrates how various types of
interpretations can be \emph{modularly} defined in OOP.
\begin{comment}
Although a modular solution based on \citep{swierstra2008data}
is also presented, it complicates the encoding dramatically and may prevent pratical use.
OO approach, on the contrary, provides modular yet simple solution of defining
multiple interpretations.
\end{comment}

\subsection{Multiple Interpretations}\label{subsec:multiple}

\paragraph{Multiple Interpretations in Haskell}
Suppose that we want to have an additional interpretation that calculates the depth of a circuit. Here is ~\citet{gibbons2014folding}'s solution:

%format Circuit2
%format identity2
%format fan2
%format beside2
%format above2
%format stretch2

\begin{code}
type Circuit2  =  (Int,Int)
identity2 n    =  (n,0)
fan2 n         =  (n,1)
above2 c1 c2   =  (width c1,depth c1 + depth c2)
beside2 c1 c2  =  (width c1 + width c2, depth c1 `max` depth c2)
stretch2 ns c  =  (sum ns,depth c)

width  =  fst
depth  =  snd
\end{code}

\noindent A tuple is used to accommodate multiple interpretations and each interpretation is defined as a projection on the tuple.
However, this solution is not modular because it relies
on defining the two interpretations (|width| and
|depth|) simultaneously. It is not
possible to reuse the independently defined |width| interpretation in
Section~\ref{subsec:shallow}.
Whenever a new interpretation is needed (e.g. |depth|), the
original code has to be revised:
the arity of the tuple must be incremented and the new interpretation has to be
appended to each case.
%we add the definition of |wellSized| by modifying the original code.

\paragraph{Multiple Interpretations in Scala}
In contrast, an OO language like Scala allows new interpretations to be introduced in a modular way:

%format Identity2
%format Fan2
%format Beside2
%format Above2
%format Stretch2

\begin{spec}
trait Circuit2 extends Circuit1 {
  def depth: Int
}
trait Identity2 extends Identity1 with Circuit2 {
  def depth = 0
}
trait Fan2 extends Fan1 with Circuit2 {
  def depth = 1
}
trait Above2 extends Above1 with Circuit2 {
  val c1, c2: Circuit2
  def depth = c1.depth + c2.depth
}
trait Beside2 extends Beside1 with Circuit2 {
  val c1, c2: Circuit2
  def depth = Math.max(c1.depth, c2.depth)
}
trait Stretch2 extends Stretch1 with Circuit2 {
  val c: Circuit2
  def depth = c.depth
}
\end{spec}
The encoding relies on three OOP abstraction mechanisms:
\emph{inheritance}, \emph{subtyping} and \emph{type-refinement}.
Specifically, |Circuit2| is a subtype of
|Circuit1| and declares a new method |depth|.
Concrete cases, for instance |Above2|, implements |Circuit2| by inheriting |Above1| and complementing the definition of |depth|.
Also, fields of type |Circuit1| are refined with |Circuit2|
to avoid type mismatches in methods~\citep{eptrivially16}.

\subsection{Dependent Interpretations}
\paragraph{Dependent Interpretations in Haskell}
\emph{Dependent interpretations} are a generalization of multiple
interpretations. A dependent interpretation does not only depend on itself but also on other interpretations.
An instance of such interpretation is |wellSized|, which checks whether a circuit is constructed correctly.
|wellSized| is dependent because combinators such as |above| have width constraints on its circuit components.

In Haskell, dependent interpretations are again defined with tuples in a non-modular way:

%format Circuit3
%format identity3
%format fan3
%format beside3
%format above3
%format stretch3

\begin{code}
type Circuit3  =  (Int,Bool)
identity3 n    =  (n,True)
fan3 n         =  (n,True)
above3 c1 c2   =  (width c1,wellSized c1 && wellSized c2 && width c1==width c2)
beside3 c1 c2  =  (width c1 + width c2,wellSized c1 && wellSized c2)
stretch3 ns c  =  (sum ns,wellSized c && length ns==width c)

wellSized  =  snd
\end{code}

\paragraph{Dependent Interpretations in Scala}\label{sec:dependent}
Fortunately, an OO approach does not have such restriction:

%format Identity3
%format Fan3
%format Beside3
%format Above3
%format Stretch3

\begin{spec}
trait Circuit3 extends Circuit1 {
  def wellSized: Boolean
}
trait Identity3 extends Identity1 with Circuit3 {
  def wellSized = true
}
trait Fan3 extends Fan1 with Circuit3 {
  def wellSized = true
}
trait Above3 extends Above1 with Circuit3 {
  val c1, c2: Circuit3
  def wellSized = c1.wellSized && c2.wellSized && c1.width==c2.width
}
trait Beside3 extends Beside1 with Circuit3 {
  val c1, c2: Circuit3
  def wellSized = c1.wellSized && c2.wellSized
}
trait Stretch3 extends Stretch1 with Circuit3 {
  val c: Circuit3
  def wellSized = c.wellSized && c2.wellSized && ns.length==c.width
}
\end{spec}
Note that |width| and |wellSized| are defined separately.
Essentially, it is sufficient to define |wellSized| while
knowing only the signature of |width| in |Circuit|.

\subsection{Context-Sensitive Interpretations}\label{sec:ctxsensitive}
Interpretations may rely on some mutable contexts.
Consider an interpretation that simplifies the representation of a circuit.
A circuit can be divided horizontally into layers.
Each layer can be represented as a sequence of pairs $(i,j)$, denoting the connection from wire $i$ to wire $j$.
For instance, circuit shown in Fig.~\ref{fig:circuit} has the following layout:

> [[(0,1), (2,3)], [(1,3)], [(1,2)]]


\paragraph{Context-Sensitive Interpretations in Haskell}
The following Haskell code models the interpretation described above:

%format Circuit4
%format identity4
%format fan4
%format beside4
%format above4
%format stretch4
%{
%format . = "\circ"

\begin{code}
type Layout    =  [[(Int, Int)]]
type Circuit4  =  (Int,(Int -> Int) -> Layout)
identity4 n    =  (n,\f -> [])
fan4 n         =  (n,\f -> [[(f 0,f j) | j <- [1..n-1]]])
above4 c1 c2   =  (width c1,\f -> tlayout c1 f ++ tlayout c2 f)
beside4 c1 c2  =  (width c1 + width c2
                  ,\f -> lzw (++) (tlayout c1 f) (tlayout c2 ((width c1+) . f)))
stretch4 ns c  =  (sum ns,\f -> tlayout c (pred . (scanl1 (+) ns!!) . f))

lzw                      ::  (a -> a -> a) -> [a] -> [a] -> [a]
lzw f [ ] ys             =  ys
lzw f xs [ ]             =  xs
lzw f (x : xs) (y : ys)  =  f x y : lzw f xs ys

tlayout =  snd
\end{code}
%}

The combinator |stretch| and |beside| will change the layout of a circuit.
For example, if a circuit is put on the right hand side of another circuit, all the indices of the circuit will be increased by the width of that circuit.
Hence the interpretation that produces a layout is firstly dependent, relying on itself as well as |width|.
An intuitive implementation of would perform these changes immediately to the affected circuit.
Rather, a more efficient implementation would accumulate these changes and apply them all at once.
|tlayout| takes a accumulating parameter to achieve this goal, thereby makes it context-sensive.
The domain of |tlayout| is not a direct value that represents the layout (|Layout|) but a function that takes a transformation on wires and then produces a layout (|(Int->Int)->Layout|).
An auxiliary definition |lzw| (stands for ``long zip with'') zips two lists by applying the function
to the two elements of the same index and appending the remaining elements from
the longer list to the resulting list.
By calling |tlayout| on a circuit and supplying |id| (identity function) as the initial value for the accumulating parameter, we will get the layout.

\paragraph{Context-sensitive Interpretations in Scala}
Context-sensitive interpretations in our OO approach are unproblematic as well:

%format Identity4
%format Fan4
%format Beside4
%format Above4
%format Stretch4

\begin{spec}
type Layout = List[List[Tuple2[Int,Int]]]
trait Circuit4 extends Circuit1 {
  def tlayout(f: Int => Int): Layout
}
trait Identity4 extends Identity1 with Circuit4 {
  def tlayout(f: Int => Int) = List()
}
trait Fan4 extends Fan1 with Circuit4 {
  def tlayout(f: Int => Int) = List(for (i <- List.range(1,n)) yield (f(0),f(i)))
}
trait Above4 extends Above1 with Circuit4 {
  val c1, c2: Circuit4
  def tlayout(f: Int => Int) = c1.tlayout(f) ++ c2.tlayout(f)
}
trait Beside4 extends Beside1 with Circuit4 {
  val c1, c2: Circuit4
  def tlayout(f: Int => Int) =
    lzw (c1.tlayout(f), c2.tlayout(f.andThen(c1.width + _))) (_ ++ _)
}
trait Stretch4 extends Stretch1 with Circuit4 {
  val c: Circuit4
  def tlayout(f: Int => Int) = c.tlayout(f.andThen(partialSum(ns)(_) - 1))
}

def lzw[A](xs: List[A], ys: List[A])(f: (A, A) => A): List[A] = (xs, ys) match {
  case (Nil,_)        =>  ys
  case (_,Nil)        =>  xs
  case (x::xs,y::ys)  =>  f(x,y)::lzw(xs,ys)(f)
}
def partialSum(ns: List[Int]): List[Int] = ns.scanLeft(0)(_ + _).tail
\end{spec}
The Scala version is both modular and intuitive, where
mutable contexts are captured as method arguments.


\subsection{Modular Construct Extensions}
Not only new interpretations, new constructs may be needed when a DSL evolves. For the case of \dsl, we may want to have a |rstretch| (right stretch) combinator which is similar to the stretch combinator but inserts wires from the opposite direction.
Shallow embeddings make the addition of |rstretch| easy through defining a new function:

< rstretch :: [Int] -> Circuit -> Circuit
< rstretch = ...

Such simplicity of adding new constructs retains on our OO approach, just through defining new traits that implement |Circuit|:

< trait RStretch extends Circuit {
<   val ns: List[Int]
<   val c: Circuit
<   ...
< }

As Gibbons and Wu have noticed that
\begin{quote}
(Providing mutiple interpretations via tuples) is still a bit clumsy: it entails revising existing code each time a new interpretation is added, and wide
tuples generally lack good language support.
\end{quote}

\subsection{Parameterized Interpretations}
\weixin{Discuss folds}

\subsection{Implicitly Parameterized Interpretations}
\weixin{Discuss type classes, tagless final, polymorphic embedding, Object Algebras?}

\subsection{Intermediate Interpretations}
\weixin{Discuss desugaring?}

\subsection{Discussion}
Gibbons and Wu claim that in shallow
embeddings new language constructs are easy to add, but new
interpretations are hard. As our OOP approach shows, in OOP both
language constructs and new interpretations are easy to add in shallow
embeddings. In other words, the circuit DSL presented so far does not
suffer from the Expression Problem. The key point is that procedural
abstraction combined with OOP features (subtyping, inheritance and
type-refinement) adds expressiveness over traditional procedural
abstraction. Gibbons and Wu do discuss a number of advanced techniques~\cite{carette2009finally,swierstra2008data} that
can solve some of the modularity problems. For example, using type
classes, \emph{finally tagless}~\cite{carette2009finally} can deal with multiple interpretations in
Section~\ref{subsec:multiple}. However tuples are still needed to deal with dependent interpretations in Section~\ref{sec:dependent}.
In contrast the approach proposed here is just straightforward OOP, and dependent
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
