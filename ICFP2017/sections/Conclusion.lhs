\section{Conclusion}
This pearl shows the close correspondence between OOP and shallow
embeddings, and how OOP improves the modularity of shallow EDSLs.
With OOP, various types of interpretations can be defined modularly. 
Moreover defining transformations is also possible.

Existing work showed that shallow embeddings yield flexible and
concise EDSLs, while deep embedding makes it easy to define
optimizations. There is a lot of work~\cite{svenningsson2012combining,
  Jovanovic:2014:YCD:2658761.2658771, scherr2014implicit} trying to blend these two
approaches to enjoy benefits from both.
They typically encode the surface language in shallow embeddings and
then generate or translate to a deep embedded version for allowing optimizations.
%Hofer and Ostermann~\cite{hofer2010modular} propose to provide both embedding through implementing internal and external visitor at the same time so that clients can choose for a particular interpretation;
Our OO approach retains the simplicity of shallow embeddings while
allowing optimizations. It would be interesting
to conduct larger case studies to assess whether the techniques
presented here are enough to avoid sophisticated deep embeddings for various DSLs
in the literature.

One limitation is that
transformations require code duplication in extensions,
as we must give an implementation when refining their return type.
Though transformations can still be defined modularly with advanced type
system features of Scala~\cite{zenger05independentlyextensible},
the encoding would become significantly more complicated.
How to define these transformations modularly, without code
duplication, and without sophisticated types
is a possible line of future work.  
%Also, it is tedious to
%express the inheritance relationships in extensions, especially when
%multiple inheritance is used. Another line of future work is to use
%some meta-programming mechanisms to eliminate such boilerplate.
