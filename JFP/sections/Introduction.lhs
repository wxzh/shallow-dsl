%include lhs2TeX.fmt
\section{Introduction}

Since Hudak's seminal paper on Embedded Domain Specific Languages (EDSLs)~\cite{hudak1998modular}, existing
languages (e.g. Haskell) have been used to directly encode
DSLs. Two common approaches to EDSLs are the so-called \emph{shallow}
and \emph{deep} embeddings. The origin of that terminology can be
attributed to ~\cite{Boulton92dsl}. The difference between these
two styles of embeddings is commonly described as follows:

\begin{quote}
\emph{With a \emph{deep embedding}, terms in the DSL are implemented simply to
construct an abstract syntax tree (AST), which is subsequently
transformed for optimization and traversed for evaluation. With a
\emph{shallow embedding}, terms in the DSL are implemented directly by
their semantics, bypassing the intermediate AST and its traversal.}~\cite{gibbons2014folding}
\end{quote}

One way to more precisely understand what ``\emph{terms in the DSL are
implemented directly by their semantics}'' means in a shallow
embedding is to say that terms are implemented using \emph{procedural
abstraction}~\cite{reynolds94proceduralabstraction}. This is the
definition of a shallow embedding in this paper. Such interpretation
arises naturally from the domain of shallow EDSLs being functions, and
procedural abstraction being a way to encode data abstractions using
functions.

The first goal of this pearl is to show the close relationship between
shallow embeddings and OOP.
As ~\cite{cook09abstraction} argued, procedural abstraction is also
the essence of OOP. Although OOP is often associated with stateful
(imperative) objects, it is possible to have functional objects that
have no mutable state. Indeed \cite{cook09abstraction} calls such
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
a simple solution to the \emph{Expression Problem}~\cite{expPb} in
OOP languages. Thus using just standard OOP mechanisms enables
\emph{multiple modular interpretations} to co-exist and be combined in
shallow embeddings.

We make our arguments by taking a recent paper by ~\cite{gibbons2014folding},
where procedural abstraction is used in Haskell to model a simple \emph{shallow}
EDSL. We recode that EDSL in Scala.
%\footnote{Available online: \url{https://github.com/wxzh/shallow-dsl}}.
From the \emph{modularity} point of view the
Scala version has clear advantages over the Haskell version. 

To further illustrate the applicability of our OOP approach, we conduct
a case study on refactoring an existing DSL implementation to make it
modular. \cite{rompf15} present a SQL to C compiler in Scala, which
is an external DSL but uses deep embedding techniques such as
algebraic datatypes and pattern matching in the implementation. The use of deep
embedding techniques facilitates multiple interpretations at the price
of modular language extensions. We rewrote the implementation as a
shallow Scala EDSL. The resulting implementation allows both new
interpretations and new constructs to be introduced modularly, and 
can be used directly (as an EDSL) in Scala.


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
