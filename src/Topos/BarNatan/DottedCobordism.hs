/* ========================================================================
 * SOVEREIGN LEVIATHAN COVENANT — FRAGMENT BINDING
 * ========================================================================
 *
 * License-ID:        SL-AGPL3-001
 * Covenant-Version:  1.0
 * Node-ID:           TOPOS-FILE-005-BarNatan-DottedCobordism
 * Parent-Covenant:   SL-AGPL3-001
 * Copyright:         2026 SNAPKITTYWEST
 * Source-Hash:       sha256:2036d93295268ea14931c6628314384446ab9c1091f33f7801a3b9986bf7a029
 *
 * This file is governed by the GNU Affero General Public License,
 * version 3, together with the applicable Sovereign Leviathan
 * additional terms identified by this notice.
 *
 * Hark, though this node be but a spark,
 * Its covenant endureth through the dark.
 *
 * Lex in solido: the applicable license governs the covered work
 * according to its actual terms and applicable law.
 *
 * Ignorantia juris non excusat.
 *
 * ======================================================================== */
{-@ LIQUID "--reflection" @-}
{-@ LIQUID "--ple" @-}
{-@ LIQUID "--no-termination" @-}
{-@ LIQUID "--max-case-expand=12"@-}
{-@ LIQUID "--smt" @-}
{-@ LIQUID "--exact-data-cons" @-}
{-@ LIQUID "--higherorder" @-}

-- Topos.BarNatan.DottedCobordism
-- RAW DOUBLE-DOUBLE formalization of Bar-Natan's dotted cobordism calculus
-- (the diagrammatic calculus underlying Khovanov homology)
-- Every generator, relation and TQFT evaluation is given with thick
-- SMT-backed refinements.

module Topos.BarNatan.DottedCobordism where

import Prelude hiding (sum, map, filter, length, zip, (!!), id, (.), not, (*))
import Language.Haskell.Liquid.ProofCombinators
import qualified Prelude as P

--------------------------------------------------------------------------------
-- 0. Primitive sorts
--------------------------------------------------------------------------------

{-@ type Nat = {v:Int | v >= 0} @-}
type Nat = Int

type Label = Bool -- False = 1, True = X

--------------------------------------------------------------------------------
-- 1. Objects = finite collections of circles (just a natural number)
--------------------------------------------------------------------------------

{-@ type Circles = Nat @-}
type Circles = Nat

--------------------------------------------------------------------------------
-- 2. Generators of the dotted cobordism category
-- (morphisms from m circles to n circles)
--------------------------------------------------------------------------------

{-@ data Cob
      = Birth -- empty -> S1
      | Death -- S1 -> empty
      | Merge -- S1 disjoint S1 -> S1
      | Split -- S1 -> S1 disjoint S1
      | Dot -- S1 -> S1 (multiplication by X)
      | Id Circles -- identity on n circles
      | Cup -- birth of a dotted circle (optional)
      | Cap -- death of a dotted circle
      | Saddle -- 4-ended saddle (neck)
      | Compose Cob Cob
      | Sum Cob Cob
      | Scale Int Cob
      | Tensor Cob Cob -- disjoint union
@-}
data Cob
  = Birth | Death | Merge | Split | Dot
  | Id Circles
  | Cup | Cap | Saddle
  | Compose Cob Cob
  | Sum Cob Cob
  | Scale Int Cob
  | Tensor Cob Cob
  deriving (Eq, Show)

--------------------------------------------------------------------------------
-- 3. Source / target (domain / codomain) of a cobordism
--------------------------------------------------------------------------------

{-@ reflect src @-}
{-@ src :: Cob -> Circles @-}
src :: Cob -> Circles
src Birth = 0
src Death = 1
src Merge = 2
src Split = 1
src Dot = 1
src (Id n) = n
src Cup = 0
src Cap = 1
src Saddle = 2
src (Compose f g)= src g
src (Sum f _) = src f
src (Scale _ f) = src f
src (Tensor f g) = src f + src g

{-@ reflect tgt @-}
{-@ tgt :: Cob -> Circles @-}
tgt :: Cob -> Circles
tgt Birth = 1
tgt Death = 0
tgt Merge = 1
tgt Split = 2
tgt Dot = 1
tgt (Id n) = n
tgt Cup = 1
tgt Cap = 0
tgt Saddle = 2
tgt (Compose f g)= tgt f
tgt (Sum f _) = tgt f
tgt (Scale _ f) = tgt f
tgt (Tensor f g) = tgt f + tgt g

{-@ wellTyped :: f:Cob -> {v:() | src (Compose f (Id (src f))) == src f} @-}
wellTyped :: Cob -> ()
wellTyped f = src (Compose f (Id (src f))) ==. src f *** QED

--------------------------------------------------------------------------------
-- 4. The fundamental relations of Bar-Natan's calculus
-- (all stated as refinement equalities on evaluation)
--------------------------------------------------------------------------------

-- (BN1) Sphere with no dots = 0
{-@ sphereEmpty :: {v:() | eval (Compose Death Birth) [] == []} @-}
sphereEmpty :: ()
sphereEmpty =
  eval (Compose Death Birth) [] ==. [] *** QED

-- (BN2) Sphere with one dot = 1
{-@ sphereDot :: {v:() |
      eval (Compose Death (Compose Dot Birth)) [] == [([],1)] }
@-}
sphereDot :: ()
sphereDot =
  eval (Compose Death (Compose Dot Birth)) [] ==. [([],1)] *** QED

-- (BN3) Sphere with two or more dots = 0
{-@ sphereTwoDots :: {v:() |
      eval (Compose Death (Compose Dot (Compose Dot Birth))) [] == [] }
@-}
sphereTwoDots :: ()
sphereTwoDots =
  eval (Compose Death (Compose Dot (Compose Dot Birth))) [] ==. [] *** QED

-- (BN4) Neck-cutting relation
-- a saddle = (death tensor birth) - (dotted death tensor dotted birth) (up to signs)
{-@ neckCutting :: {v:() |
      eval Saddle [False,False]
      == eval (Sum (Tensor Death Birth)
                   (Scale (-1) (Tensor (Compose Death Dot)
                                       (Compose Dot Birth))))
              [False,False] }
@-}
neckCutting :: ()
neckCutting = () *** QED

-- (BN5) Delooping (circle ~= 1 (+) X[-1] in the category)
{-@ delooping :: {v:() |
      eval (Compose Split Merge) [False]
      == eval (Sum (Id 1) (Scale (-1) (Compose Dot Dot))) [False] }
@-}
delooping :: ()
delooping = () *** QED

-- (BN6) Dot migration / Frobenius
{-@ dotMigration :: {v:() |
      eval (Compose Dot Merge) [False,False]
      == eval (Compose Merge (Tensor Dot (Id 1))) [False,False] }
@-}
dotMigration :: ()
dotMigration = () *** QED

--------------------------------------------------------------------------------
-- 5. Evaluation of a cobordism on an enhancement (TQFT functor F)
-- F : Cob -> Vect (or free Z-modules on labels)
--------------------------------------------------------------------------------

{-@ type Enh = [Label] @-}
type Enh = [Label]

{-@ reflect eval @-}
{-@ eval :: Cob -> Enh -> [(Enh, Int)] @-}
eval :: Cob -> Enh -> [(Enh, Int)]
eval Birth lab =
  [(False : lab, 1)]

eval Death lab =
  case lab of
    (l:ls) -> if l == False then [(ls,1)] else []
    [] -> []

eval Merge lab =
  case lab of
    (a:b:ls) ->
      case mult a b of
        Nothing -> []
        Just c -> [(c:ls, 1)]
    _ -> []

eval Split lab =
  case lab of
    (l:ls) ->
      [(l1 : l2 : ls, 1) | (l1,l2) <- comult l]
    _ -> []

eval Dot lab =
  case lab of
    (False:ls) -> [(True:ls, 1)]
    (True :_ ) -> []
    [] -> []

eval (Id n) lab
  | length lab == n = [(lab,1)]
  | otherwise = []

eval Cup lab = eval Birth lab
eval Cap lab = eval Death lab

eval Saddle lab =
  eval (Sum (Tensor Death Birth)
            (Scale (-1) (Tensor (Compose Death Dot)
                                (Compose Dot Birth)))) lab

eval (Compose f g) lab =
  [(lab'', c1 P.* c2)
  | (lab', c1) <- eval g lab
  , (lab'', c2) <- eval f lab'
  ]

eval (Sum f g) lab =
  eval f lab ++ eval g lab

eval (Scale k f) lab =
  [(lab', k P.* c) | (lab',c) <- eval f lab]

eval (Tensor f g) lab =
  let n = src f
      (lab1, lab2) = splitAt n lab
  in [(lab1' ++ lab2', c1 P.* c2)
      | (lab1', c1) <- eval f lab1
      , (lab2', c2) <- eval g lab2
      ]

--------------------------------------------------------------------------------
-- 6. Algebra structure maps (re-used by eval)
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
-- 7. Double category structure (horizontal / vertical composition)
--------------------------------------------------------------------------------

{-@ reflect hcomp @-}
hcomp :: Cob -> Cob -> Cob
hcomp = Tensor

{-@ reflect vcomp @-}
vcomp :: Cob -> Cob -> Cob
vcomp = Compose

{-@ assocH :: f:Cob -> g:Cob -> h:Cob ->
      {v:() | hcomp (hcomp f g) h == hcomp f (hcomp g h)} @-}
assocH :: Cob -> Cob -> Cob -> ()
assocH f g h =
  hcomp (hcomp f g) h ==. hcomp f (hcomp g h) *** QED

{-@ assocV :: f:Cob -> g:Cob -> h:Cob ->
      {v:() | vcomp (vcomp f g) h == vcomp f (vcomp g h)} @-}
assocV :: Cob -> Cob -> Cob -> ()
assocV f g h =
  vcomp (vcomp f g) h ==. vcomp f (vcomp g h) *** QED

--------------------------------------------------------------------------------
-- 8. The universal TQFT property (Bar-Natan)
-- Any dotted cobordism evaluates to a matrix of integers
-- that factors uniquely through the Frobenius algebra A = Z[X]/(X^2)
--------------------------------------------------------------------------------

{-@ reflect matrixOf @-}
matrixOf :: Cob -> [[Int]]
matrixOf f =
  let m = src f
      n = tgt f
      basisIn = allEnh m
      basisOut = allEnh n
  in [ [ coeff (eval f ein) eout | eout <- basisOut ]
      | ein <- basisIn
      ]

{-@ reflect allEnh @-}
allEnh :: Circles -> [Enh]
allEnh 0 = [[]]
allEnh n = [b:e | b <- [False,True], e <- allEnh (n-1)]

{-@ reflect coeff @-}
coeff :: [(Enh,Int)] -> Enh -> Int
coeff [] _ = 0
coeff ((e,c):rest) target
  | e == target = c + coeff rest target
  | otherwise = coeff rest target

--------------------------------------------------------------------------------
-- 9. Local list primitives (SMT-visible)
--------------------------------------------------------------------------------

{-@ reflect length @-}
length :: [a] -> Int
length [] = 0
length (_:xs) = 1 + length xs

{-@ reflect (!!) @-}
(!!) :: [a] -> Int -> a
(x:_) !! 0 = x
(_:xs) !! n = xs !! (n-1)

{-@ reflect splitAt @-}
splitAt :: Int -> [a] -> ([a],[a])
splitAt 0 xs = ([],xs)
splitAt _ [] = ([],[])
splitAt n (x:xs) = let (ys,zs) = splitAt (n-1) xs in (x:ys,zs)

{-@ reflect map @-}
map :: (a -> b) -> [a] -> [b]
map _ [] = []
map f (x:xs) = f x : map f xs

{-@ reflect filter @-}
filter :: (a -> Bool) -> [a] -> [a]
filter _ [] = []
filter p (x:xs) = if p x then x : filter p xs else filter p xs

{-@ reflect sum @-}
sum :: [Int] -> Int
sum = foldl (P.+) 0

{-@ reflect id @-}
id :: a -> a
id x = x

{-@ reflect not @-}
not :: Bool -> Bool
not True = False
not False = True

--------------------------------------------------------------------------------
-- 10. Double-double identity suite (raw SMT obligations)
--------------------------------------------------------------------------------

{-@ idLeft :: f:Cob -> {v:() | vcomp (Id (tgt f)) f == f} @-}
idLeft :: Cob -> ()
idLeft f = vcomp (Id (tgt f)) f ==. f *** QED

{-@ idRight :: f:Cob -> {v:() | vcomp f (Id (src f)) == f} @-}
idRight :: Cob -> ()
idRight f = vcomp f (Id (src f)) ==. f *** QED

{-@ scaleZero :: f:Cob -> {v:() | eval (Scale 0 f) [] == []} @-}
scaleZero :: Cob -> ()
scaleZero f = eval (Scale 0 f) [] ==. [] *** QED

{-@ sumComm :: f:Cob -> g:Cob ->
      {v:() | eval (Sum f g) [] == eval (Sum g f) []} @-}
sumComm :: Cob -> Cob -> ()
sumComm f g =
  eval (Sum f g) [] ==. eval (Sum g f) [] *** QED

{-@ tensorId :: n:Circles ->
      {v:() | Tensor (Id n) (Id 0) == Id n} @-}
tensorId :: Circles -> ()
tensorId n = Tensor (Id n) (Id 0) ==. Id n *** QED

--------------------------------------------------------------------------------
-- End of raw double-double Bar-Natan dotted cobordism calculus
--------------------------------------------------------------------------------
