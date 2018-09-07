%include lhs2TeX.fmt
%include polycode.fmt
%include def.fmt

%format :<: = "\prec"
%format <+> = "\oplus"

% no longer semantics first?

\section{Modular Interpretations in Haskell}
Indeed, modular interpretations are also possible in Haskell using the Finally Tagless~\cite{carette2009finally} approach.
The idea is to use a \emph{type class} to abstract over the signatures of constructs and define interpretations as instances of that type class. This section recodes the \dsl example and compares the two modular implementations in Haskell and Scala.

\subsection{Revisiting \dsl}
Here is the type class defined for \dsl:

> class Circuit c where
>   id       ::  Int -> c
>   fan      ::  Int -> c
>   above    ::  c -> c -> c
>   beside   ::  c -> c -> c
>   stretch  ::  [Int] -> c -> c

The signatures are the same as what \autoref{subsec:shallow} shows except that the semantic domain is captured by a type parameter |c|.
Interpretations such as |width| are then defined as instances of |Scans|:


> newtype Width = Width {width :: Int}
>
> instance Circuit Width where
>   id n          =  Width n
>   fan n         =  Width n
>   beside c1 c2  =  Width (width c1 + width c2)
>   above c1 c2   =  Width (width c1)
>   stretch ns c  =  Width (sum ns)

where |c| is instantiated as a record type |Width|.
Instantiating the type parameter as |Width| rather than |Int| avoids the conflict with the |depth| interpretation which also produces integers.

\paragraph{Multiple interpretaions} Adding |depth| interpretation can now be done in a modular manner similar to |width|:

> newtype Depth = Depth {depth :: Int}
>
> instance Circuit Depth where
>   id n           =  Depth n
>   fan n          =  Depth n
>   beside c1 c2   =  Depth (depth c1 + depth c2)
>   above c1 c2    =  Depth (depth c1 `max` depth c2)
>   stretch ns c   =  Depth (depth c)

\paragraph{Dependent interpretation} However, adding dependent interpretation like |wellSized| is more challenging.
We need the following type class introduced by ~\cite{Bahr}:

> class a :<: b where
>   inter :: b -> a
>
> instance a :<: a where
>   inter = id
>
> instance a :<: (a,b) where
>   inter = fst
>
> instance (c :<: b) => c :<: (a,b) where
>   inter = inter . snd

This type class is defined for simulating subtyping relation.
|a :<: b| means that type |a| is a component of a larger
collection of types represented by |b|. The member function |inter|
retrieves a value of type |a| from a value of the compound type |b|.
The three instances, which are defined using overlapping instances,
define the behaviour of the projection function by searching for
the type being projected in a larger state space that contains
a value of that type.

Now, defining |wellSized| modularly becomes possible:

> instance (Circuit c, Width :<: c) => Circuit (Compose WellSized c) where
>   id  n         =  (WellSized True, id n)
>   fan n         =  (WellSized True, fan n)
>   above c1 c2   =  (WellSized (gwellSized c1 && gwellSized c2 && gwidth c1 == gwidth c2)
>                    ,above (inter c1) (inter c2))
>   beside c1 c2  =  (WellSized (gwellSized c1 && gwellSized c2),beside (inter c1) (inter c2))
>   stretch ns c  =  (WellSized (gwellSized c && length ns == gwidth c),stretch ns (inter c))
>
> gwidth :: Width :<: c => c -> Int
> gwidth = width . inter
>
> gwellSized :: WellSized :<: c => c -> Bool
> gwellSized = wellSized . inter

Essentially, dependent interpretations are still defined using tuples.
The dependency on |width| is expressed by constraining the type parameter as |Width :<: c|. Such dependency is not hard-wired to any concrete implementation of |width|.
The implementation is modular but requires some boilerplate.
The reuse of |width| is achieved via delegatation, where |inter| needs to be called on each subcircuit. Also, auxiliary definitions |gwidth| and |gwellSized| are necessary for projecting the desired interpretations from the constrained type parameter.

\paragraph{Modular terms}
The circuit shown in \autoref{fig:circuit} can be constructed and interpreted differently:

> c  ::  Circuit c => c
> c  =   (fan 2 `beside` fan 2) `above`
>        stretch [2,2] (fan 2) `above`
>        (id 1 `beside` fanF 2 `beside` id 1)
>
> width (c :: Width)                          -- 4
> gwellSized (c :: Compose WellSized Width)   -- True

Note that |c| needs to be annotated with target semantic domain in choosing an appropriate type class instance for interpretation.

\paragraph{Syntax extensions}
Type classes also allow us to modularly extend \dsl with more language constructs such as |rstretch|:

> class Circuit c => ExtendedCircuit c where
>   rstretch :: [Int] -> c -> c

Existing interpretations can be modularly extended so that |rstretch| can be handled:

> instance ExtendedCircuit Width where
>   rstretch = stretch

\subsection{Comparing language features needed for modular implementation: Scala vs Haskell}
Although both Scala and Haskell are able to encode modular shallow embedding, they use a different set of language features. \autoref{comparison} compares the language features needed by Scala and Haskell for a modular implemention. Our Scala approach is arguably superior than the Haskell approach for the following reasons:
\begin{itemize}
  \item It uses simpler language features that are common in OO languages and not require parametric polymorphism;
\item It needs less boilerplate for dependent interpretations;
\item It retains the semantics-first benefits of shallow embedding.


\end{itemize}

\begin{table}
  \caption{Language features needed for modular interpretations: Scala vs. Haskell }
  \begin{tabular}{lcc}
  \textbf{Functionality} & \textbf{Scala} & \textbf{Haskell} \\
  \toprule
  Multiple interpretations & Type refinement & Type class \\
  Interpretation reuse & Inheritance & Delegation \\
  Dependency declaration & Subtyping & Type constraints \\ %(similar to bounded qualifications)
  \bottomrule
  \end{tabular}
  \label{comparison}
\end{table}

% encoding of subtyping

% less boilerplate and no parametric polymorphism is needed
