\section{Conclusion}
This pearl revealed the close correspondence between OOP and shallow
embeddings - the essence of both is procedural abstraction.  It also
showed how OOP increases the modularity of shallow EDSLs.  OOP
abstractions, including subtyping, inheritance, and type-refinement,
bring extra modularity to traditional procedural abstraction. As a
result, multiple interpretations are allowed to co-exist in shallow
embeddings.

It has always being a hard choice between the shallow and deep embedding when implementing a DSL - there are some tradeoffs between the two styles.
A nice aspect of shallow embeddings is their simplicity. Deep
embeddings trade some simplicity and the ability to add new language
constructs for some extra power. This extra power enables multiple
interpretations, as well as complex transformations over the AST.
The distinction between the two styles is not as clear in OOP languages as in functional languages.
A shallow EDSL turns to be deep once classes are used as types~\cite{cook09abstraction}.
As this pearl shows that in OO languages, multiple interpretations are still easy
to do with shallow embeddings, the motivation to
employ deep embeddings becomes weaker.
Nevertheless, the need for transformations over
the AST is still a valid reason to switch to deep embeddings.
