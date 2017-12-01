%include lhs2TeX.fmt
%include polycode.fmt
%include def.fmt
\vspace{-7pt}
\section{Interpretations in shallow embeddings}\label{sec:interp}

An often stated limitation of shallow embeddings is that multiple 
interpretations are difficult. Gibbons and Wu~\shortcite{gibbons2014folding} work around this problem by using tuples. However, their encoding needs to modify
the original code, and thus is non-modular. This section illustrates how various types of
interpretations can be \emph{modularly} defined using standard OOP mechanisms, and compares the result with Gibbons and Wu's Haskell implementations.

\subsection{Multiple interpretations}\label{subsec:multiple}
A single interpretation may not be enough for realistic DSLs.
For example, besides |width|, we may want to have another interpretation
that calculates the depth of a circuit in \dsl.

\paragraph{Multiple interpretations in Haskell}
Here is Gibbons and Wu~\shortcite{gibbons2014folding}'s solution:

%format Circuit2
%format id2
%format fan2
%format beside2
%format above2
%format stretch2

\begin{code}
type Circuit2  =  (Int,Int)
id2 n          =  (n,0)
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

\paragraph{Multiple interpretations in Scala}
In contrast, Scala allows new interpretations to be introduced in a modular way:

%format Id2
%format Fan2
%format Beside2
%format Above2
%format Stretch2

\begin{spec}
trait Circuit2 extends Circuit1 {def depth: Int}      {-"  \text{ // the extended semantic domain} "-}
trait Id2 extends Id1 with Circuit2 {def depth = 0}
trait Fan2 extends Fan1 with Circuit2 {def depth = 1}
trait Above2 extends Above1 with Circuit2 {
  override val c1, c2: Circuit2    {-"  \text{   // type-refinement that allows depth invocations } "-}
  def depth = c1.depth + c2.depth
}
trait Beside2 extends Beside1 with Circuit2 {
  override val c1, c2: Circuit2    {-"  \text{   // type-refinement that allows depth invocations } "-}
  def depth = Math.max(c1.depth, c2.depth)
}
trait Stretch2 extends Stretch1 with Circuit2 {
  override val c: Circuit2         {-"  \text{   // type-refinement that allows depth invocations } "-}
  def depth = c.depth
}
\end{spec}

The encoding relies on three OOP abstraction mechanisms:
\emph{inheritance}, \emph{subtyping}, and \emph{type-refinement}.
Specifically, |Circuit2| is a subtype of
|Circuit1| and declares a new method |depth|.
Concrete cases, for instance |Above2|, implement |Circuit2| by inheriting |Above1| and complementing the definition of |depth|.
Also, fields of type |Circuit1| are covariantly refined as type |Circuit2| to allow |depth| invocations.
Importantly, all definitions for |width| in Section~\ref{subsec:shallow} are \emph{modularly reused} here.

\subsection{Dependent interpretations}
\emph{Dependent interpretations} are a generalization of multiple
interpretations. A dependent interpretation does not only depend on itself but also on other interpretations, which goes beyond simple compositional interpretations.
An instance of dependent interpretation is |wellSized|, which checks whether a circuit is constructed correctly.
The interpretation of |wellSized| is dependent because combinators like |above| use |width| in their definitions.

\paragraph{Dependent interpretations in Haskell}
In Haskell, dependent interpretations are again defined with tuples in a non-modular way:

%format Circuit3
%format id3
%format fan3
%format beside3
%format above3
%format stretch3

\begin{code}
type Circuit3  =  (Int,Bool)
id3 n          =  (n,True)
fan3 n         =  (n,True)
above3 c1 c2   =  (width c1,wellSized c1 && wellSized c2 && width c1==width c2)
beside3 c1 c2  =  (width c1 + width c2,wellSized c1 && wellSized c2)
stretch3 ns c  =  (sum ns,wellSized c && length ns==width c)

wellSized  =  snd
\end{code}
\noindent where |width| is called in the definition of |wellSized| for |above3| and |stretch3|.

\paragraph{Dependent interpretations in Scala}\label{sec:dependent}
Once again, it is easy to model dependent interpretation with a simple OO approach:

%format Id3
%format Fan3
%format Beside3
%format Above3
%format Stretch3

\begin{spec}
trait Circuit3 extends Circuit1 { def wellSized: Boolean } {-" \text{ // the semantic domain} "-}
trait Id3 extends Id1 with Circuit3 {def wellSized = true}
trait Fan3 extends Fan1 with Circuit3 {def wellSized = true}
trait Above3 extends Above1 with Circuit3 {
  override val c1, c2: Circuit3
  def wellSized = c1.wellSized && c2.wellSized &&
    c1.width==c2.width                               {-" \text{ // width dependency} "-}
}
trait Beside3 extends Beside1 with Circuit3 {
  override val c1, c2: Circuit3
  def wellSized = c1.wellSized && c2.wellSized
}
trait Stretch3 extends Stretch1 with Circuit3 {
  override val c: Circuit3
  def wellSized = c.wellSized && ns.length==c.width  {-" \text{ // width dependency} "-}
}
\end{spec}
Note that |width| and |wellSized| are defined separately.
Essentially, it is sufficient to define |wellSized| while
knowing only the signature of |width| in the object interface.
In the definition of |Above3|, for example, it is possible 
not only to call |wellSized|, but also |width|. 

\subsection{Context-sensitive interpretations}\label{sec:ctxsensitive}
Interpretations may rely on some context.
Consider an interpretation that simplifies the representation of a circuit.
A circuit can be divided horizontally into layers.
Each layer can be represented as a sequence of pairs $(i,j)$, denoting the connection from wire $i$ to wire $j$.
For instance, the circuit shown in Fig.~\ref{fig:circuit} has the following layout:

> [[(0,1), (2,3)], [(1,3)], [(1,2)]]

The combinator |stretch| and |beside| will change the layout of a circuit.
For example, if two circuits are put side by side, all the indices of the right circuit will be increased by the width of the left circuit.
Hence the interpretation |layout| is also dependent, relying on itself as well as |width|.
An intuitive implementation of |layout| performs these changes immediately to the affected circuit.
A more efficient implementation accumulates these changes and applies them all at once.
Therefore, an accumulating parameter is used to achieve this goal, which makes |layout| context-sensitive.

\paragraph{Context-sensitive interpretations in Haskell}
The following Haskell code implements (non-modular) |layout|:

%format Circuit4
%format id4
%format fan4
%format beside4
%format above4
%format stretch4
%{
%format . = "\circ"

\begin{code}
type Circuit4  =  (Int,(Int -> Int) -> [[(Int, Int)]])
id4 n          =  (n,\f -> [])
fan4 n         =  (n,\f -> [[(f 0,f j) | j <- [1..n-1]]])
above4 c1 c2   =  (width c1,\f -> layout c1 f ++ layout c2 f)
beside4 c1 c2  =  (  width c1 + width c2,
                     \f -> lzw (++) (layout c1 f) (layout c2 (f . (width c1+))))
stretch4 ns c  =  (sum ns,\f -> layout c (f . pred . (scanl1 (+) ns !!)))

lzw                      ::  (a -> a -> a) -> [a] -> [a] -> [a]
lzw f [ ] ys             =  ys
lzw f xs [ ]             =  xs
lzw f (x : xs) (y : ys)  =  f x y : lzw f xs ys

layout =  snd
\end{code}
%}

\noindent The domain of |layout| is a function type
|(Int->Int)->[[(Int, Int)]]|, which takes a transformation on wires and
produces a layout.  An anonymous function is hence defined for each
case, where |f| is the accumulating parameter.  Note that |f| is
accumulated in |beside4| and |stretch4| through function
composition\footnote{A minor remark is that the composition order for |f| is
incorrect in Gibbons and Wu's paper.}, propagated in
|above4|, and finally applied to wire connections in |fan4|.  An
auxiliary definition |lzw| (stands for ``long zip with'') zips two
lists by applying the binary operator to elements of the same index,
and appending the remaining elements from the longer list to the
resulting list.  By calling |layout| on a circuit and supplying an identity function
as the initial value of the accumulating parameter, we will get the
layout.

\paragraph{Context-sensitive interpretations in Scala}
Context-sensitive interpretations in Scala are unproblematic as well:

%format Id4
%format Fan4
%format Beside4
%format Above4
%format Stretch4
%format (="\!("
%format [="\!["

\begin{spec}
trait Circuit4 extends Circuit1 { def layout(f: Int => Int): List[List[(Int,Int)]] }
trait Id4 extends Id1 with Circuit4 { def layout(f: Int => Int) = List() }
trait Fan4 extends Fan1 with Circuit4 {
  def layout(f: Int => Int) = List(for (i <- List.range(1,n)) yield (f(0),f(i)))
}
trait Above4 extends Above1 with Circuit4 {
  override val c1, c2: Circuit4
  def layout(f: Int => Int) = c1.layout(f) ++ c2.layout(f)
}
trait Beside4 extends Beside1 with Circuit4 {
  override val c1, c2: Circuit4
  def layout(f: Int => Int) =
    lzw (c1.layout(f), c2.layout(f.compose(c1.width + _))) (_ ++ _)
}
trait Stretch4 extends Stretch1 with Circuit4 {
  override val c: Circuit4
  def layout(f: Int => Int) = {
    val vs = ns.scanLeft(0)(_ + _).tail
    c.layout(f.compose(vs(_) - 1)) }
}

def lzw[A](xs: List[A], ys: List[A])(f: (A, A) => A): List[A] = (xs, ys) match {
  case (Nil,_)        =>  ys
  case (_,Nil)        =>  xs
  case (x::xs,y::ys)  =>  f(x,y) :: lzw (xs,ys) (f)
}
\end{spec}
The Scala version is both modular and arguably more intuitive, since
contexts are captured as method arguments.
The implementation of |layout| is a direct translation from the Haskell version.
There are some minor syntax differences that need explanations.
Firstly, in |Fan4|, a |for comprehension| is used for producing a list of connections.
Secondly, for simplicity, anonymous functions are created without a parameter list.
For example, inside |Beside4|, |c1.width + _| is a shorthand for |i => c1.width + i|, where the placeholder |_| plays the role of the named parameter |i|.
Thirdly, function composition is achieved through the |compose| method defined on function values, which has a reverse composition order as opposed to $\circ$ in Haskell.
Fourthly, |lzw| is implemented as a |curried function|, where the binary operator |f| is moved to the end as a separate parameter list for facilitating type inference.

\subsection{Modular language constructs}\label{sec:construct}

Besides new interpretations, new language constructs may be needed when a DSL
evolves. For example, in the case of \dsl, we may want a |rstretch| (right
stretch) combinator which is similar to the |stretch| combinator but stretches a circuit  oppositely.

\paragraph{New constructs in Haskell}

Shallow embeddings make the addition of |rstretch| easy by defining a new function:

%{
%format ( = "\;("

> rstretch        ::  [Int] -> Circuit4 -> Circuit4
> rstretch  ns c  =   stretch4 (1 : init ns) c `beside4` id4 (last ns - 1)

%}

\noindent |rstretch| happens to be syntactic sugar over existing constructs.
For non-sugar constructs, a new function that implements all supported interpretations is needed.

\paragraph{New constructs in Scala}
Such simplicity of adding new constructs is retained in Scala.
Differently from the Haskell approach, there is a clear distinction between
syntactic sugar and ordinary constructs in Scala.

In Scala, syntactic sugar is defined as a smart constructor upon other smart constructors:

> def rstretch(ns: List[Int], c: Circuit4) = stretch (1 :: ns.init, beside(c, id(ns.last - 1)))

On the other hand, adding ordinary constructs is done by defining a new trait that implements |Circuit4|.
If we treated |rstretch| as an ordinary construct, its definition would be:

\begin{spec}
trait RStretch extends Stretch4 {
  override def layout(f: Int => Int) = {
    val vs = ns.scanLeft(ns.last - 1)(_ + _).init
    c.layout(f.compose(vs(_)))}
}
\end{spec}

Such an implementation of |RStretch| illustrates another strength of Scala regarding modularity.
Note that |RStretch| does not implement |Circuit4| directly.
Instead, it inherits |Stretch4| and overrides the |layout| definition so as to reuse other interpretations as well as field declarations from |Stretch4|.
Inheritance and method overriding enable partial reuse of an existing language construct implementation,
which is particularly useful for defining specialized constructs.
However, such partial reuse is hard to achieve in Haskell.

\subsection{Discussion}
Gibbons and Wu claim that in shallow embeddings new language
constructs are easy to add, but new interpretations are hard.
It is possible to define multiple interpretations via tuples,
``\emph{but this
is still a bit clumsy: it entails revising existing code each time a
new interpretation is added, and wide tuples generally lack good
language support}''~\cite{gibbons2014folding}.
In other words, Haskell's approach based on tuples is essentially non-modular.
However, as our Scala code shows, using OOP mechanisms both language constructs and
interpretations are easy to add in shallow embeddings.
Moreover, dependent interpretations are possible too, which enables 
interpretations that may depend on other modular interpretations and go beyond
simple compositionality.  
 The key point is that procedural abstraction combined with
OOP features (subtyping, inheritance, and type-refinement) adds
expressiveness over traditional procedural abstraction.

Gibbons and Wu do discuss a number of advanced
techniques~\cite{carette2009finally,swierstra2008data} that can solve
\emph{some} of the modularity problems. For example, Carette \emph{et al}.~\shortcite{carette2009finally} deal with multiple interpretations (Section~\ref{subsec:multiple}) using type classes. However, while useful (see also Section~\ref{sec:modterms}), these techniques complicate the encoding of the EDSL.
Moreover, dependent interpretations (Section~\ref{sec:dependent}) remain non-modular
because an encoding via tuples is still needed. In contrast,
the Scala version is straightforward using OOP mechanisms, it uses only simple types, and dependent
interpretations are not a problem.
