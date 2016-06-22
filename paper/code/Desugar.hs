id :: Int -> Circuit
fan :: Int -> Circuit
beside :: Circuit -> Circuit -> Circuit

--BEGIN_DESUGAR
data Circuit2 = Circuit2 {
  width2   :: Int,
  desugar2 :: Circuit2
}
id2 n = Circuit2 {
  width2   = n,
  desugar2 = foldr1 beside $ replicate n (fan 1)
}
fan2 n = Circuit2 {
  width2   = n,
  desugar2 = fan n
}
beside2 c1 c2 = Circuit {
  width2   = width2 c1 + width2 c2,
  desugar2 = beside2 (desugar2 c1) (desugar2 c2)
}
--END_DESUGAR

