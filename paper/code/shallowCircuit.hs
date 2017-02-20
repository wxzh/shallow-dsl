{-BEGIN_CIRCUIT_TYPE
type Circuit = ...
END_CIRCUIT_TYPE-}
--BEGIN_TYPES
id     :: Int -> Circuit
fan    :: Int -> Circuit
beside :: Circuit -> Circuit -> Circuit
--END_TYPES

--BEGIN_CIRCUIT1
type Circuit = Int
id n         = n
fan n        = n
beside c1 c2 = c1 + c2
--END_CIRCUIT1

--BEGIN_CIRCUIT2
newtype Circuit3 = Circuit3 Int
identity3 n                         = Circuit3 n
fan3 n                              = Circuit3 n
beside3 (Circuit3 c1) (Circuit3 c3) =
  Circuit3 $ c1 + c3

width3 :: Circuit3 -> Int
width3 (Circuit3 n) = n
--END_CIRCUIT2

--BEGIN_SYNTAX_TYPES
stretch :: [Int] -> Circuit -> Circuit
above   :: Circuit -> Circuit -> Circuit
--END_SYNTAX_TYPES

--BEGIN_SYNTAX_HS
stretch ns c = sum ns
above c1 c2  = c2
--END_SYNTAX_HS
