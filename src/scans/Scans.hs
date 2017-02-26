identity      ::  Int -> Circuit
fan           ::  Int -> Circuit
beside        ::  Circuit -> Circuit -> Circuit
above         ::  Circuit -> Circuit -> Circuit
stretch       ::  [Int] -> Circuit -> Circuit

type Circuit   =  Int
identity n     =  n
fan n          =  n
beside c1 c2   =  c1 + c2
above c1 c2    =  c1
stretch ns c   =  sum ns

c  =  ( fan 2 `beside` fan 2) `above`
      stretch [2,2] (fan 2) `above`
      (identity 1 `beside` fan 2 `beside` identity 1)

newtype Circuit1   =  Circuit1 {width1  ::  Int}
identity1 n        =  Circuit1 {width1  =   n}
fan1 n             =  Circuit1 {width1  =   n}
beside1 c1 c2      =  Circuit1 {width1  =   width1 c1 + width1 c2}
above1 c1 c2       =  Circuit1 {width1  =   width1 c1}
stretch1 ns c      =  Circuit1 {width1  =   sum ns}

type Circuit2  =  (Int,Int)
identity2 n    =  (n,0)
fan2 n         =  (n,1)
above2 c1 c2   =  (width c1,depth c1 + depth c2)
beside2 c1 c2  =  (width c1 + width c2, depth c1 `max` depth c2)
stretch2 ns c  =  (sum ns,depth c)

width  =  fst
depth  =  snd

type Circuit3  =  (Int,Bool)
identity3 n    =  (n,True)
fan3 n         =  (n,True)
above3 c1 c2   =  (width c1,wellSized c1 && wellSized c2 && width c1==width c2)
beside3 c1 c2  =  (width c1 + width c2,wellSized c1 && wellSized c2)
stretch3 ns c  =  (sum ns,wellSized c && length ns==width c)

wellSized  =  snd

type Layout    =  [[(Int, Int)]]
type Circuit4  =  (Int,(Int -> Int) -> Layout)
identity4 n    =  (n,\f -> [])
fan4 n         =  (n,\f -> [[(f 0,f j) | j <- [1..n-1]]])
above4 c1 c2   =  (width c1,\f -> tlayout c1 f ++ tlayout c2 f)
beside4 c1 c2  =  (width c1 + width c2,\f -> lzw (++) (tlayout c1 f) (tlayout c2 (f . (width c1+))))
stretch4 ns c  =  (sum ns,\f -> tlayout c (f . pred . (vs !!)))
  where vs = scanl1 (+) ns

lzw                      ::  (a -> a -> a) -> [a] -> [a] -> [a]
lzw f [ ] ys             =  ys
lzw f xs [ ]             =  xs
lzw f (x : xs) (y : ys)  =  f x y : lzw f xs ys

tlayout =  snd

rstretch        ::  [Int] -> Circuit4 -> Circuit4
rstretch  ns c  =   stretch4 (1 : init ns) c `beside4` identity4 (last ns - 1)
