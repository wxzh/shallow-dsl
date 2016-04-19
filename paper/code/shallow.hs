--BEGIN_EXPR1
type Expr1 = Int
lit1 n = n
add1 e1 e2 = e1 + e2
eval1 = id
--END_EXPR1

--BEGIN_EXPR2
newtype Expr2 = Expr2 Int
lit2 n = Expr2 n
add2 (Expr2 e1) (Expr2 e2) = Expr2 $ e1 + e2
eval2 (Expr2 n) = n
--END_EXPR2

--BEGIN_EXPR3
data Expr3 = Expr3 { eval3 :: Int }
lit3 n = Expr3 { eval3 = n }
add3 e1 e2 = Expr3 { eval3 = eval3 e1 + eval3 e2 }
--END_EXPR3

--BEGIN_EXPR4
data Expr4 = Expr4 {
  eval4 :: Int,
  transform :: Expr4
}
lit4 n = Expr4 {
  eval4 = n,
  transform = lit4 n
}
add4 e1 e2 = Expr4 {
  eval4 = eval4 e1 + eval4 e2,
  transform = add4 (lit4 0) e2
}
--END_EXPR4
