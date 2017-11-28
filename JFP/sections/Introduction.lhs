%include lhs2TeX.fmt
\section{Introduction}

Since Hudak's seminal paper~\shortcite{hudak1998modular} on embedded
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
enable tranformations on the abstract syntax, and multiple
interpretations are easy to implement; shallow-embeddings enforce the property of \emph{compositionality}
by construction, and are easily extended with new EDSL
operations. Such discussions lead to a generally accepted belief that it is hard to support
multiple interpretations and transformations in shallow embeddings.

Compositionality is considered a sign of good language design, and
it is one of the hallmarks of denotational semantics. Compositionality means
that the denotation of a program is constructed from denotations of
its parts. One advantage of compositionality is that it
leads to a modular semantics, where adding new language
constructs does not require changes in the semantics of existing constructs.
Because compositionality offers a guideline for good language design,
some authors~\cite{erwig2014semantics} argue that a semantics-first
approach to EDSLs is superior to a syntax-first approach. In such
semantics-driven approach, the idea is to first find target domain
that leads to a compositional denotational semantics, and later grow
the syntax on top of the semantic core. Shallow embeddings fit
well with such a semantics-driven approach.
Nevertheless, the limitations of shallow embeddings compared to
deep embeddings can deter their use.

This functional perl shows that, given adequate language support,
supporting multiple modular interpretations in shallow DSLs is not
only possible, but simple. Therefore this perl aims to debunk the belief
that multiple interpretations are hard to model with shallow embeddings.
Several previous authors~\cite{gibbons2014folding,erwig2014semantics} already
observed that, in conventional functional programming, by using
products and projections multiple interpretations can be supported.
Nevertheless, the use of products and projections is very cumbersome,
and often leads to code that is not modular.
We argue that multiple interpretations can be encoded naturally
when the host language supports common OO features, such as
\emph{subtyping}, \emph{inheritance} and \emph{type-refinement}.

\begin{comment}
. We show that
in languages supporting
\emph{subtyping}, \emph{inheritance} and \emph{type-refinement}
it is easy to modularly support multiple interpretations, while retaining
the other advantages of shallow-embeddings: \emph{compositionality}.


Not the expression porblem. in the EP we have only multiple independent
interpretations. The techniques that we propose here go further and
allow multiple dependent 
By removing this limitation, the 
\end{comment}


\begin{comment}
The origin of that terminology can be
attributed to Boulton et al.~\shortcite{Boulton92dsl}. The difference between these
two styles of embeddings is commonly described as follows:

\begin{quote}
With a \emph{deep embedding}, terms in the DSL are implemented simply to
construct an abstract syntax tree (AST), which is subsequently
transformed for optimization and traversed for evaluation. With a
\emph{shallow embedding}, terms in the DSL are implemented directly by
their semantics, bypassing the intermediate AST and its traversal.\\~\cite{gibbons2014folding}
\end{quote}


\weixin{add procedural abstraction definition}
One way to more precisely understand what ``\emph{terms in the DSL are
implemented directly by their semantics}'' means in a shallow
embedding is to say that terms are implemented using \emph{procedural
abstraction} where

\begin{quote}
The abstract form of data is characterized by the primitive operations which can be peformed upon it, and an item of data is simply a procedure or collection of procedures for performing these operations.~\cite{reynolds75userdefined}
\end{quote}

\noindent This is the definition of a shallow embedding in this paper. Such interpretation
arises naturally from the domain of shallow EDSLs being functions, and
procedural abstraction being a way to encode data abstractions using
functions.
\end{comment}

At the center of this pearl is Reynolds \shortcite{reynolds75userdefined} idea of \emph{procedural abstraction}, which
enables us to directly relate shallow embeddings and OOP. With procedural abstraction data is characterized by the operations that are performed over it.
This pearl starts by discussing two independently observed connections to procedural abstraction:

\xymatrixcolsep{6pc}
\xymatrix{
\text{Shallow Embeddings} \ar@@{<->}[r]^-*+{\text{Gibbons and Wu~\shortcite{gibbons2014folding}}} & \text{Procedural Abstraction}\ar@@{<->}[r]^-*+{\text{Cook~\shortcite{cook09abstraction}}} & \text{OOP}
}
\vspace{5pt}
\noindent The first connection is between procedural abstraction and shallow embeddings.
As Gibbons and Wu~\shortcite{gibbons2014folding} state ``\emph{it was probably known to Reynolds, who contrasted
deep embeddings (‘user defined types’) and shallow (‘procedural data
structures’)}''. Gibbons and Wu noted the connection between shallow embeddings
and procedural abstractions, although they did not go into a lot of detail.
The second connection is the connection between OOP and procedural
abstraction, which was widely discussed by Cook~\shortcite{cook09abstraction}.




\begin{comment}
The first goal of this pearl is to show the close relationship between
shallow embeddings and object-oriented programming (OOP).
As Cook~\shortcite{cook09abstraction} argued, procedural abstraction is also
the essence of OOP. Although OOP is often associated with stateful
(imperative) objects, it is possible to have functional objects that
have no mutable state. Indeed Cook~\shortcite{cook09abstraction} calls such
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

To make our arguments we take the examples in Gibbons and Wu~\shortcite{gibbons2014folding}'s paper,
where procedural abstraction is used in Haskell to model a simple \emph{shallow}
EDSL. We recode that EDSL in Scala, using a
recently proposed design pattern~\cite{eptrivially16}, which provides
a simple solution to the \emph{Expression Problem}~\cite{expPb}.
%\footnote{Available online: \url{https://github.com/wxzh/shallow-dsl}}.
From the \emph{modularity} point of view the
resulting Scala version has clear advantages over the Haskell version, due
to the use of subtyping, inheritance and type-refinement. In particular, the Scala code
allows the denotation of a program to easily \emph{depend on other modular denotations}. 

While the technique proposed here does not deal with transformations, yielding efficient shallow EDSL is still possible via staging~\cite{rompf2012lightweight,carette2009finally}.
By removing the limitation of multiple interpretations, we enlarge the applicability of shallow embeddings. A concrete example is our case study, which refactors an external DSL that employs deep embedding techiniques~\cite{rompf15} into a shallow EDSL.
The refactored implementation allows both new interpretations and new constructs to be introduced modularly without sacrificing performance.
Complete code for all examples and the case study is available online:

\center{\url{https://github.com/wxzh/shallow-dsl}}

\begin{comment}
To further illustrate the applicability of our OOP approach, we conduct
a case study on refactoring an existing DSL implementation to make it
modular. Rompf and Amin~\shortcite{rompf15} present a SQL to C compiler in Scala, which
is an external DSL but uses deep embedding techniques such as
algebraic datatypes and pattern matching in the implementation. The use of deep
embedding techniques facilitates multiple interpretations at the price
of modular language extensions. We rewrote the implementation as a
shallow Scala EDSL. The resulting implementation allows both new
interpretations and new constructs to be introduced modularly, and
can be used directly (as an EDSL) in Scala.
\end{comment}

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
