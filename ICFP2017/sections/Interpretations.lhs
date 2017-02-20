%include lhs2TeX.fmt
%include polycode.fmt
%include def.fmt
\section{Interpretations in Shallow Embeddings}

An often stated limitation of shallow embeddings is that they allow only a single
interpretation. ~\citet{gibbons2014folding} work around this problem by using tuples. However, their encoding needs to modify
the original code, and thus is non-modular. This section illustrates how various types of
interpretations can be \emph{modularly} defined using standard OOP techniques.
\begin{comment}
Although a modular solution based on \citep{swierstra2008data}
is also presented, it complicates the encoding dramatically and may prevent pratical use.
OO approach, on the contrary, provides modular yet simple solution of defining
multiple interpretations.
\end{comment}

\subsection{Multiple Interpretations}\label{subsec:multiple}
A single interpretation may not be enough for realistic DSLs.
For example, besides |width|, we may want to have an additional interpretation
that calculates the depth of a circuit in \dsl.

\paragraph{Multiple Interpretations in Haskell}
Here is ~\citet{gibbons2014folding}'s solution:

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

\noindent A tuple is used to accommodate multiple interpretations, and each interpretation is defined as a projection on the tuple.
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
Concrete cases, for instance |Above2|, implement |Circuit2| by inheriting |Above1| and complementing the definition of |depth|.
Also, fields of type |Circuit1| are refined with |Circuit2| to allow |depth| invocations.
Importantly, all definitions for |width| in Section~\ref{subsec:shallow} are reused here.

\subsection{Dependent Interpretations}
\emph{Dependent interpretations} are a generalization of multiple
interpretations. A dependent interpretation does not only depend on itself but also on other interpretations.
An instance of such interpretation is |wellSized|, which checks whether a circuit is constructed correctly.
|wellSized| is dependent because combinators such as |above| have width constraints on its circuit components.

\paragraph{Dependent Interpretations in Haskell}
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
\noindent where |width| is called in the definition of |wellSized| for |above3| and |stretch3|.

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
In the definition of |Above3|, for example, it is possible 
to, not only call |wellSized|, but also |width|. 

\subsection{Context-Sensitive Interpretations}\label{sec:ctxsensitive}
Interpretations may rely on some context.
Consider an interpretation that simplifies the representation of a circuit.
A circuit can be divided horizontally into layers.
Each layer can be represented as a sequence of pairs $(i,j)$, denoting the connection from wire $i$ to wire $j$.
For instance, circuit shown in Fig.~\ref{fig:circuit} has the following layout:

> [[(0,1), (2,3)], [(1,3)], [(1,2)]]

The combinator |stretch| and |beside| will change the layout of a circuit.
For example, if a circuit is put on the right hand side of another circuit, all the indices of the circuit will be increased by the width of that circuit.
Hence the interpretation, let us call it |tlayout|, that produces a layout is firstly dependent, relying on itself as well as |width|.
An intuitive implementation of |tlayout| would perform these changes immediately to the affected circuit.
Rather, a more efficient implementation would accumulate these changes and apply them all at once.
An accumulating parameter is used to achieve this goal, which makes |tlayout| context-sensive.

\paragraph{Context-Sensitive Interpretations in Haskell}
The following Haskell code implements (non-modular) |tlayout|:

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
                  ,\f -> lzw (++) (tlayout c1 f) (tlayout c2 (f . (width c1+))))
stretch4 ns c  =  (sum ns,\f -> tlayout c (f . pred . (vs!!)))
  where vs = scanl1 (+) ns

lzw                      ::  (a -> a -> a) -> [a] -> [a] -> [a]
lzw f [ ] ys             =  ys
lzw f xs [ ]             =  xs
lzw f (x : xs) (y : ys)  =  f x y : lzw f xs ys

tlayout =  snd
\end{code}
%}

The domain of |tlayout| is not a direct value that represents the layout (|Layout|) but a function that takes a transformation on wires and then produces a layout (|(Int->Int)->Layout|).
An anonymous function that takes as an accumulating parameter |f| is constructed for each case.
Note that |f| is accumulated in |beside4| and |stretch4| through function composition, propagated in |above4|, and finally applied to wire connections in |fan4|\footnote{The function composition order is incorrect in the original paper. |f| should be put on the left-hand side of $\circ$, as the circuit is built bottom up.}.
An auxiliary definition |lzw| (stands for ``long zip with'') zips two lists by applying the binary operator
to elements of the same index, and appending the remaining elements from
the longer list to the resulting list.
By calling |tlayout| on a circuit and supplying |id| as the initial value for the accumulating parameter, we will get the layout.

\paragraph{Context-Sensitive Interpretations in Scala}
Context-sensitive interpretations in our OO approach are unproblematic as well:

%format Identity4
%format Fan4
%format Beside4
%format Above4
%format Stretch4
%format (="\!("
%format [="\!["

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
  def tlayout(f: Int => Int) = lzw (c1.tlayout(f), c2.tlayout(f.compose(c1.width + _))) (_ ++ _)
}
trait Stretch4 extends Stretch1 with Circuit4 {
  val c: Circuit4
  def tlayout(f: Int => Int) = {
    val vs = ns.scanLeft(0)(_ + _).tail
    c.tlayout(f.compose(vs(_) - 1))
  }
}

def lzw[A](xs: List[A], ys: List[A])(f: (A, A) => A): List[A] = (xs, ys) match {
  case (Nil,_)        =>  ys
  case (_,Nil)        =>  xs
  case (x::xs,y::ys)  =>  f(x,y) :: lzw (xs,ys) (f)
}
\end{spec}
The Scala version is both modular and arguably more intuitive, since
contexts are captured as method arguments.
The implementation of |tlayout| is a direct translation from the Haskell version.
There are some minor syntax differences that are explained as follows.
In |Fan4|, a for comprehension is used for producing a list of connections.
The parameter list of annonymous functions is omitted.
Instead, we refer to these using underscores (|_|) instead.
For example, in |Beside4|, |c1.width + _| is short for |(i: Int) => c1.width + i|.
Function composition is achieved through |compose|, which has a different composition order as oppososed to |.| in Haskell.
The |lzw| is a curried function in Scala, where the binary operator |f| is moved to the end as a separater parameter list for facilitating type inference.

\bruno{I think some more explanation is needed here, specially on Scala 
code that may be unfamiliar. For example explain |tlayout| in |Fan4|. 
Do not use mix-fix syntax in |Above4| and other places: it only serves the purpose of 
confusing readers or requiring extra explanation. you do need to explain compose. 
Explain what "_" means in Scala.}

\subsection{Modular Language Constructs}\label{sec:construct}

Besides new interpretations, new language constructs may be needed when a DSL
evolves. For example, in the case of \dsl, we may want to have a |rstretch| (right
stretch) combinator which is similar to the |stretch| combinator except for the direction of stretching.

\paragraph{New Constructs in Haskell}

Shallow embeddings make the addition of |rstretch| easy by defining a new function:

< rstretch        ::  [Int] -> Circuit4 -> Circuit4
< rstretch  ns c  =  stretch4 (1 : init ns) c `beside` identity (last ns - 1)

|rstretch| happens to be a syntatic sugar that can be defined in terms of existing constructs.
For non-sugar constructs, we need to define a new function that implements all supported interpretations.

\paragraph{New Constructs in Scala}
Such simplicity of adding new constructs is retained in our OO approach.
Differently from the Haskell approach, there is a clear distinction between 
syntatic sugar and ordinary constructs in the OOP approach.

In our OOP approach, a syntatic sugar is defined as a smart constructor upon other smart constructors:

> def rstretch(ns: List[Int], c: Circuit4) = stretch (1 :: ns.init, beside(c, identity(ns.last - 1)))

% All that is needed is
On the other hand, adding an ordinary construct is done through defining a new trait that implements |Circuit4|.
If we treated |rstretch| as an ordinary construct, its definition would be:

> trait RStretch extends Stretch4 {
>   override def tlayout(f: Int => Int) = {
>     val vs = ns.scanLeft(ns.last - 1)(_ + _).init
>     c.tlayout(f.compose(vs(_)))
>   }
> }

\bruno{mixfix being used again}
Such an implementation of |RStretch| illustrates another strength of our OO approach regarding to modularity.
Note that |RStretch| does not implement |Circuit4| directly.
Instead, it inherites |Stretch4| and overrides the |tlayout| definition so as to reuse other interpretations as well as field declarations from |Stretch4|.
Inheritance and overriding enable partial reuse of a existing language construct implementation,
which is particularly useful for defining specialized constructs.
However, such partial reuse is hard to achieve in Haskell.

\subsection{Parameterized Interpretations}
\weixin{Discuss folds}

\begin{comment}
\subsection{Implicitly Parameterized Interpretations}
\weixin{Discuss type classes, tagless final, polymorphic embedding, Object Algebras?}

\subsection{Intermediate Interpretations}
\weixin{Discuss desugaring?}
\end{comment}

\subsection{Discussion}
\begin{comment}
As Gibbons and Wu notice:
\begin{quote}
\emph{
it is not difficult to provide multiple interpretations with a shallow
embedding ... But this is still a bit clumsy: it entails revising
existing code each time a new interpretation is added, and wide tuples
generally lack good language support.}  \end{quote}

\noindent In other words, Haskell's approach based on tuples is essentially non-modular.
This is precisely where OOP has advantages over the Haskell
encoding.  Instead of tuples, objects are used. Objects are
essentially records/named-tuples. Unlike Haskell tuples objects
can have subtyping relations. That is, whenever a object of a certain
type is needed, an object with more field/methods can be used instead.
\end{comment}

Gibbons and Wu claim that in shallow embeddings new language
constructs are easy to add, but new interpretations are hard.
Although it is possible to define multiple interpretations via tuples,
they have noticed that 

\begin{quote} \emph{ it is not difficult to
provide multiple interpretations with a shallow embedding ... But this
is still a bit clumsy: it entails revising existing code each time a
new interpretation is added, and wide tuples generally lack good
language support.}~\citep{gibbons2014folding} 
\end{quote} 
In other words, Haskell's approach based on tuples is essentially non-modular.
However, as our OOP approach shows, in OOP both language constructs and new
interpretations are easy to add in shallow embeddings. In other words,
the circuit DSL presented so far does not suffer from the Expression
Problem. The key point is that procedural abstraction combined with
OOP features (subtyping, inheritance and type-refinement) adds
expressiveness over traditional procedural abstraction. 
%%Instead 
%%of tuples, we can use objects. 
%%Instead of tuples, traits are used. Traits are
%%essentially records/named-tuples. Unlike Haskell tuples, traits
%%can have subtyping relations. That is, whenever a object of a certain
%%type is needed, an object with more field/methods can be used instead.


Gibbons and Wu
do discuss a number of advanced
techniques~\cite{carette2009finally,swierstra2008data} that can solve
some of the modularity problems. For example, using type classes,
\emph{finally tagless}~\cite{carette2009finally} can deal with
multiple interpretations in Section~\ref{subsec:multiple}. However,
these techniques complicates the encoding of the EDSL
significantly. Moreover, 
dependent interpretations (see Section~\ref{sec:dependent}) are still non-modular 
because an encoding via tuples is still needed. In contrast
the approach proposed here is just straightforward OOP, and dependent
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
