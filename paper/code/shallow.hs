--BEGIN_TYPE
lit :: Int -> Exp
add :: Exp -> Exp -> Exp
--END_TYPE

--BEGIN_EXPR1
type Exp1 = Bool
lit1 n = n == 0
add1 _ _ = false
is0 = id
--END_EXPR1

--BEGIN_EXPR2
newtype Exp2 = Exp2 Bool
lit2 n = Exp2 n
add2 (Exp2 e1) (Exp2 e2) = Exp2 $ e1 + e2
is0 (Exp2 e) = e
--END_EXPR2

--BEGIN_EXPR3
newtype Exp3 = Exp3 { eval3 :: Int }
lit3 n = Exp3 { eval3 = n }
add3 e1 e2 = Exp3 { eval3 = eval3 e1 + eval3 e2 }
--END_EXPR3

--BEGIN_EXPR4
data Exp4 = Exp4 {
  eval4 :: Int,
  transform :: Exp4
}
lit4 n = Exp4 {
  eval4 = n,
  transform = lit4 n
}
add4 e1 e2 = Exp4 {
  eval4 = eval4 e1 + eval4 e2,
  transform = add4 (lit4 0) e2
}

data Exp = Exp {
  is0 :: Bool,
  peval :: Exp
}
lit n = Exp {
  is0 = n == 0,
  peval = lit n
}
add e1 e2 = Exp {
  is0 = false,
  peval = let (e1', e2') = (peval e1, peval e2)
          in if (is0 e1') then e2' else add(e1', e2')
}
--END_EXPR4
