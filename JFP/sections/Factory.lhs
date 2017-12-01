%include lhs2TeX.fmt
%include polycode.fmt
%include def.fmt

%format (="\!("
%format [="\!["
%format Factory1
%format Factory4
%format ExtendedFactory4
%format Circuit4

\section{Modular terms}\label{sec:modterms}

One potential criticism to the approach presented so far is that while
the interpretations are modular, building terms is not. 
Every time we develop new interpretations, a new set of companion smart
constructors has to be developed as well. Unfortunately the different smart
constructors build terms that are specific to a particular interpretation, leading 
to duplication of code whenever the same term needs to be run with different interpretations. 
Fortunately, there is an easy
solution to this problem: we overload the constructors, making them
independent of any specific interpretation.

%\weixin{cite polymorphic embedding of DSLs / Object Algebras?}
%This section illustrates how to write modular DSL terms without committing to a particular implementation.
%The idea is to combine our approach with the {\sc Abstract Factory} design pattern.

\paragraph{Abstract factories} To capture the generic interface of the constructors we use an abstract factory for circuits:
\begin{code}
trait Factory[Circuit] {
  def id(x: Int): Circuit
  def fan(x: Int): Circuit
  def above(x: Circuit, y: Circuit): Circuit
  def beside(x: Circuit, y: Circuit): Circuit
  def stretch(x: Circuit, xs: Int*): Circuit
}
\end{code}
|Factory| is a generic interface, which exposes factory methods for
each circuit construct supported by \dsl. The idea of capturing 
the interfaces of constructors is inspired by the 
Finally Tagless~\cite{carette2009finally} or Object Algebras~\cite{oliveira2012extensibility} 
approaches, which employ such a technique.

\paragraph{Abstract terms}
Modular terms can be constructed via the abstract factory. For example,
the circuit shown in Fig.~\ref{fig:circuit} is built as:

\begin{spec}
def c[Circuit](f: Factory[Circuit]) =
  f.above (  f.beside(f.fan(2),f.fan(2)),
             f.above (  f.stretch(f.fan(2),2,2),
                        f.beside(f.beside(f.id(1),f.fan(2)),f.id(1))))
\end{spec}
|c| is a generic method that takes a |Factory| instance and builds a circuit through that instance. With Scala the definition of |c| can be simpler: we can avoid prefixing ``|f.|'' everywhere by importing |f|. Nevertheless, the definition shown here is more language-independent.
\paragraph{Concrete factories} We need concrete factories that implement |Factory| to actually invoke |c|. Here is a concrete factory that produces |Circuit1|:

> trait Factory1 extends Factory[Circuit1] { ... }

where the omitted code is identical to the smart constructors presented in Section~\ref{subsec:shallow}. Concrete factories for other circuit implementations can be defined in a similar way by instantiating the type parameter |Circuit| accordingly:

> trait Factory4 extends Factory[Circuit4] { ... }

\paragraph{Concrete terms} Supplying concrete factories to abstract terms, we obtain concrete terms that can be interpreted differently:

\begin{code}
c(new Factory1{}).width              {-"\text{ // 4} "-}
c(new Factory4{}).layout { x => x }  {-"\text{ // List(List((0,1), (2,3)), List((1,3)), List((1,2)))} "-}
\end{code}

\paragraph{Modular extensions} Both factories and terms can be \emph{modularly} reused when the DSL is extended with new language constructs. To support right stretch for \dsl, we first extend the abstract factory with new factory methods:

\begin{code}
trait ExtendedFactory[Circuit] extends Factory[Circuit] {
  def rstretch(x: Circuit, xs: Int*): Circuit
}
\end{code}
We can also build extended concrete factories upon existing concrete factories:

\begin{code}
trait ExtendedFactory4 extends ExtendedFactory[Circuit4] with Factory4 {
  def rstretch(x: Circuit4, xs: Int*) = new RStretch {val c=x; val ns=xs.toList}
}
\end{code}
Furthermore, previously defined terms can be reused in constructing extended terms:

> def c2[Circuit](f: ExtendedFactory[Circuit]) = f.rstretch(c(f),2,2,2,2)
