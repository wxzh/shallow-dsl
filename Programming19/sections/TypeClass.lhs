%include lhs2TeX.fmt
%include polycode.fmt
%include def.fmt

%format :<: = "\prec"
%format <+> = "\oplus"

% no longer semantics first?

\section{Modular interpretations in Haskell}\label{sec:modHaskell}
Modular interpretations are also possible in Haskell via a variant of Church encodings that uses type classes. The original technique is due to Hinze~\cite{hinze06generics} and was shown to be modular and extensible by Oliveira et al.~\cite{emgm}. It has since been popularized under the name Finally Tagless~\cite{carette2009finally} in the context of embedded DSLs.
The idea is to use a \emph{type class} to abstract over the signatures of constructs and define interpretations as instances of that type class. This section recodes the \dsl example and compares the two modular implementations in Haskell and Scala.

\subsection{Revisiting \dsl} \label{sec:class}
Here is the type class defined for \dsl:

> class Circuit c where
>   id       ::  Int -> c
>   fan      ::  Int -> c
>   above    ::  c -> c -> c
>   beside   ::  c -> c -> c
>   stretch  ::  [Int] -> c -> c

The signatures are the same as what \autoref{subsec:shallow} shows except that the semantic domain is captured by a type parameter |c|.
Interpretations such as |width| are then defined as instances of |Circuit|:


> newtype Width = Width {width :: Int}
>
> instance Circuit Width where
>   id n          =  Width n
>   fan n         =  Width n
>   above c1 c2   =  Width (width c1)
>   beside c1 c2  =  Width (width c1 + width c2)
>   stretch ns c  =  Width (sum ns)

where |c| is instantiated as a record type |Width|.
Instantiating the type parameter as |Width| rather than |Int| avoids the conflict with the |depth| interpretation which also produces integers.

\paragraph{Multiple interpretations} Adding the |depth| interpretation can now be done in a modular manner similar to |width|:

> newtype Depth = Depth {depth :: Int}
>
> instance Circuit Depth where
>   id n           =  Depth 0
>   fan n          =  Depth 1
>   above c1 c2    =  Depth (depth c1 + depth c2)
>   beside c1 c2   =  Depth (depth c1 `max` depth c2)
>   stretch ns c   =  Depth (depth c)

\subsection{Modular dependent interpretations}
Adding a modular dependent interpretation like |wellSized| is more challenging
in the Finally Tagless approach. However, inspired by the OO approach we can
try to mimic the OO mechanisms in Haskell to obtain similar benefits in Haskell.
In what follows we explain how to encode subtyping, inheritance, and type-refinement
in Haskell and how that encoding enables additional modularity benefits in Haskell.

\paragraph{Subtyping}
In the Scala solution subtyping avoids the explicit projections that are needed
in the Haskell solution presented in~\autoref{sec:interp}.
We can obtain a similar benefit in Haskell by encoding a subtyping relation
on tuples in Haskell. We use the following type class, which was introduced by
Bahr and Hvitved~\cite{bahr2011compositional}, to express a subtyping relation on tuples:

> class a :<: b where
>   prj :: a -> b
>
> instance a :<: a where
>   prj x = x
>
> instance (a,b) :<: a where
>   prj = fst
>
> instance (b :<: c) => (a,b) :<: c where
>   prj = prj . snd

In essence a type |a| is a subtype of a type |b| (expressed as |a :<:
b|) if |a| has \emph{the same or more} tuple components as the type
|b|. This subtyping relation is closely related to the elaboration interpretation
of \emph{intersection types} proposed by Dunfield~\cite{dunfield2014elaborating}, where
Dunfield's merge operator corresponds (via elaboration) to the tuple constructor and
projections are implicit and type-driven.
The function |prj| simulates up-casting, which converts a
value of type |a| to a value of type |b|.  The three overlapping instances define the behaviour of the projection function by searching for the type being projected in a compound type.

\paragraph{Modular |wellSized| and encodings of inheritance and type-refinement}
Now, defining |wellSized| modularly becomes possible:

> newtype WellSized  = WellSized {wellSized :: Bool}
>
> instance (Circuit c, c :<: Width) => Circuit (WellSized, c) where
>    id  n         =  (WellSized True, id n)
>    fan n         =  (WellSized True, fan n)
>    above c1 c2   =  (WellSized (gwellSized c1 && gwellSized c2 && gwidth c1 == gwidth c2)
>                     ,above (prj c1) (prj c2))
>    beside c1 c2  =  (WellSized (gwellSized c1 && gwellSized c2),beside (prj c1) (prj c2))
>    stretch ns c  =  (WellSized (gwellSized c && length ns == gwidth c),stretch ns (prj c))
>
> gwidth :: (c :<: Width) => c -> Int
> gwidth = width . prj
>
> gdepth :: (c :<: Depth) => c -> Int
> gdepth = depth . prj
>
> gwellSized :: (c :<: WellSized) => c -> Bool
> gwellSized = wellSized . prj

Essentially, dependent interpretations are still defined using tuples.
The dependency on |width| is expressed by constraining the type
parameter as |c :<: Width|.  Such constraint allows us to simulate the
type-refinement of fields in the Scala solution.  % Nevertheless, such
%The dependency is not hard-wired to any concrete implementation of |width|.
Although the implementation is modular, it requires some boilerplate.
The reuse of |width| interpretation is achieved via delegation,
where |prj| needs to be called on each subcircuit. Such explicit
delegation simulates the inheritance employed in the Scala
solution.  Also, auxiliary definitions |gwidth| and |gwellSized| are
necessary for projecting the desired interpretations from the
constrained type parameter.

\subsection{Modular terms}
As new interpretations may be added later, a problem is how to construct the term that can be interpreted by those new interpretations without reconstruction.
We show how to do this for the circuit shown in \autoref{fig:circuit}:

> circuit  ::  Circuit c => c
> circuit  =   (fan 2 `beside` fan 2) `above`
>              stretch [2,2] (fan 2) `above`
>              (id 1 `beside` fan 2 `beside` id 1)

Here, |circuit| is a generic circuit that is not tied to any interpretation.
When interpreting |circuit|, its type must be instantiated:

< > width (circuit :: Width)                    -- 4
< > depth (circuit :: Depth)                    -- 3
< > gwellSized (circuit :: (WellSized,Width))   -- True

At user-site, |circuit| must be annotated with the target semantic domain so that an appropriate type class instance for interpretation can be chosen.

\begin{comment}
We can further \emph{truly} compose interpretations to avoid repeating the construction of |c| for each interpretation:

> circuit' = circuit :: (Depth,(WellSized,Width))
> gwidth circuit'      -- 4
> gdepth circuit'      -- 3
> gwellSized circuit'  -- True
>
> gdepth :: (Depth :<: c) => c -> Int
> gdepth = depth . prj
>
> instance (Circuit a, Circuit b) => Circuit (a,b) where
>   id n         = (id n, id n)
>   fan n        = (fan n, fan n)
>   above c1 c2  = (above (prj c1) (prj c2), above (prj c1) (prj c2))
>   beside c1 c2 = (beside (prj c1) (prj c2), beside (prj c1) (prj c2))
>   stretch xs c = (stretch xs (prj c), stretch xs (prj c))
\end{comment}

\paragraph{Syntax extensions}
This solution also allows us to modularly extend~\cite{emgm} \dsl with more
language constructs such as |rstretch|:

> class Circuit c => ExtendedCircuit c where
>   rstretch :: [Int] -> c -> c

Existing interpretations can be modularly extended to handle |rstretch|:

> instance ExtendedCircuit Width where
>   rstretch = stretch

Existing circuits can also be reused for constructing circuits in extended \dsl:

> circuit2 :: ExtendedCircuit c => c
> circuit2 = rstretch [2,2,2,2] circuit

\subsection{Comparing modular implementations using Scala and Haskell}

Although both the Scala and Haskell solutions are able to do modular dependent interpretations
embedding, they use a different set of language features.
\autoref{comparison} compares the language features needed by Scala and Haskell.
The Scala approach relies on built-in features. In particular, subtyping, inheritance (mixin composition) and type-refinement are all built-in. This makes it
quite natural to program the solutions in Scala, without even needing
any form of parametric polymorphism. In contrast, the Haskell solution
does not have such built-in support for OO features. Subtyping and
type-refinement need to be
encoded/simulated using parametric polymorphism and type classes.
Inheritance is simulated by explicit delegations.
The Haskell encoding is arguably conceptually more difficult to understand and use, but
it is still quite simple. One interesting feature that is
supported in Haskell is the ability to encode modular terms. This relies
on the fact that the constructors are overloaded. The Scala
solution presented so far does not allow such overloading, so code
using constructors is tied with a specific interpretation.
In the next section we will see a final refinement of the Scala
solution that enables modular terms, also by using overloaded constructors.

%TODO: mention tuples
\begin{table}
  \centering
  \begin{tabular}{lcc}
  \textbf{Goal} & \textbf{Scala} & \textbf{Haskell} \\
  \toprule
  Multiple interpretation & Trait \& Type-refinement  & Type class \\
  Interpretation reuse & Inheritance & Delegation \\
  Dependency declaration & Subtyping & Tuples \& Type constraints \\ %(similar to bounded qualifications)
  \bottomrule
  \end{tabular}
  \caption{Language features needed for modular interpretations: Scala vs. Haskell.}
  \label{comparison}
\end{table}

% encoding of subtyping

% less boilerplate and no parametric polymorphism is needed
