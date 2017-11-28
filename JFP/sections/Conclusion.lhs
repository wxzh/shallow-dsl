\section{Conclusion}
This pearl revealed the close correspondence between OOP and shallow
embeddings - the essence of both is procedural abstraction. It also
showed how OOP increases the modularity of shallow EDSLs. OOP
abstractions, including subtyping, inheritance, and type-refinement,
bring extra modularity to traditional procedural abstraction. As a
result, multiple interpretations are allowed to co-exist in shallow
embeddings.

It has always been a hard choice between shallow and deep
embeddings when designing a EDSL: there are some tradeoffs between
the two styles.
A nice aspect of shallow embeddings is their simplicity.
Deep embeddings trade some simplicity and the ability to
add new language constructs for some extra power. This extra power
enables multiple interpretations, as well as complex transformations
over the AST.
%The distinction between the two styles is not as clear in OOP languages as in functional languages.
%A shallow EDSL turns out to be deep once classes are used as types for accessing fields~\cite{cook09abstraction}, violating
% what Cook calls pure OOP, but allowing transformations to be defined.
As this pearl shows, in OO languages, multiple interpretations are
still easy to do with shallow embeddings.
Moveover, Erwig and Walkingshaw~\shortcite{erwig2014semantics} argue that
shallow embeddings are more semantics-driven compared to deep embeddings
which have many preferable properties in designing DSLs.
Therefore the motivation to employ deep embeddings becomes weaker.
Nevertheless, the need for transformations over the AST is still a valid reason to switch to deep embeddings.

% classes as object generators
