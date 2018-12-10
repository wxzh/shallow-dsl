%include lhs2TeX.fmt
\section{Introduction}

Since Hudak's seminal paper~\cite{hudak1998modular} on embedded
domain-specific languages (EDSLs), existing languages
have been used to directly encode DSLs. Two common approaches to EDSLs
are the so-called \emph{shallow} and \emph{deep} embeddings.
Deep embeddings emphasize a \emph{syntax}-first approach:
the abstract syntax is defined first using a data type, and
then interpretations of the abstract syntax follow. The role of
interpretations in deep embeddings is to map syntactic values into
semantic values in a semantic domain.
Shallow embeddings emphasize a \emph{semantics}-first approach, where
a semantic domain is defined first. In the shallow approach,
the operations of the EDSLs are interpreted directly into the semantic
domain. Therefore there is no data type representing uninterpreted
abstract syntax. 

The trade-offs between shallow and deep embeddings have been widely
discussed~\cite{svenningsson2012combining,yinyang}: deep embeddings
enable transformations on the abstract syntax tree (AST), and multiple
interpretations are easy to implement; shallow embeddings enforce the property of \emph{compositionality}
by construction, and are easily extended with new EDSL
operations. Such discussions lead to a generally accepted belief that it is hard to support
multiple interpretations~\cite{svenningsson2012combining} and AST transformations in shallow embeddings.
% http://composition.al/blog/2015/06/02/embedding-deep-and-shallow/
% https://alessandrovermeulen.me/2013/07/13/the-difference-between-shallow-and-deep-embedding/
% Simple Types in Type Theory: deep and shallow encodings

Compositionality is considered a sign of good language design, and
it is one of the hallmarks of denotational semantics. Compositionality means
that a denotation (or interpretation) of a language is constructed from the denotation of
its parts. Compositionality 
leads to a modular semantics, where adding new language
constructs does not require changes in the semantics of existing constructs.
Because compositionality offers a guideline for good language design,
some authors~\cite{erwig2014semantics} argue that a semantics-first
approach to EDSLs is superior to a syntax-first approach.
%%In such
%%semantics-driven approach, the idea is to first find a target domain
%%that leads to a compositional denotational semantics, and later grow
%%the syntax on top of the semantic core.
Shallow embeddings fit
well with such a semantics-driven approach.
Nevertheless, the limitations of shallow embeddings compared to
deep embeddings can deter their use.

This programming pearl shows that, given adequate language support,
having multiple modular interpretations in shallow DSLs is not
only possible, but simple. 
Therefore we aim to debunk the belief
that multiple interpretations are hard to model with shallow embeddings.
Several previous authors~\cite{gibbons2014folding,erwig2014semantics} already
observed that, by using
products and projections, multiple interpretations can be supported with a cumbersome and often non-modular encoding.
Moreover it is also known that multiple interpretations \emph{without dependencies} on other interpretations
are modularized easily using variants Church encodings~\cite{gibbons2014folding,carette2009finally,oliveira2012extensibility}. 
We show that a solution for multiple interpretations, including dependencies,
is encodable naturally
when the host language combines functional features with common OO features, such as
\emph{subtyping}, \emph{inheritance}, and \emph{type-refinement}.

At the center of this pearl is Reynolds'~\cite{reynolds75userdefined} idea of \emph{procedural abstraction}, which
enables us to directly relate shallow embeddings and OOP. With procedural abstraction, data is characterized by the operations that are performed over it.
This pearl builds on two independently observed connections to procedural abstraction:

\xymatrixcolsep{6pc}
\xymatrix{
\text{Shallow Embeddings} \ar@@{<->}[r]^-*+{\text{Gibbons and Wu~\cite{gibbons2014folding}}} & \text{Procedural Abstraction}\ar@@{<->}[r]^-*+{\text{Cook~\cite{cook09abstraction}}} & \text{OOP}
}
\vspace{5pt}
\noindent The first connection is between procedural abstraction and shallow embeddings.
As Gibbons and Wu~\cite{gibbons2014folding} state ``\emph{it was probably known to Reynolds, who contrasted
deep embeddings (‘user defined types’) and shallow (‘procedural data
structures’)}''. Gibbons and Wu noted the connection between shallow embeddings
and procedural abstractions, although they did not go into a lot of detail.
The second connection is the connection between OOP and procedural
abstraction, which was discussed in depth by Cook~\cite{cook09abstraction}.



\begin{comment}
The first goal of this pearl is to show the close relationship between
shallow embeddings and object-oriented programming (OOP).
As Cook~\cite{cook09abstraction} argued, procedural abstraction is also
the essence of OOP. Although OOP is often associated with stateful
(imperative) objects, it is possible to have functional objects that
have no mutable state. Indeed Cook~\cite{cook09abstraction} calls such
style \emph{pure OOP}, and argues that it captures the essence of OOP.
Although such pure OOP definition may be controversial for OOP
programmers, it fits very well with functional programming.  Since pure OOP
is essentially procedural abstraction, the implementation of a shallow
EDSL in OOP languages should simply correspond to a standard
object-oriented program.

The second goal of this pearl is to argue that OOP languages have
advantages for the implementation of shallow embeddings.
An often stated limitation of shallow EDSLs is that they only support
a \emph{single} interpretation. This is frequently a motivation to switch to
deep embeddings instead, since they allow for multiple
interpretations. However deep embeddings also come at a cost: adding 
language extensions becomes problematic.
We show that OOP abstractions, including
\emph{inheritance}, \emph{subtyping}, and \emph{type-refinement},
add expressive power to procedural abstraction, and 
enable multiple interpretations
to co-exist in shallow embeddings. Furthermore adding language extensions 
is still simple. The key idea is to employ a
recently proposed design pattern~\cite{eptrivially16}, which provides
a simple solution to the \emph{Expression Problem}~\cite{expPb}. Thus using just standard OOP mechanisms enables
\emph{multiple modular interpretations} to co-exist and be combined in
shallow embeddings.
\end{comment}

We make our arguments concrete using Gibbons and Wu~\cite{gibbons2014folding}'s examples,
where procedural abstraction is used in Haskell to model a simple \emph{shallow}
EDSL. We recode that EDSL in Scala using a
design pattern~\cite{eptrivially16}, which provides
a simple solution to the \emph{Expression Problem}~\cite{expPb}.
%\footnote{Available online: \url{https://github.com/wxzh/shallow-dsl}}.
From the \emph{modularity} point of view, the
resulting Scala version has advantages over the Haskell version, due
to the use of subtyping, inheritance, and type-refinement.
In particular, the Scala code
can easily express modular interpretations that may
\emph{not only depend on themselves but also depend on other modular interpretations},
leading to our motto: \emph{beyond simple compositionality}.

While Haskell does not natively support subtyping, inheritance, and type-refinement,
its powerful and expressive type system is sufficient to encode similar features.
Therefore we can port back to Haskell some of the ideas used in the Scala
solution using an improved Haskell encoding that has similar (and
sometimes even better) benefits in terms of modularity.
In essence, in the Haskell solution we encode a
form of subtyping on pairs using type classes. This is useful to
avoid explicit projections, that clutter the original Haskell solution.
Inheritance is encoded by explicitly
delegating interpretations using Haskell superclasses.
Finally, type refinement is simulated using the subtyping typeclass
to introduce subtyping constraints.

While the techniques are still cumbersome for transformations, yielding
efficient shallow EDSLs is still possible via staging~\cite{rompf2012lightweight,carette2009finally}. By removing
the limitation of multiple interpretations, we enlarge the
applicability of shallow embeddings. A concrete example is our case
study, which refactors an external SQL DSL that employs deep embedding
techniques~\cite{rompf15} into a shallow EDSL. The refactored
implementation allows both new (possibly dependent) interpretations
and new constructs to be introduced modularly without sacrificing
performance. Complete code for all examples and case study is available
at:

  \begin{center}
\url{https://github.com/wxzh/shallow-dsl}
  \end{center}


%\bruno{Disclaimer about the OOP style promoted here: we promote
%a \emph{functional} OOP style.}
%\weixin{Or \emph{pure} OOP according to \citet{cook09abstraction}}

%if False
If we accept Cook's view on OOP, 
a natural way to distinguish implementations of EDSLs is 
in terms of the data abstraction used to model the language
constructs instead. As Reynold's~\cite{reynolds94proceduralabstraction} suggested there are two
types of data abstraction: procedural abstraction and \emph{user-defined
  types}. It is clear that shallow embeddings use \emph{procedural
  abstraction}: the DSLs are modelled by interpretation
functions. Thus, the other implementation option for EDSLs is to
use \emph{user-defined types}. In Reynolds terminology user-defined
types mean disjoint union types, which are nowadays commonly available
in modern languages as \emph{algebraic datatypes}. Disjoint union
types can also be emulated in OOP using the {\sc Visitor} pattern. 

A distinction based on data abstraction is more precise and provides a
remedy for possible misinterpretation. An EDSL implemented with
algebraic datatypes falls into the category of user-defined types
(deep embedding), while a {\sc Composite}-based OO implementation falls
under procedural abstraction (shallow embedding). 

%The {\sc Composite} or {\sc Interpreter}
%patterns are normally accepted to provide a way to encode ASTs. Thus, 
%one possible interpretation is that \emph{according to definition of deep embedding
%  above, the OO approach classifies as a deep
%  embedding}. 

For example, in their work
on EDSLs~\cite{}, Gibbons and Wu claim that deep embeddings (which
encode ASTs using algebraic datatypes in Haskell) allow adding new DSL
interpretations easily, but they make adding new language constructs
difficult. In contrast Gibbons and Wu claim that shallow embeddings
have dual modularity properties: new cases are easy to add, but new
interpretations are hard.  However what if, instead of using Haskell
and algebraic datatypes, one uses an OO language to encode an AST, for
example with the {\sc Composite} pattern.  Would this OO approach be
classified as a shallow or deep embedding? We believe arguments can be
made both ways. Since the {\sc Composite}
pattern is normally accepted to be a way to encode ASTs, it would be
reasonable to say that \emph{according to definition of deep embedding
  above, the OO approach classifies as a deep
  embedding}. Unfortunatelly this interpretation could be problematic.
As the Expression Problem~\cite{} tell us,
in the OO approach adding new language constructs is easy, but adding
interpretations is hard. Thus this would contradict Gibbons and Wu's
claims, since we have an AST representation (i.e. a deep embedding)
with the modularity properties of shallow embeddings.

We believe that the core of problem is that ASTs can be represented in
multiple ways. In particular, it is well know that functions alone are
enough to encode datastructures such as ASTs (via Church
encodings~\cite{}).  Distinguishing deep and shallow embeddings based
solely on whether a ``real'' datastructure is being used or not is
misleading.  Moreover, it gives the impression that shallow embeddings
are significantly less expressive than deep embeddings, because they
do not have access to the datastructure.
Gibbons and Wu themselves feel uneasy with the definition of shallow 
embeddings when they say:
``\emph{So it turns out that the syntax of the DSL is not really as ephemeral
in a shallow embedding as Boulton's choice of terms suggests.}''
%endif
