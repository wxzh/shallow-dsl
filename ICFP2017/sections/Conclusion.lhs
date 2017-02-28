\section{Conclusion}
This pearl revealed the close correspondence between OOP and shallow
embeddings - the essence of both is procedural abstraction.  It also
showed how OOP increases the modularity of shallow EDSLs.  OOP
abstractions, including subtyping, inheritance, and type-refinement,
bring extra modularity to traditional procedural abstraction. As a
result, multiple-interpretations are allowed to co-exist in shallow
embeddings.

This pearl also reveals that in OO languages the choice between
shallow and deep embeddings is not as clear in functional languages.
A nice aspect of shallow embeddings is their simplicity. Deep
embeddings trade some simplicity and the ability to add new language
constructs for some extra power. This extra power enables multiple
interpretations, as well transformations over the AST. This pearl
shows that in OO languages multiple interpretations are still easy
todo with shallow embeddings, so there is a weaker motivation to
employ deep embeddings. Nevertheless the need for transformations over
the AST is still a valid reason to use deep embeddings.

\begin{comment}
Existing work showed that shallow embeddings yield flexible and
concise EDSLs, while deep embedding makes it easy to define
optimizations. There is a lot of work~\cite{svenningsson2012combining,
  Jovanovic:2014:YCD:2658761.2658771, scherr2014implicit} trying to blend these two
approaches to enjoy benefits from both.
They typically encode the surface language in shallow embeddings and
then generate or translate to a deep embedded version for allowing optimizations.
%Hofer and Ostermann~\cite{hofer2010modular} propose to provide both embedding through implementing internal and external visitor at the same time so that clients can choose for a particular interpretation;
Our OO approach retains the simplicity of shallow embeddings while
allowing optimizations.
\end{comment}
