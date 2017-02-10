\documentclass{jfp1}

%include lhs2TeX.fmt
%include lhs2TeX.sty
%include polycode.fmt
%include def.fmt

\usepackage{color}
\usepackage{url}
\usepackage{xspace}
\usepackage{syntax}
\usepackage{comment}

\newcommand{\dsl}{\textsc{Scans}\xspace}
\newcommand{\interp}{\textsc{Interpreter}\xspace}

%\newcommand{\authornote}[3]{}
\newcommand{\authornote}[3]{{\color{#2} {\sc #1}:#3}}
\newcommand{\weixin}[1]{\authornote{weixin}{cyan}{#1}}
\newcommand{\bruno}[1]{\authornote{bruno}{red}{#1}}

\begin{document}

\title{Shallow EDSLs and Object-Oriented Programming}


\author[W. Zhang and B. C. D. S. Oliveira]
        {WEIXIN ZHANG and BRUNO C. D. S. OLIVEIRA\\
         The University of Hong Kong, Hong Kong}
%\\\email{\{wxzhang2,bruno\\@cs.hku.hk}}
%\authorinfo{Name}
%           {Affiliation2/3}
%           {Email2/3}

\maketitle[f]

\begin{abstract}

Shallow Embedded Domain Specific Languages (EDSLs) use
\emph{procedural abstraction} to directly encode a DSL into an existing host language. Procedural abstraction has
been argued to be the essence of Object-Oriented Programming (OOP). 
%Given
%that OO languages have evolved over more than 50 years
%to improve the use of procedural abstraction, they ought to have some
%advantages to encode shallow EDSLs.
This paper argues that OOP abstractions 
(including \emph{inheritance}, \emph{subtyping} and
\emph{type-refinement}) 
increase the modularity and reuse of shallow
EDSLs when compared to classical procedural abstraction. We make this
argument by taking a recent paper by Gibbons and Wu, where procedural
abstraction is used in Haskell to model a simple shallow EDSL, and we recode
that EDSL in Scala. From the \emph{semantic}
and \emph{modularity} point of view the Scala version has clear advantages 
over the Haskell version. 

%To alleviate some of the syntactical disadvantages of Java, we create
%an annotation inspired by \emph{family polymorphism} and a recent
%solution to the Expression Problem.
%The annotation uses transparent code generation techniques to
%automatically eliminate large portions of boilerplate code.
%To further illustrate the applicability of our tool and techniques, we conduct
%several case studies using larger DSLs from the literature.
\end{abstract}

% mention Willam Cook's work
% pure: class are only used to construct objects. The use of classes as types are discussed later. No inheritance


%===============================================================================
%include Introduction.lhs
%include ShallowOO.lhs
%include Interpretations.lhs
%include Casestudy.lhs
%\acks

%Acknowledgments, if needed.

\bibliographystyle{jfp}
\bibliography{Main}


\end{document}
