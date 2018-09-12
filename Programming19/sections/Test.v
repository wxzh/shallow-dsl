Definition WS := fun A B => forall C, (forall (x : A), B x -> C) -> C.

Definition fst A B (x : WS A B) := x A (fun x p => x).

Definition MySet := WS Set (fun s => s -> bool).

Definition MkPair A B x t : WS A B := fun C => fun f => f x t.

Definition test := fst nat (fun s => nat) (MkPair nat (fun s => nat) 3 4).

(* Lets design a (more Haskell-like) language where we can write the above code 

newtype WS A B = Build (forall C, (forall (x : A), B x -> C) -> C)

-- fst : (A : Set) -> (B : A -> Set) -> WS A B -> A 
fst A B (Build x) = x A (\x p => x)

-- mkPair : (A : Set) -> (B : A -> Set) -> (x : A) -> B x -> WS A B  
mkPair A B x t = Build (\C f => f x t)

newtype K A B = K A

-- test : nat
test = fst nat (K nat) (mkPair nat (K nat) 3 (K 4))

*)



(* Definition K (B : Type) (A : Type) (x : A) := B. *)

(* Definition snd A B (x : WS A (K B A)) : B = x Type (fun x p => p). *)

Definition insert (x : Int) (s : MySet) : MySet := 


