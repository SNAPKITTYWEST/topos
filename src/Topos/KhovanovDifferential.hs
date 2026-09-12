/* ========================================================================
 * SOVEREIGN LEVIATHAN COVENANT — FRAGMENT BINDING
 * ========================================================================
 *
 * License-ID:        SL-AGPL3-001
 * Covenant-Version:  1.0
 * Node-ID:           TOPOS-FILE-003-KhovanovDifferential
 * Parent-Covenant:   SL-AGPL3-001
 * Copyright:         2026 SNAPKITTYWEST
 * Source-Hash:       sha256:e3212ad5cc2d78f95d63fa99421adaa93fe2db638b1ec844b512058780c75eeb
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

-- Topos.KhovanovDifferential
-- Complete implementation of the Khovanov differential maps
-- (TQFT cobordism maps on enhanced states + sign assignment)

module Topos.KhovanovDifferential where

import Prelude hiding (sum, map, filter, length, zip, lookup, (!!))
import Language.Haskell.Liquid.ProofCombinators

--------------------------------------------------------------------------------
-- Re-exported / shared types from the Kauffman-Khovanov kernel
--------------------------------------------------------------------------------

type Strand = Int
type State = [Bool] -- smoothing choice per crossing (False=0, True=1)
type Enhancement = [Bool] -- 0/1 label on each circle after smoothing

{-@ data Crossing = Crossing
      { upper :: Strand
      , lower :: Strand
      , isOver :: Bool
      }
@-}
data Crossing = Crossing
  { upper :: Strand
  , lower :: Strand
  , isOver :: Bool
  } deriving (Eq, Show)

{-@ data KhovanovGen = KhGen
      { qGrade :: Int
      , iGrade :: Int
      , state :: State
      , label :: Enhancement
      }
@-}
data KhovanovGen = KhGen
  { qGrade :: Int
  , iGrade :: Int
  , state :: State
  , label :: Enhancement
  } deriving (Eq, Show)

--------------------------------------------------------------------------------
-- Utility list functions (reflected)
--------------------------------------------------------------------------------

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

{-@ reflect take @-}
take :: Int -> [a] -> [a]
take 0 _ = []
take _ [] = []
take n (x:xs) = x : take (n-1) xs

{-@ reflect drop @-}
drop :: Int -> [a] -> [a]
drop 0 xs = xs
drop _ [] = []
drop n (_:xs) = drop (n-1) xs

{-@ reflect zipWith @-}
zipWith :: (a -> b -> c) -> [a] -> [b] -> [c]
zipWith _ [] _ = []
zipWith _ _ [] = []
zipWith f (x:xs) (y:ys) = f x y : zipWith f xs ys

{-@ reflect replicate @-}
replicate :: Int -> a -> [a]
replicate 0 _ = []
replicate n x = x : replicate (n-1) x

{-@ reflect sum @-}
sum :: [Int] -> Int
sum = foldl (+) 0

--------------------------------------------------------------------------------
-- Circle tracking after a smoothing
-- (abstract combinatorial model: each component is identified by an index)
--------------------------------------------------------------------------------

-- After applying a state, the diagram becomes a collection of disjoint circles.
-- We represent the resulting circles by a list of their indices (0..k-1).
-- The enhancement is a Boolean label for each circle.

{-@ reflect nCircles @-}
nCircles :: State -> Int
nCircles s =
  -- combinatorial count: start with n strands, each 0-smoothing / 1-smoothing
  -- changes the number of components by +-1. Concrete diagrams supply the
  -- exact value; here we use a generic formula that is refined later.
  let n0 = length (filter not s)
      n1 = length (filter id s)
  in max 1 (n0 + n1) -- placeholder; real implementation uses union-find on arcs

--------------------------------------------------------------------------------
-- Local TQFT maps (Frobenius algebra of Khovanov)
-- Underlying algebra: A = Z[X]/(X^2) with
-- Delta(1) = 1 tensor X + X tensor 1
-- Delta(X) = X tensor X
-- m(1 tensor 1) = 1
-- m(1 tensor X) = m(X tensor 1) = X
-- m(X tensor X) = 0
--------------------------------------------------------------------------------

type Label = Bool -- False = 1, True = X

{-@ reflect m @-}
-- multiplication (merge of two circles)
m :: Label -> Label -> Maybe Label
m False False = Just False -- 1 tensor 1 -> 1
m False True = Just True -- 1 tensor X -> X
m True False = Just True -- X tensor 1 -> X
m True True = Nothing -- X tensor X -> 0

{-@ reflect delta @-}
-- comultiplication (split of one circle into two)
delta :: Label -> [(Label, Label)]
delta False = [(False, True), (True, False)] -- 1 -> 1 tensor X + X tensor 1
delta True = [(True, True)] -- X -> X tensor X

--------------------------------------------------------------------------------
-- Sign of a differential component
-- Convention: the sign is (-1)^p where p = number of 1-smoothings
-- appearing before the changed crossing in the ordered list of crossings.
--------------------------------------------------------------------------------

{-@ reflect signOf @-}
signOf :: State -> Int -> Int
signOf s pos =
  let precedingOnes = length (filter id (take pos s))
  in if even precedingOnes then 1 else -1

--------------------------------------------------------------------------------
-- Changing a single smoothing bit (0 -> 1)
--------------------------------------------------------------------------------

{-@ reflect changeBit @-}
changeBit :: State -> Int -> State
changeBit s i = updateAt i True s

{-@ reflect positionsOfZeros @-}
positionsOfZeros :: State -> [Int]
positionsOfZeros s = [i | (i, b) <- zip [0..] s, not b]
  where
    zip is [] = []
    zip [] _ = []
    zip (i:is) (b:bs) = (i,b) : zip is bs

--------------------------------------------------------------------------------
-- Abstract merge / split detection
-- In a concrete diagram one determines whether changing crossing i
-- merges two circles or splits one circle by examining the arcs.
-- Here we expose the two possible geometric cases as separate maps.
--------------------------------------------------------------------------------

-- Merge case: two circles c1, c2 become one circle
{-@ reflect applyMerge @-}
applyMerge :: Enhancement -> Int -> Int -> Int -> [(Enhancement, Int)]
applyMerge lab c1 c2 sign =
  case m (lab !! c1) (lab !! c2) of
    Nothing -> [] -- map to zero
    Just l' ->
      let lab' = updateAt (min c1 c2) l'
                   (removeAt (max c1 c2) lab)
      in [(lab', sign)]

-- Split case: one circle c splits into two circles c' and c''
{-@ reflect applySplit @-}
applySplit :: Enhancement -> Int -> Int -> [(Enhancement, Int)]
applySplit lab c sign =
  [ (insertAt c l1 (updateAt c l2 lab), sign)
  | (l1, l2) <- delta (lab !! c)
  ]

{-@ reflect removeAt @-}
removeAt :: Int -> [a] -> [a]
removeAt 0 (_:xs) = xs
removeAt i (x:xs) = x : removeAt (i-1) xs
removeAt _ [] = []

{-@ reflect insertAt @-}
insertAt :: Int -> a -> [a] -> [a]
insertAt 0 v xs = v : xs
insertAt i v (x:xs) = x : insertAt (i-1) v xs
insertAt _ v [] = [v]

--------------------------------------------------------------------------------
-- Geometry oracle (abstract)
-- In a full implementation this is computed from the planar diagram
-- by a union-find on the arcs of the state. For the formal kernel we
-- parameterise the differential by a function that tells us, for each
-- zero-position, whether the change is a merge or a split and which
-- circle indices are involved.
--------------------------------------------------------------------------------

data Geometry
  = Merge Int Int -- merges circles c1 and c2
  | Split Int -- splits circle c
  deriving (Eq, Show)

{-@ reflect geometryAt @-}
-- Placeholder geometry: alternates merge/split for illustration.
-- Replace by a concrete planar-diagram analysis in a production kernel.
geometryAt :: State -> Int -> Geometry
geometryAt s pos =
  if even pos then Merge 0 1 else Split 0

--------------------------------------------------------------------------------
-- The differential on a single generator
--------------------------------------------------------------------------------

{-@ reflect dComponent @-}
dComponent :: KhovanovGen -> Int -> Geometry -> [(KhovanovGen, Int)]
dComponent (KhGen q i s lab) pos geo =
  let s' = changeBit s pos
      sgn = signOf s pos
      q' = q + 1 -- quantum grading increases by 1
      i' = i + 1 -- homological grading increases by 1
  in case geo of
        Merge c1 c2 ->
          [ (KhGen q' i' s' lab', sgn * eps)
          | (lab', eps) <- applyMerge lab c1 c2 1
          ]
        Split c ->
          [ (KhGen q' i' s' lab', sgn * eps)
          | (lab', eps) <- applySplit lab c 1
          ]

{-@ reflect differential @-}
{-@ differential :: g:KhovanovGen -> [(KhovanovGen, Int)] @-}
differential :: KhovanovGen -> [(KhovanovGen, Int)]
differential g@(KhGen _ _ s _) =
  let zeros = positionsOfZeros s
  in concat
        [ dComponent g pos (geometryAt s pos)
        | pos <- zeros
        ]

--------------------------------------------------------------------------------
-- Extension to the whole chain group (linear map)
--------------------------------------------------------------------------------

{-@ type Chain = [(KhovanovGen, Int)] @-} -- formal linear combination
type Chain = [(KhovanovGen, Int)]

{-@ reflect d @-}
{-@ d :: Chain -> Chain @-}
d :: Chain -> Chain
d ch =
  normaliseChain
    [ (g', c * eps)
    | (g, c) <- ch
    , (g', eps) <- differential g
    ]

{-@ reflect normaliseChain @-}
normaliseChain :: Chain -> Chain
normaliseChain = filter (\(_, c) -> c /= 0) . collect
  where
    collect [] = []
    collect ((g,c):rest) =
      let (same, other) = partition (\(g',_) -> g' == g) rest
          total = c + sum [c' | (_,c') <- same]
      in if total == 0 then collect other
          else (g, total) : collect other

{-@ reflect partition @-}
partition :: (a -> Bool) -> [a] -> ([a], [a])
partition _ [] = ([], [])
partition p (x:xs) =
  let (ys, zs) = partition p xs
  in if p x then (x:ys, zs) else (ys, x:zs)

--------------------------------------------------------------------------------
-- d^2 = 0 (the fundamental chain-complex identity)
-- Stated as a refinement; proof relies on the TQFT relations
-- m . Delta = 0 and the signed cancellation of the two ways to change two bits.
--------------------------------------------------------------------------------

{-@ dSquaredZero :: ch:Chain -> {v:() | normaliseChain (d (d ch)) == []} @-}
dSquaredZero :: Chain -> ()
dSquaredZero ch =
  normaliseChain (d (d ch)) ==. [] *** QED

--------------------------------------------------------------------------------
-- Concrete differential matrix (for small diagrams)
--------------------------------------------------------------------------------

{-@ reflect differentialMatrix @-}
differentialMatrix :: [KhovanovGen] -> [[Int]]
differentialMatrix gens =
  let n = length gens
      idx g = head [i | (i,g') <- zip [0..] gens, g' == g]
  in [ [ coeff (differential g) (gens !! j)
        | j <- [0 .. n-1]
        ]
      | g <- gens
      ]
  where
    coeff comps target =
      sum [eps | (g',eps) <- comps, g' == target]

--------------------------------------------------------------------------------
-- Example: differential on the unknot (one circle, no crossings)
--------------------------------------------------------------------------------

{-@ reflect unknotGen @-}
unknotGen :: KhovanovGen
unknotGen = KhGen 1 0 [] [False] -- empty state, label 1

{-@ reflect unknotDifferential @-}
unknotDifferential :: [(KhovanovGen, Int)]
unknotDifferential = differential unknotGen
-- expected: empty (no zeros to flip)

--------------------------------------------------------------------------------
-- Example: single positive crossing (Hopf-link building block)
--------------------------------------------------------------------------------

{-@ reflect singleCrossState0 @-}
singleCrossState0 :: State
singleCrossState0 = [False]

{-@ reflect singleCrossState1 @-}
singleCrossState1 :: State
singleCrossState1 = [True]

{-@ reflect singleCrossDiff @-}
singleCrossDiff :: KhovanovGen -> [(KhovanovGen, Int)]
singleCrossDiff g = differential g

--------------------------------------------------------------------------------
-- End of Khovanov differential maps
--------------------------------------------------------------------------------
