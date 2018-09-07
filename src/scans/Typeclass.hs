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
  beside c1 c2  =  Width (width c1 + width c2)
  above c1 c2   =  Width (width c1)
  stretch ns c  =  Width (sum ns)

newtype Depth = Depth {depth :: Int}

instance Circuit Depth where
  id n           =  Depth n
  fan n          =  Depth n
  beside c1 c2   =  Depth (depth c1 + depth c2)
  above c1 c2    =  Depth (depth c1 `max` depth c2)
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

c1 :: Circuit c => c
c1 = (fan 2 `beside` fan 2) `above`
     stretch [2,2] (fan 2) `above`
     (id 1 `beside` fan 2 `beside` id 1)


v1 = width (c1 :: Width)
v2 = gwellSized (c1 :: Compose WellSized Width)
