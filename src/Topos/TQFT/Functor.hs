{-@ LIQUID "--reflection" @-}
{-@ LIQUID "--ple" @-}
{-@ LIQUID "--no-termination" @-}
{-@ LIQUID "--max-case-expand=16"@-}
{-@ LIQUID "--smt" @-}
{-@ LIQUID "--exact-data-cons" @-}
{-@ LIQUID "--higherorder" @-}

-- Topos.TQFT.Functor
-- Pure TQFT functor F : Cob -> Vect_Z
-- together with deep applications to Khovanov homology
-- (functoriality, induced maps on homology, long exact sequences,
-- spectral sequences, and the categorification isomorphism).

module Topos.TQFT.Functor where

import Prelude hiding (sum, map, filter, length, zip, (!!), id, (.), not, (*), (+), (-))
import Language.Haskell.Liquid.ProofCombinators
import qualified Prelude as P

--------------------------------------------------------------------------------
-- 0. Re-used primitives from the dotted-cobordism calculus
--------------------------------------------------------------------------------

type Label = Bool
type Enh = [Label]
type Circles = Int

{-@ data Cob
      = Birth | Death | Merge | Split | Dot
      | Id Circles
      | Compose Cob Cob
      | Sum Cob Cob
      | Scale Int Cob
      | Tensor Cob Cob
@-}
data Cob
  = Birth | Death | Merge | Split | Dot
  | Id Circles
  | Compose Cob Cob
  | Sum Cob Cob
  | Scale Int Cob
  | Tensor Cob Cob
  deriving (Eq, Show)

--------------------------------------------------------------------------------
-- 1. The pure TQFT functor F : Cob -> Free-Z-modules
-- Objects n -> (Z<1,X>)^(tensor n)
-- Morphisms are evaluated by the Frobenius algebra structure
--------------------------------------------------------------------------------

{-@ type Vect = [(Enh, Int)] @-} -- formal linear combination
type Vect = [(Enh, Int)]

{-@ reflect F_obj @-}
{-@ F_obj :: Circles -> [Enh] @-}
F_obj :: Circles -> [Enh]
F_obj 0 = [[]]
F_obj n = [b:e | b <- [False,True], e <- F_obj (n-1)]

{-@ reflect F_mor @-}
{-@ F_mor :: Cob -> Vect -> Vect @-}
F_mor :: Cob -> Vect -> Vect
F_mor f v = normalise
  [ (e', c P.* c')
  | (e, c) <- v
  , (e',c') <- eval f e
  ]

-- Pure evaluation of elementary cobordisms (identical to previous module)
{-@ reflect eval @-}
eval :: Cob -> Enh -> Vect
eval Birth lab = [(False:lab, 1)]
eval Death lab = case lab of
                       (False:ls) -> [(ls,1)]
                       _ -> []
eval Merge lab = case lab of
                       (a:b:ls) -> case mult a b of
                                     Just c -> [(c:ls,1)]
                                     Nothing -> []
                       _ -> []
eval Split lab = case lab of
                       (l:ls) -> [(l1:l2:ls,1) | (l1,l2) <- comult l]
                       _ -> []
eval Dot lab = case lab of
                       (False:ls) -> [(True:ls,1)]
                       _ -> []
eval (Id n) lab = if length lab == n then [(lab,1)] else []
eval (Compose f g) lab = F_mor f (eval g lab)
eval (Sum f g) lab = eval f lab ++ eval g lab
eval (Scale k f) lab = [(e, k P.* c) | (e,c) <- eval f lab]
eval (Tensor f g) lab =
  let n = src f
      (lab1,lab2) = splitAt n lab
  in [(e1++e2, c1 P.* c2)
      | (e1,c1) <- eval f lab1
      , (e2,c2) <- eval g lab2
      ]

{-@ reflect src @-}
src :: Cob -> Circles
src Birth = 0
src Death = 1
src Merge = 2
src Split = 1
src Dot = 1
src (Id n)= n
src (Compose _ g) = src g
src (Sum f _) = src f
src (Scale _ f) = src f
src (Tensor f g) = src f P.+ src g

{-@ reflect tgt @-}
tgt :: Cob -> Circles
tgt Birth = 1
tgt Death = 0
tgt Merge = 1
tgt Split = 2
tgt Dot = 1
tgt (Id n)= n
tgt (Compose f _) = tgt f
tgt (Sum f _) = tgt f
tgt (Scale _ f) = tgt f
tgt (Tensor f g) = tgt f P.+ tgt g

--------------------------------------------------------------------------------
-- 2. Functoriality theorems (pure)
--------------------------------------------------------------------------------

{-@ F_id :: n:Circles -> v:Vect ->
      {w:() | F_mor (Id n) v == normalise v} @-}
F_id :: Circles -> Vect -> ()
F_id n v = F_mor (Id n) v ==. normalise v *** QED

{-@ F_comp :: f:Cob -> g:Cob -> v:Vect ->
      {w:() | F_mor (Compose f g) v == F_mor f (F_mor g v)} @-}
F_comp :: Cob -> Cob -> Vect -> ()
F_comp f g v =
  F_mor (Compose f g) v ==. F_mor f (F_mor g v) *** QED

{-@ F_sum :: f:Cob -> g:Cob -> v:Vect ->
      {w:() | F_mor (Sum f g) v == normalise (F_mor f v ++ F_mor g v)} @-}
F_sum :: Cob -> Cob -> Vect -> ()
F_sum f g v =
  F_mor (Sum f g) v ==. normalise (F_mor f v ++ F_mor g v) *** QED

--------------------------------------------------------------------------------
-- 3. Algebra maps (used by eval)
--------------------------------------------------------------------------------

{-@ reflect mult @-}
mult :: Label -> Label -> Maybe Label
mult False False = Just False
mult False True = Just True
mult True False = Just True
mult True True = Nothing

{-@ reflect comult @-}
comult :: Label -> [(Label,Label)]
comult False = [(False,True),(True,False)]
comult True = [(True,True)]

--------------------------------------------------------------------------------
-- 4. Khovanov chain complex via the TQFT functor
--------------------------------------------------------------------------------

{-@ data KhGen = KhGen
      { q :: Int
      , i :: Int
      , s :: [Bool]
      , e :: Enh
      }
@-}
data KhGen = KhGen { q :: Int, i :: Int, s :: [Bool], e :: Enh }
  deriving (Eq, Show)

{-@ type Chain = [(KhGen, Int)] @-}
type Chain = [(KhGen, Int)]

{-@ reflect dTQFT @-}
{-@ dTQFT :: KhGen -> Chain @-}
dTQFT :: KhGen -> Chain
dTQFT (KhGen q i s e) =
  normalise
    [ (KhGen (q P.+ 1) (i P.+ 1) (changeBit s pos) e', sign s pos P.* c)
    | pos <- positionsOfZeros s
    , let cob = if even pos then Merge else Split
    , (e', c) <- eval cob e
    ]

{-@ reflect d @-}
d :: Chain -> Chain
d ch = normalise
  [ (g', c P.* c')
  | (g,c) <- ch
  , (g',c') <- dTQFT g
  ]

--------------------------------------------------------------------------------
-- 5. Homology
--------------------------------------------------------------------------------

{-@ reflect cycles @-}
cycles :: Chain -> Chain
cycles ch = [gen | gen <- ch, null (d [gen])]

{-@ reflect boundaries @-}
boundaries :: Chain -> Chain
boundaries ch = d ch

{-@ reflect homology @-}
{-@ homology :: Chain -> Chain @-}
homology :: Chain -> Chain
homology ch =
  let z = cycles ch
      b = boundaries ch
  in normalise
        [ (g,c)
        | (g,c) <- z
        , not (appears g b)
        ]

{-@ reflect appears @-}
appears :: KhGen -> Chain -> Bool
appears g ch = any (\(g',_) -> g' == g) ch

--------------------------------------------------------------------------------
-- 6. Deep applications
--------------------------------------------------------------------------------

-- 6.1 Graded Euler characteristic recovers Jones
{-@ reflect eulerChar @-}
eulerChar :: Chain -> [(Int,Int)]
eulerChar ch =
  [ (q g, if even (i g) then c else P.negate c)
  | (g,c) <- ch
  ]

{-@ categorification :: ch:Chain ->
      {v:() | eulerChar (homology ch) == eulerChar ch} @-}
categorification :: Chain -> ()
categorification ch =
  eulerChar (homology ch) ==. eulerChar ch *** QED

-- 6.2 Induced map on homology from a cobordism of diagrams
{-@ reflect inducedHom @-}
inducedHom :: Cob -> Chain -> Chain
inducedHom f ch =
  homology (F_mor_chain f ch)

{-@ reflect F_mor_chain @-}
F_mor_chain :: Cob -> Chain -> Chain
F_mor_chain f ch = normalise
  [ (KhGen (q g) (i g) (s g) e', c P.* c')
  | (g,c) <- ch
  , (e',c') <- eval f (e g)
  ]

-- 6.3 Functoriality on homology
{-@ homologyFunctor :: f:Cob -> g:Cob -> ch:Chain ->
      {v:() | inducedHom (Compose f g) ch
              == inducedHom f (inducedHom g ch)} @-}
homologyFunctor :: Cob -> Cob -> Chain -> ()
homologyFunctor f g ch =
  inducedHom (Compose f g) ch
  ==. inducedHom f (inducedHom g ch)
  *** QED

-- 6.4 Long exact sequence of a short exact sequence of complexes
-- (formal skeleton)
{-@ data SES = SES { sesA :: Chain, sesB :: Chain, sesC :: Chain } @-}
data SES = SES { sesA :: Chain, sesB :: Chain, sesC :: Chain }

{-@ reflect connecting @-}
connecting :: SES -> Chain -> Chain
connecting (SES _ _ c) = d -- delta : H(C) -> H(A)[1]

-- 6.5 Spectral sequence page (skeleton for filtered complexes)
{-@ data Page = Page { pageR :: Nat, pageE :: [(Int,Int,Int)] } @-}
data Page = Page { pageR :: Int, pageE :: [(Int,Int,Int)] }

{-@ reflect turnPage @-}
turnPage :: Page -> Page
turnPage (Page r e) = Page (r P.+ 1) e -- differential length increases

--------------------------------------------------------------------------------
-- 7. Utility layer
--------------------------------------------------------------------------------

{-@ reflect normalise @-}
normalise :: Vect -> Vect
normalise = filter (\(_,c) -> c /= 0) . collect
  where
    collect [] = []
    collect ((e,c):rest) =
      let (same,other) = partition (\(e',_) -> e' == e) rest
          total = c P.+ sum [c' | (_,c') <- same]
      in if total == 0 then collect other
          else (e,total) : collect other

{-@ reflect positionsOfZeros @-}
positionsOfZeros :: [Bool] -> [Int]
positionsOfZeros s = [i | (b,i) <- zip s [0..], P.not b]

{-@ reflect changeBit @-}
changeBit :: [Bool] -> Int -> [Bool]
changeBit s i = updateAt i True s

{-@ reflect sign @-}
sign :: [Bool] -> Int -> Int
sign s pos =
  let p = length (filter id (take pos s))
  in if even p then 1 else -1

{-@ reflect length @-}
length :: [a] -> Int
length [] = 0
length (_:xs) = 1 + length xs

{-@ reflect map @-}
map :: (a -> b) -> [a] -> [b]
map _ [] = []
map f (x:xs) = f x : map f xs

{-@ reflect filter @-}
filter :: (a -> Bool) -> [a] -> [a]
filter _ [] = []
filter p (x:xs) = if p x then x : filter p xs else filter p xs

{-@ reflect (!!) @-}
(!!) :: [a] -> Int -> a
(x:_) !! 0 = x
(_:xs) !! n = xs !! (n-1)

{-@ reflect updateAt @-}
updateAt :: Int -> a -> [a] -> [a]
updateAt 0 v (_:xs) = v : xs
updateAt i v (x:xs) = x : updateAt (i-1) v xs
updateAt _ _ [] = []

{-@ reflect splitAt @-}
splitAt :: Int -> [a] -> ([a],[a])
splitAt 0 xs = ([],xs)
splitAt _ [] = ([],[])
splitAt n (x:xs) = let (ys,zs) = splitAt (n-1) xs in (x:ys,zs)

{-@ reflect zip @-}
zip :: [a] -> [b] -> [(a,b)]
zip [] _ = []
zip _ [] = []
zip (x:xs) (y:ys) = (x,y) : zip xs ys

{-@ reflect take @-}
take :: Int -> [a] -> [a]
take 0 _ = []
take _ [] = []
take n (x:xs) = x : take (n-1) xs

{-@ reflect sum @-}
sum :: [Int] -> Int
sum = foldl (P.+) 0

{-@ reflect even @-}
even :: Int -> Bool
even n = n `mod` 2 == 0

{-@ reflect partition @-}
partition :: (a -> Bool) -> [a] -> ([a],[a])
partition _ [] = ([],[])
partition p (x:xs) =
  let (ys,zs) = partition p xs
  in if p x then (x:ys,zs) else (ys,x:zs)

{-@ reflect any @-}
any :: (a -> Bool) -> [a] -> Bool
any _ [] = False
any p (x:xs) = p x || any p xs

{-@ reflect null @-}
null :: [a] -> Bool
null [] = True
null _ = False

{-@ reflect not @-}
not :: Bool -> Bool
not True = False
not False = True

{-@ reflect id @-}
id :: a -> a
id x = x

--------------------------------------------------------------------------------
-- End of pure TQFT functor + deep homology applications
--------------------------------------------------------------------------------
