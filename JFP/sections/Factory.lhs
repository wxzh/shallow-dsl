%include lhs2TeX.fmt
%include polycode.fmt
%include def.fmt

%format (="\!("
%format [="\!["
%format Factory1
%format Factory4
%format ExtendedFactory4
%format Circuit4

\section{Modular Interpretation-independent Terms}
\weixin{cite polymorphic embedding of DSLs / Object Algebras?}
This section illustrates how to write modular DSL terms without commiting to a particular implementation.
The idea is to combine our approach with the {\sc Abstract Factory} pattern.

\paragraph{Abstract Factories} Here is an abstract factory for \dsl:
\begin{code}
trait Factory[Circuit] {
  def identity(x: Int): Circuit
  def fan(x: Int): Circuit
  def above(x: Circuit, y: Circuit): Circuit
  def beside(x: Circuit, y: Circuit): Circuit
  def stretch(x: Circuit, xs: Int*): Circuit
}
\end{code}
which exposes factory methods for each supported circuit construct.

\paragraph{Abstract Terms} By using an abstract factory instance, we can build modular terms that are independent of any implementation.
For example, the circuit shown in Fig.~\ref{fig:circuit} can be constructed as follows:

\weixin{Cannot print underscore in code}
\def\commentbegin{\{\ }
\def\commentend{\}}
\begin{spec}
def c[Circuit](f: Factory[Circuit]) =
  f.above (  f.beside(f.fan(2),f.fan(2)),
             f.above (  f.stretch(f.fan(2),2,2),
                        f.beside(f.beside(f.identity(1),f.fan(2)),f.identity(1))))
\end{spec}
The definition can be even fancier without prefixing ``|f.|'' everywhere by importing |f|.

\paragraph{Concrete Factories} To actually build a term, concrete factories are needed, which are implementations of the factory interface.
Here is a concrete factory that produces |Circuit1|:

> trait Factory1 extends Factory[Circuit1] { ... }

where the omitted code is identical to the smart constructors presented in Section~\ref{subsec:shallow}. Similarly, we can define more concrete factories for other circuit implementations by instantiating |Circuit| accordingly:

> trait Factory4 extends Factory[Circuit4] { ... }

\paragraph{Concrete Terms} By supplying concrete factories to abstract terms like |c|, we obtain concrete terms.
%instances to |c|, we are able to construct different concrete terms, which can be further interpreted differently:

< scala> new Term with Factory1{}.c.width
< 4
< scala> new Term with Factory4{}.c.tlayout { x => x }
< List(List((0,1), (2,3)), List((1,3)), List((1,2)))

\paragraph{Extensions} Whenever new language constructs are introduced to the DSL, the abstract factory needs be extended correspondinly:

\begin{code}
trait ExtendedFactory extends Factory {
  def rstretch(x: Circuit, xs: Int*): Circuit
}
\end{code}
The extended abstract factory contains a new factory method that produces right stretches.

\begin{code}
trait ExtendedFactory4 extends Factory4 with ExtendedFactory {
  def rstretch(x: Circuit4, xs: Int*) = new RStretch {val c=x; val ns=xs.toList}
}
\end{code}

A |rstretch| circuit can be constructed using an extended abstract factory:

> trait ExtendedTerm extends Term with ExtendedFactory {
>   def c = rstretch(c,2,2,2,2)
> }

where the circuit constructed with a initial factory, |c|, is reused.

%Indeed, we can directly encode interpretations as concrete visitors by
%instantiating the type parameter |C| to the semantic domain and implementing each case accordingly~\cite{poly,oa}.
