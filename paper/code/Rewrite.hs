--BEGIN_CIRCUIT3
newtype Circuit = Circuit {width :: Int}
id n         = Circuit {width = n}
fan n        = Circuit {width = n}
beside c1 c2 = Circuit {width = width c1 + width c2}
--END_CIRCUIT3
