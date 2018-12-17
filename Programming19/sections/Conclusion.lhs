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
One final note regarding AST transformations is that
prior work on the Finally Tagless~\cite{kiselyov2012typed} and Object Algebras~\cite{zhang2015scrap}\bruno{cite relevant
work on transformations} approaches
already show that AST transformations are still possible in those styles.
However this requires some extra machinery, and the line between shallow
and deep embeddings becomes quite blurry at that point. 

Finally, this work shows a combination of two previously
studied solutions to the Expression Problem in OO: the extensible
interpreter design proposed by Wang and Oliveira~\cite{eptrivially16} and Object
Algebras~\cite{oliveira2012extensibility}. The combination exploits the advantages of each of
the approaches to overcome limitations of each approach individually.
In the original approach by Wang and Oliveira modular terms
are hard to model, whereas with Object Algebras a difficulty is
modeling modular dependent operations. A closely related technique is
employed by Cazolla and Vacchi~\cite{Cazzola16dsls}, although in the
context of external DSLs. Their technique is slightly different with
respect to the extensible interpreter pattern. Essentially while our
approach is purely based on subtyping and
type-refinement, they use generic types types instead to simulate the
type refinement. While the focus of our work is embedded DSLs,
the techniques discussed here are useful for other applications, including
external DSLs as Cazolla and Vacchi shows.



%%where 
%%Nevertheless, the need for transformations over the AST is still a valid reason to s%witch to deep embeddings.
% classes as object generators
