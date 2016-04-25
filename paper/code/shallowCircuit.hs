{-BEGIN_CTYPE
type Circuit = ...
identity :: Int -> Circuit
fan :: Int -> Circuit
beside :: Circuit -> Circuit -> Circuit
END_CTYPE-}

-- stretch :: [Int] -> Circuit -> Circuit

--BEGIN_CIRCUIT1
type Circuit1 = Int
identity1 n = n
fan1 n = n
beside1 c1 c2 = c1 + c2

width1 = id
--END_CIRCUIT1

--BEGIN_CIRCUIT2
newtype Circuit2 = Circuit2 Int
identity2 n = Circuit2 n
fan2 n = Circuit2 n
beside2 (Circuit2 c1) (Circuit2 c2) =
  Circuit2 $ c1 + c2

width2 (Circuit2 n) = n
--END_CIRCUIT2


--BEGIN_CIRCUIT3
newtype Circuit3 = Circuit3 { width3 :: Int }
identity3 n = Circuit3 { width3 = n }
fan3 n = Circuit3 { width3 = n }
beside3 c1 c2 = Circuit3 {
  width3 = width3 c1 + width3 c2
}
--END_CIRCUIT3

--BEGIN_DESUGAR
data Circuit = Circuit {
  width :: Int,
  desugar :: Circuit
}
identity n = Circuit {
  width = width c,
  desugar = c
} where c = foldl1 beside $ replicate n (fan 1)
fan n = Circuit {
  width = n,
  desugar = fan n
}
beside c1 c2 = Circuit {
  width = width c1 + width c2,
  desugar = beside (desugar c1) (desugar c2)
}
--END_DESUGAR

--BEGIN_SYNTAX_HS
--identity n = n
above _ c2 = c2
--END_SYNTAX_HS


--BEGIN_SEMANTICS_HS
--fan2 n = (n, n > 0)
--beside2 c1 c2 = (fst c1 + fst c2, snd c1 && snd c2)
--stretch2 ns c = (sum ns, snd c && length ns == fst c)
--END_SEMANTICS_HS
