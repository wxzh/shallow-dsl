--BEGIN_SEMANTICS_HS
identity n = (n,True)
fan n = (n,True)
beside c1 c2 = 
  (width c1 + width c2,wellSized c1 && wellSized c2)

width = fst
wellSized = snd
--END_SEMANTICS_HS
