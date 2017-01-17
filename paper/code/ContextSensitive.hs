--BEGIN_TLAYOUT_HS
lzw::(a -> a -> a) -> [a] -> [a] -> [a]
lzw f [ ] ys            = ys
lzw f xs [ ]            = xs
lzw f (x : xs) (y : ys) = f x y : lzw f xs ys

type Layout = [[(Int, Int)]]
type Circuit = (Int,(Int -> Int) -> Layout)
id n         = (n,\f -> [])
fan n        = (n,\f -> [[(f 0,f j) | j <- [1..n-1]]])
above c1 c2  = (width c1,\f -> tlayout c1 f ++ tlayout c2 f)
beside c1 c2 = (width c1 + width c2
               ,\f -> lzw (++) (tlayout c1 f) (tlayout c2 ((width c1+) . f)))
stretch ns c = (sum ns,\f -> tlayout c (pred . (vs!!) . f))
  where vs = scanl1 (+) ns

width  = fst
tlayout = snd
--END_TLAYOUT_HS
