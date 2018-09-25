\section{Conclusion}
This programming pearl revealed the close correspondence between OOP and shallow
embeddings: the essence of both is procedural abstraction. It also
showed how OOP increases the modularity of shallow EDSLs. OOP
abstractions, including subtyping, inheritance, and type-refinement,
bring extra modularity to traditional procedural abstraction. As a
result, multiple interpretations are allowed to co-exist in shallow
embeddings. Moreover the multiple interpretations can be \emph{dependent}: 
an interpretation can depend not only on itself, but also on other
modular interpretations. Thus the approach presented here allows us to
go \emph{beyond simple compositionality}, where interpretations can only depend
on themselves.

It has always been a hard choice between shallow and deep
embeddings when designing an EDSL: there are some tradeoffs between
the two styles.
%%A nice aspect of shallow embeddings is their simplicity.
Deep embeddings trade some simplicity and the ability to
add new language constructs for some extra power. This extra power
enables multiple interpretations, as well as complex AST transformations.
%The distinction between the two styles is not as clear in OOP languages as in functional languages.
%A shallow EDSL turns out to be deep once classes are used as types for accessing fields~\cite{cook09abstraction}, violating
% what Cook calls pure OOP, but allowing transformations to be defined.
As this pearl shows, in languages with OOP mechanisms, multiple (possibly dependent) interpretations are
still easy to do with shallow embeddings and the full benefits
of an extended form of compositionality still apply.
Therefore the motivation to employ deep embeddings becomes weaker than before
and mostly reduced to the need for AST transformations.
One final note regarding transformations, is that
prior work on the Finally Tagless~\cite{} and Object Algebras~\cite{}\bruno{cite relevant
work on transformations} approaches
already shows that transformations are still possible in those styles.
However this requires some extra machinery, and the line between shallow
and deep embeddings becomes quite blurry at that point. 

%%where 
%%Nevertheless, the need for transformations over the AST is still a valid reason to s%witch to deep embeddings.
% classes as object generators
