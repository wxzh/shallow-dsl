identity :: Int -> Circuit
fan :: Int -> Circuit
beside :: Circuit -> Circuit -> Circuit

--BEGIN_DESUGAR
data Circuit = Circuit {
  width   :: Int,
  desugar :: Circuit
}
identity n = Circuit {
  width   = n,
  desugar = foldr1 beside $ replicate n (fan 1)
}
fan n = Circuit {
  width   = n,
  desugar = fan n
}
beside c1 c2 = Circuit {
  width   = width c1 + width c2,
  desugar = beside (desugar c1) (desugar c2)
}
--END_DESUGAR

