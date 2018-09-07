{-# OPTIONS -XTypeSynonymInstances -XFlexibleInstances -XTypeOperators -XMultiParamTypeClasses -XFlexibleContexts -XOverlappingInstances #-}
import Prelude hiding (id)

class Circuit c where
  id       ::  Int -> c
  fan      ::  Int -> c
  above    ::  c -> c -> c
  beside   ::  c -> c -> c
  stretch  ::  [Int] -> c -> c

newtype Width = Width {width :: Int}

instance Circuit Width where
  id n          =  Width n
  fan n         =  Width n
  above c1 c2   =  Width (width c1)
  beside c1 c2  =  Width (width c1 + width c2)
  stretch ns c  =  Width (sum ns)

newtype Depth = Depth {depth :: Int}

instance Circuit Depth where
  id n           =  Depth 0
  fan n          =  Depth 1
  above c1 c2    =  Depth (depth c1 + depth c2)
  beside c1 c2   =  Depth (depth c1 `max` depth c2)
  stretch ns c   =  Depth (depth c)

newtype WellSized  = WellSized {wellSized :: Bool}

type Compose i1 i2 = (i1, i2)

class a :<: b where
  inter :: b -> a

instance a :<: a where
  inter = \x -> x

instance a :<: (Compose a b) where
  inter = fst

instance (c :<: b) => c :<: (Compose a b) where
  inter = inter . snd


instance (Circuit width, Width :<: width) =>
          Circuit (Compose WellSized width) where
   id  n         =  (WellSized True, id n)
   fan n         =  (WellSized True, fan n)
   above c1 c2   =  (WellSized (gwellSized c1 && gwellSized c2 && gwidth c1 == gwidth c2)
                    ,above (inter c1) (inter c2))
   beside c1 c2  =  (WellSized (gwellSized c1 && gwellSized c2)
                    ,beside (inter c1) (inter c2))
   stretch ns c  =  (WellSized (gwellSized c && length ns == gwidth c)
                    ,stretch ns (inter c))

class Circuit c => ExtendedCircuit c where
  rstretch :: [Int] -> c -> c

instance ExtendedCircuit Width where
  rstretch = stretch

gwidth :: (Width :<: e) => e -> Int
gwidth = width . inter

gdepth :: (Depth :<: e) => e -> Int
gdepth = depth . inter

gwellSized :: (WellSized :<: e) => e -> Bool
gwellSized = wellSized . inter

circuit :: Circuit c => c
circuit = (fan 2 `beside` fan 2) `above`
     stretch [2,2] (fan 2) `above`
     (id 1 `beside` fan 2 `beside` id 1)

instance (Circuit i1, Circuit i2) => Circuit (Compose i1 i2) where
  id n         = (id n, id n)
  fan n        = (fan n, fan n)
  above c1 c2  = (above (inter c1) (inter c2), above (inter c1) (inter c2))
  beside c1 c2 = (beside (inter c1) (inter c2), beside (inter c1) (inter c2))
  stretch xs c = (stretch xs (inter c), stretch xs (inter c))

v1 = width (circuit :: Width)
v2 = depth (circuit :: Depth)
v3 = gwellSized (circuit :: Compose WellSized Width)

circuit' = circuit :: Compose Depth (Compose WellSized Width)
u1 = gwidth circuit'
u2 = gdepth circuit'
u3 = gwellSized circuit'
