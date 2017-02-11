%include lhs2TeX.fmt
%include def.fmt
\section{Interpretations in Shallow Embeddings}

An often stated limitation of shallow embeddings is that they allow only a single
interpretation. Gibbons and Wu~\citet{gibbons2014folding} work around this problem by using tuples. However, their encoding needs to modify
the original code, and thus is non-modular. This section illustrates how various type of
interpretations can be \emph{modularly} defined in OOP.
\begin{comment}
Although a modular solution based on \citep{swierstra2008data}
is also presented, it complicates the encoding dramatically and may prevent pratical use.
OO approach, on the contrary, provides modular yet simple solution of defining
multiple interpretations. 
\end{comment}

\subsection{Multiple Interpretations}\label{subsec:multiple}

\paragraph{Multiple Interpretations in Haskell}
Suppose that we want to have an additional interpretation that calculates the depth of a circuit. Here is Gibbons and Wu's solution:
\begin{code}
type Circuit3  =  (Int,Int)
identity3 n    =  (n,0)
fan3 n         =  (n,1)
above3 c1 c2   =  (width c1,depth c1 + depth c2)
beside3 c1 c2  =  (width c1 + width c2, depth c1 `max` depth c2)
stretch3 ns c  =  (sum ns,depth c)

width  =  fst
depth  =  snd
\end{code}

\noindent where a tuple is used to accommodate multiple interpretations.
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
\begin{code}
type Circuit  =  (Int,Bool)
identity n    =  (n,True)
fan n         =  (n,True)
above c1 c2   =  (width c1,wellSized c1 && wellSized c2 && width c1==width c2)
beside c1 c2  =  (width c1 + width c2,wellSized c1 && wellSized c2)
stretch ns c  =  (sum ns,wellSized c && length ns==width c)

wellSized  =  snd
\end{code}

\paragraph{Dependent Interpretations in Scala}
Fortunately, an OO approach does not have such restriction:
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

\subsection{Context-Sensitive Interpretations}
Interpretations may rely on some mutable contexts.
Consider an interpretation that simplifies the representation of a circuit.
A circuit can be divided horizontally into layers.
Each layer can be represented as a sequence of pairs $(i,j)$, denoting the connection from wire $i$ to wire $j$.
For instance, circuit shown in Fig.~\ref{fig:circuit} has the following layout:

> [[(0,1), (2,3)], [(1,3)], [(1,2)]]

It has three layers: the first layer has connections from
the first wire to the second, and from the third to the fourth; the second layer has
only one connection from the second wire to the fourth one; the third layer also has a single connection from the second to the third.

\paragraph{Context-sensitive Interpretations in Haskell}
The following Haskell code models the interpretation described above:
%{
%format . = "\circ"
\begin{code}
type Layout    = [[(Int, Int)]]
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

|tlayout| is firstly a dependent interpretation, relying on itself as well as |width|.
More importantly, it is a context-sensitive interpretation.
A circuit's would be changed when the circuit is stretched or put on the right hand side of another circuit.
To effectively produce a layout, these changes are lazily applied to the circuit and are accumulated in a parameter.
The domain |tlayout| is thereby not a direct value that represents the layout (|Layout|) but a function that takes a transformation on wires and then produces a layout (|(Int->Int)->Layout|).
Then each case of |tlayout| is defined using Haskell's lambda syntax.

\paragraph{Context-sensitive Interpretations in Scala}
Context-sensitive interpretations in our OO approach are unproblematic as well:
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

\subsection{Parameterized Interpretations}
\weixin{Discuss folds}

\subsection{Implicitly Parameterized Interpretations}
\weixin{Discuss type classes, tagless final, polymorphic embedding, Object Algebras?}

\subsection{Intermediate Interpretations}
\weixin{Discuss desugaring?}
The core language is represented using deep embedding (algebraic datatypes).
Desugaring from
% CoreCircuit
% Desugaring

\subsection{Modular Interpretations}
\weixin{Discuss adding RStretch and DTC}
As Gibbons and Wu have noticed that
\begin{quote}
(Providing mutiple interpretations via tuples) is still a bit clumsy: it entails revising existing code each time a new interpretation is added, and wide
tuples generally lack good language support.
\end{quote}
Later sections of
Two advanced techniques, i.e. tagless final~\citep{carette2009finally} and data type a la carte~\citep{swierstra2008data}, are investigated.
Dependent interpretation can not be introduced modularly using these techniques.
% This prevents a new interpretation that depends on existing interpretations from being defined modularly.

\paragraph{Modular Interpretations in Haskell}
% new constructs that can be desugared to core constructs can easily be added
%
% DTC


\paragraph{Modular Interpretations in Scala}

Figure~\ref{code:variant} shows the Scala implementation, which
\emph{modularly} defines new traits implementing |Circuit|.

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
