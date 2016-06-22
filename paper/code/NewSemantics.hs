--BEGIN_SEMANTICS_HS
type Circuit = (Int,Bool)
id n         = (n,n > 0)
fan n        = (n,n > 0)
beside c1 c2 = 
  (width c1 + width c2,wellSized c1 && wellSized c2)

width     = fst
wellSized = snd
--END_SEMANTICS_HS
