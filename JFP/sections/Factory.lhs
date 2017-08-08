%include lhs2TeX.fmt
%include polycode.fmt
%include def.fmt

%format (="\!("
%format [="\!["

\section{Towards Interpretation-independent Terms}
\weixin{cite polymorphic embedding of DSLs / Object Algebras?}
This section illustrates how to write DSL terms without commiting to a particular implementation.
This can be done by combining our OOP approach with the {\sc Abstract Factory} pattern.

\paragraph{Abstract Factories} Here is an abstract factory for \dsl:
\begin{code}
trait CircuitFactory[C] {
  def identity(x: Int): C
  def fan(x: Int): C
  def above(x: C, y: C): C
  def beside(x: C, y: C): C
  def stretch(x: C, xs: Int*): C
}
\end{code}
which defines a factory method for each supported circuit construct.

\paragraph{Abstract Terms} By using an abstract factory instance, we can build abstract terms that are independent of any implementation. For example, the circuit shown in Fig.~\ref{fig:circuit} can be constructed as follows:

\weixin{Cannot print underscore in code}

\begin{spec}
def c[C](f: CircuitFactory[C]) =
  f.above (  f.beside(f.fan(2),f.fan(2)),
             f.above (  f.stretch(f.fan(2),2,2),
                        f.beside(f.beside(f.identity(1),f.fan(2)),f.identity(1))))
\end{spec}
The definition can be even fancier by importing |f| to remove the need of a |f.| prefix.

\paragraph{Concrete Factories} To actually build a term, concrete factories are needed, which are implementations of the factory interface.
Here is a concrete factory that produces |Circuit1|:
\begin{code}
trait Circuit1Factory extends CircuitFactory[Circuit1] { ... }
\end{code}
where the omitted code is identical to the smart constructors presented in Section~\ref{}.
Similar concrete factories can be defined for different versions of circuit implementations, e.g.
\begin{code}
trait Circuit4Factory extends CircuitFactory[Circuit4] { ... }
\end{code}

\paragraph{Concrete Terms} By supplying different concrete factory instances to |c|, we are able to construct different concrete terms, which can be further interpreted differently:

< scala> c(new Circuit1Factory{}).width
< 4
< scala> c(new Circuit4Factory{}).tlayout { x => x }
< List(List((0,1), (2,3)), List((1,3)), List((1,2)))

\paragraph{Extensions} Whenever new language constructs are introduced to the DSL, the abstract factory needs be extended accordingly:

\begin{code}
trait ExtCircuitFactory[C] extends CircuitFactory[C] {
  def rstretch(x: C, xs: Int*): C
}
\end{code}
The extended abstract factory contains a new factory method that produces right stretches:

\begin{code}
trait ExtCircuit4Factory extends Circuit4Factory with ExtCircuitFactory[Circuit4] {
  def rstretch(x: Circuit4, xs: Int*) = new RStretch {val c=x; val ns=xs.toList}
}
\end{code}

An extended circuit can be constructed using an extended abstract factory while reusing the previously constructed term |c|:

> def c2[C](f: ExtCircuitFactory[C]) = f.rstretch(c(f),2,2,2,2)

%Indeed, we can directly encode interpretations as concrete visitors by
%instantiating the type parameter |C| to the semantic domain and implementing each case accordingly~\cite{poly,oa}.
