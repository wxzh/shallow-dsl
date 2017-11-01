%include lhs2TeX.fmt
%include polycode.fmt
%include def.fmt

%format (="\!("
%format [="\!["
%format Factory1
%format Factory4
%format ExtendedFactory4
%format Circuit4

\section{Modular Terms}
\weixin{cite polymorphic embedding of DSLs / Object Algebras?}
This section illustrates how to write modular DSL terms without commiting to a particular implementation.
The idea is to combine our approach with the {\sc Abstract Factory} design pattern.

\paragraph{Abstract Factories} Here is an abstract factory for constructing circuits:
\begin{code}
trait Factory[Circuit] {
  def identity(x: Int): Circuit
  def fan(x: Int): Circuit
  def above(x: Circuit, y: Circuit): Circuit
  def beside(x: Circuit, y: Circuit): Circuit
  def stretch(x: Circuit, xs: Int*): Circuit
}
\end{code}
|Factory| is a generic interface, which exposes factory methods for each circuit construct supported by \dsl.

\paragraph{Abstract Terms} Modular terms can be built via an abstract factory, e.g. the circuit shown in Fig.~\ref{fig:circuit}:

\begin{spec}
def c[Circuit](f: Factory[Circuit]) =
  f.above (  f.beside(f.fan(2),f.fan(2)),
             f.above (  f.stretch(f.fan(2),2,2),
                        f.beside(f.beside(f.identity(1),f.fan(2)),f.identity(1))))
\end{spec}
|c| is a generic method that takes an |Factory| instance and constructs a circuit through that instance. The definition of |c| can be even simpler with Scala. By importing |f|, we can avoid prefixing ``|f.|'' everywhere.

\paragraph{Concrete Factories} We need concrete factories that implement |Factory| to actually invoke |c|. Here is a concrete factory that produces |Circuit1|:

> trait Factory1 extends Factory[Circuit1] { ... }

where the omitted code is identical to the smart constructors presented in Section~\ref{subsec:shallow}. Concrete factories for other circuit implementations can be defined in a similar way by instantiating the type parameter |Circuit| accordingly:

> trait Factory4 extends Factory[Circuit4] { ... }

\paragraph{Concrete Terms} Supplying concrete factories to abstract terms, we obtain concrete terms that can be interpreted differently:

\begin{code}
c(new Factory1{}).width // 4
c(new Factory4{}).tlayout { x => x } // List(List((0,1), (2,3)), List((1,3)), List((1,2)))
\end{code}

\paragraph{Modular Extensions} Both factories and terms can be \emph{modularly} reused when the DSL is extended with new language constructs. To support right stretch for \dsl, we first extend the abstract factory:

\begin{code}
trait ExtendedFactory extends Factory {
  def rstretch(x: Circuit, xs: Int*): Circuit
}
\end{code}
We can also build extended concrete factories upon existing concrete factories:

\begin{code}
trait ExtendedFactory4 extends Factory4 with ExtendedFactory {
  def rstretch(x: Circuit4, xs: Int*) = new RStretch {val c=x; val ns=xs.toList}
}
\end{code}
Moreover, previously defined terms can be reused in constructing extended terms:

> def c2[Circuit](f: ExtendedFactory) = f.rstretch(c(f),2,2,2,2)
