%include lhs2TeX.fmt
%include polycode.fmt
%include def.fmt
%include scala.fmt

%format (="\!("
%format [="\!["
%format Factory1
%format Factory4
%format ExtendedFactory4
%format Circuit4

\section{Modular terms in Scala}\label{sec:modterms}

% no generic polymorphism
One advantage of the Finally Tagless approach over our Scala approach presented so far is that terms can be constructed modularly without tying to any interpretation.
Indeed, modular terms are also possible by combining our Scala approach with Object Algebras~\cite{oliveira2012extensibility}, which employ technique similar to Finally Tagless in the context of OOP.

\paragraph{Abstract factories} To capture the generic interface of the constructors we define an abstract factory for circuits similar to the type class version shown in \autoref{sec:class}:

\begin{code}
trait Circuit[C] {
  def id(x: Int): C
  def fan(x: Int): C
  def above(x: C, y: C): C
  def beside(x: C, y: C): C
  def stretch(x: C, xs: Int*): C
}
\end{code}
|Circuit| is a generic interface, which exposes factory methods for
each circuit construct supported by \dsl.

\paragraph{Abstract terms}
Modular terms can be constructed via the abstract factory. For example,
the circuit shown in~\autoref{fig:circuit} is built as:

\begin{spec}
def circuit[C](f: Circuit[C]) =
  f.above (  f.beside(f.fan(2),f.fan(2)),
             f.above (  f.stretch(f.fan(2),2,2),
                        f.beside(f.beside(f.id(1),f.fan(2)),f.id(1))))
\end{spec}
|circuit| is a generic method that takes a |Circuit| instance and builds a circuit through that instance. With Scala the definition of |circuit| can be even simpler: we can avoid prefixing ``|f.|'' everywhere by importing |f|. Nevertheless, the definition shown here is more language-independent.
\paragraph{Concrete factories} We need concrete factories that implement |Circuit| to actually invoke |circuit|. Here is a concrete factory that produces |Circuit1|:

> trait Factory1 extends Circuit[Circuit1] { ... }

where the omitted code is identical to the smart constructors presented in Section~\ref{subsec:shallow}. Concrete factories for other circuit implementations can be defined in a similar way by instantiating the type parameter |Circuit| accordingly:

> trait Factory4 extends Factory[Circuit4] { ... }

\paragraph{Concrete terms} Supplying concrete factories to abstract terms, we obtain concrete terms that can be interpreted differently:

\begin{code}
c(new Factory1{}).width {-"\quad\quad\quad\quad\text{ // 4} "-}
c(new Factory4{}).layout { x => x } {-" \text{ // List(List((0,1), (2,3)), List((1,3)), List((1,2)))} "-}
\end{code}

\paragraph{Modular extensions} Both factories and terms can be \emph{modularly} reused when the DSL is extended with new language constructs. To support right stretch for \dsl, we first extend the abstract factory with new factory methods:

\begin{code}
trait ExtendedCircuit[C] extends Circuit[C] {
  def rstretch(x: C, xs: Int*): C
}
\end{code}
We can also build extended concrete factories upon existing concrete factories:

\begin{code}
trait ExtendedFactory4 extends ExtendedCircuit[Circuit4] with Factory4 {
  def rstretch(x: Circuit4, xs: Int*) = new RStretch {val c=x; val ns=xs.toList}
}
\end{code}
Furthermore, previously defined terms can be reused in constructing extended terms:

> def circuit2[C](f: ExtendedCircuit[C]) = f.rstretch(circuit(f),2,2,2,2)
