We thank all the reviewers for their constructive comments.

Review A
===

- if you support multiple interpretations, then how do I write DSL terms, without committing to a particular interpretation of the DSL?

There are different options to build terms:

1) An easy way that offers some weak form of modularity but not independent from multiple interpretations is to provide smart constructors of same signatures in different versions of DSLs. For example,

```
object Circuit1 {
  def fan(x: Int) = new Fan1 {val n=x}
  def beside(x: Circuit1, y: Circuit1) = new Beside1 {val c1=x; val c2=y}
  ...
}

object Circuit2 {
  def fan(x: Int) = new Fan2 {val n=x}
  def beside(x: Circuit2, y: Circuit2) = new Beside2 {val c1=x; val c2=y}
  ...
}
```
By switching import statements from `Circuit1` to `Circuit2`, we can have a circuit that supports different interpretations without touching the construction code


2) Object Algebras are complementary to our own techniques.
By building on the strength of Object Algebras, we can have terms that are independent from interpretations.
Here is the Object Algebra interface for the circuit DSL:

```
trait CircuitFactory[C] {
  def fan(x: Int): C
  def beside(x: C, y: C): C
  ...
}
```

This interface can be used to construct interpretation-independent terms:

```
def mkCircuit[C](f: CircuitFactory[C]): C = f.beside(f.fan(2),f.fan(2))
```

Now, smart constructor definitions are moved to a concrete factory:

```
object Circuit1Factory extends CircuitFactory[Circuit1] {
  def fan(x: Int) = new Fan1 {val n=x}
  def beside(x: Circuit1, y: Circuit1) = new Beside1 {val c1=x; val c2=y}
  ...
}
object Circuit2Factory extends CircuitFactory[Circuit2] {
  def fan(x: Int) = new Fan2 {val n=x}
  def beside(x: Circuit1, y: Circuit1) = new Beside2 {val c1=x; val c2=y}
  ...
}
```

Similar concrete factories can be defined for `Circuit2`.
By supplying different concrete factories to `mkCircuit`, we obtain circuits that support different  interpretations.

Review B
===


Review C
===


- "Scala inheritance is used to save a tiny bit of redefinition"
inheritance allows reuse of existing interpretations
subtyping allows new interpretations

- This paper strangely (to me) spends 2 sentences acknowledging that the approach is a bad fit for DSLs that are used with program transformation -- as if that were not a crucial feature for many DSL domains, including the most realistic one treated in this paper!


- The OOP style demonstrated here forces a linearization of the method signatures -- each new widget inherits from a particular old one, even if the two widgets in question define two methods that aren't mutually recursive.

No. For example, `Circuit2` shown on page 6 can be defined separately:

```
trait Circuit2 {
  def depth: Int
}
trait Identity2 extends Circuit2 {
  def depth = 0
}
...
```

We can merge `Circuit1` and `Circuit2` via multiple trait inheritance:

```
trait Circuit extends Circuit1 with Circuit2
trait Identity extends Circuit12 with Idenity1 with Identity2
...
```
