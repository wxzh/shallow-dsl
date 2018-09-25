%include lhs2TeX.fmt
%include polycode.fmt
%include def.fmt

%format :<: = "\prec"
%format <+> = "\oplus"

% no longer semantics first?

\section{Modular interpretations in Haskell}\label{sec:modHaskell}
Modular interpretations are also possible in Haskell using the Finally Tagless~\cite{carette2009finally} approach.
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
try to mimick the OO mechanisms in Haskell to obtain similar benefits in Haskell.
In what follows we explain how to encode subtyping, inheritance and type-refinement
in Haskell and how that encoding enables additional modularity benefits in Haskell.

\paragraph{Subtyping}
In the Scala solution subtyping avoids the explicit projections that are needed
in the Haskell solution presented in~\autoref{sec:interp}.
We can obtain a similar benefit in Haskell by encoding a subtyping relation
on tuples in Haskell. We use the following type class, which was introduced by
Bahr and Hvitved~\cite{bahr2011compositional}, to express a subtyping relation on tuples:

> class a :<: b where
>   inter :: a -> b
>
> instance a :<: a where
>   inter x = x
>
> instance (a,b) :<: a where
>   inter = fst
>
> instance (b :<: c) => (a,b) :<: c where
>   inter = inter . snd

In essence a type |a| is a subtype of a type |b| (expressed as |a :<:
b|) if |a| has \emph{the same or more} tuple components as the type
|b|. This subtyping relation is closely related to the elaboration interpretation
of \emph{intersection types} proposed by Dunfield~\cite{dunfield2014elaborating}, where
Dunfield's merge operator corresponds (via elaboration) to the tuple constructor and
projections are implicit and type-driven.
The function |inter| simulates up-casting, which converts a
value of type |a| to a value of type |b|.  The three instances, which
are defined using overlapping instances, define the behaviour of the
projection function by searching for the type being projected in a
compound type.

\paragraph{Modular |wellSized| and encodings of inheritance and type-refinement}
Now, defining |wellSized| modularly becomes possible:

> instance (Circuit c, c :<: Width) => Circuit (WellSized, c) where
>    id  n         =  (WellSized True, id n)
>    fan n         =  (WellSized True, fan n)
>    above c1 c2   =  (WellSized (gwellSized c1 && gwellSized c2 && gwidth c1 == gwidth c2)
>                     ,above (inter c1) (inter c2))
>    beside c1 c2  =  (WellSized (gwellSized c1 && gwellSized c2),beside (inter c1) (inter c2))
>    stretch ns c  =  (WellSized (gwellSized c && length ns == gwidth c),stretch ns (inter c))
>
> gwidth :: (c :<: Width) => c -> Int
> gwidth = width . inter
>
> gdepth :: (c :<: Depth) => c -> Int
> gdepth = depth . inter
>
> gwellSized :: (c :<: WellSized) => c -> Bool
> gwellSized = wellSized . inter

Essentially, dependent interpretations are still defined using tuples.
The dependency on |width| is expressed by constraining the type
parameter as |c :<: Width|.  Such constraint allows us to simulate the
type-refinement of fields in the Scala solution.  % Nevertheless, such
The dependency is not hard-wired to any concrete implementation of
|width|.  Although the implementation is modular, it requires some boilerplate.
The reuse of |width| interpretation is achieved via delegatation,
where |inter| needs to be called on each subcircuit. Such explicit
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

|circuit| is a generic circuit that is not tied to any interpretation.
When interpreting |circuit|, its type needs to be instantiated:

< > width (circuit :: Width)                    -- 4
< > depth (circuit :: Depth)                    -- 3
< > gwellSized (circuit :: (WellSized,Width))   -- True

Note that |circuit| is annotated with the target semantic domain in choosing an appropriate type class instance for interpretation.

\begin{comment}
We can further \emph{truly} compose interpretations to avoid repeating the construction of |c| for each interpretation:

> circuit' = circuit :: (Depth,(WellSized,Width))
> gwidth circuit'      -- 4
> gdepth circuit'      -- 3
> gwellSized circuit'  -- True
>
> gdepth :: (Depth :<: c) => c -> Int
> gdepth = depth . inter
>
> instance (Circuit a, Circuit b) => Circuit (a,b) where
>   id n         = (id n, id n)
>   fan n        = (fan n, fan n)
>   above c1 c2  = (above (inter c1) (inter c2), above (inter c1) (inter c2))
>   beside c1 c2 = (beside (inter c1) (inter c2), beside (inter c1) (inter c2))
>   stretch xs c = (stretch xs (inter c), stretch xs (inter c))
\end{comment}

\paragraph{Syntax extensions}
The Finally Tagless solution also allows us to modularly extend \dsl with more
language constructs such as |rstretch|:

> class Circuit c => ExtendedCircuit c where
>   rstretch :: [Int] -> c -> c

Existing interpretations can be modularly extended so that |rstretch| can be handled:

> instance ExtendedCircuit Width where
>   rstretch = stretch

\subsection{Comparing modular implementations using Scala and Haskell}

Although both the Scala and Haskell solutions are able to do modular dependent interpretations
embedding, they use a different set of language
features.
%%\autoref{comparison} compares the language features needed
%%by Scala and Haskell for a modular implemention.
The Scala approach
relies on built-in features. In particular, subtyping, multiple (trait)
inheritance and type-refinement are all built-in. This makes it
quite natural to program the solutions in Scala, without even needing
any form of parametric polymorphism. In contrast the Haskell solution
does not have such built-in support for OO features. Subtyping and
type-refinement need to be
encoded/simulated using parametric polymorphism and type classes.
Inheritance is simulated by explicitly delegating method implementations.
The encoding is arguably conceptually more difficult to understand and use, but
it is still quite simple. One interesting feature that is
supported in Haskell is the ability to encode modular terms. This relies
on the fact that the constructors are overloaded. The Scala
solution presented so far does not allow such overloading, so code
using constructors is tied with a specific interpretation.
In the next section we will see a final refinement of the Scala
solution that enables modular terms, by using overloaded constructors too.

\begin{comment}
Our Scala approach is
arguably superior than the Haskell approach for the following reasons:
\begin{itemize} \item It uses simpler language features that are
common in OO languages and not require parametric polymorphism; \item
It needs less boilerplate for dependent interpretations; \item It
retains the semantics-first benefits of shallow embedding.


\end{itemize}

\begin{table}
  \begin{tabular}{lcc}
  \textbf{Functionality} & \textbf{Scala} & \textbf{Haskell} \\
  \toprule
  Multiple interpretations & Type refinement & Type class \\
  Interpretation reuse & Inheritance & Delegation \\
  Dependency declaration & Subtyping & Type constraints \\ %(similar to bounded qualifications)
  \bottomrule
  \end{tabular}
  \caption{Language features needed for modular interpretations: Scala vs. Haskell }  
  \label{comparison}
\end{table}
\end{comment}

% encoding of subtyping

% less boilerplate and no parametric polymorphism is needed
