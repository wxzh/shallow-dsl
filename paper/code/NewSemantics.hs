--BEGIN_SEMANTICS_HS
identity n = (True,n)
fan n = (True,n)
beside c1 c2 = (fst c1 && fst c2,fst c1 + fst c2)
stretch ns c = (fst c && length ns == snd c)
above c1 c2 = (fst c1 && fst c2 && snd c1 == snd c2,snd c1)
--END_SEMANTICS_HS
