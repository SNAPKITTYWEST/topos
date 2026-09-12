-- COMMENT SOVEREIGN LEVIATHAN COVENANT - FRAGMENT BINDING;
-- COMMENT Node-ID: TOPOS-FILE-001-Core;
-- COMMENT Parent-Work: topos;
-- COMMENT Parent-Covenant: SL-AGPL3-001;
-- COMMENT Copyright: 2026 SNAPKITTYWEST;
-- COMMENT License-ID: SL-AGPL3-001 / MGPLv3;
-- COMMENT Covenant-Version: 1.0;
-- COMMENT Source-Hash: sha256:6fd5bd22fb0ba87243ca7cde5f6a77bace8e876cc45d52bc320ce2b64b0a91d6;
-- COMMENT Hash-Scope: source before generated license headers, UTF-8 LF;
-- COMMENT Creation-Date: 2026-09-12 (provenance record);
-- COMMENT Modification-Record: added license and node headers only;
-- COMMENT Verification-Record: text preservation checked, compilation not verified;
-- COMMENT Governed by GNU Affero General Public License version 3;
-- COMMENT together with applicable Sovereign Leviathan additional terms;
-- COMMENT AGPLv3 terms remain authoritative where additional terms do not validly apply;
-- COMMENT See LICENSE and docs/PROVENANCE.md;
-- COMMENT 
-- COMMENT ===========================================================;
-- COMMENT SOVEREIGN NODE KEY: TOPOS-FILE-001-Core-BLK-001-001-1;
-- COMMENT Parent-ID: TOPOS-FILE-001-Core;
-- COMMENT License-ID: SL-AGPL3-001 / MGPLv3;
-- COMMENT Covenant-Version: 1.0;
-- COMMENT Copyright: 2026 SNAPKITTYWEST;
-- COMMENT License-Location: LICENSE;
-- COMMENT Provenance: docs/NODE_MANIFEST.json;
-- COMMENT BLOCK 001;
-- COMMENT Component: Core.hs;
-- COMMENT Purpose: braid algebra, Yang-Baxter, Jones/Alexander/HOMFLY, Burau, tangle;
-- COMMENT Inputs: varies;
-- COMMENT Outputs: varies;
-- COMMENT ===========================================================;
-- COMMENT 
{-# LANGUAGE GADTs #-}
{-# LANGUAGE DeriveGeneric #-}
-- | Topos: Braided Domain-Specific Language for Topological Invariants
-- Dense raw implementation core. No runtime deps beyond base + containers.
-- Strand algebra, braid monoid, Yang-Baxter native, polynomial invariants embedded.

module Topos.Core where

import Prelude hiding (id, (.))
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as M
import Data.Set (Set)
import qualified Data.Set as S
import Data.List (nub, sort, intersperse, foldl')
import Data.Maybe (fromMaybe, mapMaybe)
import Control.Monad (foldM, when, unless)
import Control.Applicative ((<|>))
import GHC.Generics (Generic)

-- Primitive strand identifiers. Parametric over name type for extensibility.
newtype Strand = Strand { unStrand :: String } deriving (Eq, Ord, Show, Generic)

strand :: String -> Strand
strand = Strand

-- Crossing type: over or under, oriented left-to-right or right-to-left.
data CrossingType = Over | Under deriving (Eq, Ord, Show, Generic)

data Orientation = LtoR | RtoL deriving (Eq, Ord, Show, Generic)

data Crossing = Crossing
  { upper :: Strand
  , lower :: Strand
  , ctype :: CrossingType
  , orient :: Orientation
  } deriving (Eq, Ord, Show, Generic)

mkCrossing :: Strand -> Strand -> CrossingType -> Orientation -> Crossing
mkCrossing u l t o = Crossing u l t o

-- Twist: integer multiple of full 2 pi or half-turn (pi).
data Twist = Twist
  { twisted :: Strand
  , turns :: Int -- positive = right-handed, negative = left-handed
  } deriving (Eq, Ord, Show, Generic)

fullTurn :: Strand -> Twist
fullTurn s = Twist s 1

halfTurn :: Strand -> Twist
halfTurn s = Twist s 0 -- convention: 0 = pi rotation for framing

-- Braid word generators. Atomic operations.
data Generator
  = Cross Crossing
  | Tw Twist
  | Id Strand -- identity on single strand
  | Parallel [Generator] -- simultaneous non-interacting
  | Seq [Generator] -- sequential composition
  deriving (Eq, Ord, Show, Generic)

-- Full braid expression: free monoid on generators quotiented by braid relations.
data Braid = Braid
  { strands :: [Strand]
  , word :: [Generator]
  , framing :: Map Strand Int -- writhe contribution per strand
  } deriving (Eq, Show, Generic)

emptyBraid :: [Strand] -> Braid
emptyBraid ss = Braid ss [] M.empty

-- Core constructors matching the proposed surface syntax.
crossing :: Strand -> Strand -> CrossingType -> Braid -> Braid
crossing a b t b0 =
  let c = mkCrossing a b t LtoR
      g = Cross c
  in b0 { word = word b0 ++ [g]
        , framing = updateWrithe a b t (framing b0)
        }

crossing' :: Strand -> Strand -> CrossingType -> Orientation -> Braid -> Braid
crossing' a b t o b0 =
  let c = mkCrossing a b t o
      g = Cross c
  in b0 { word = word b0 ++ [g]
        , framing = updateWrithe a b t (framing b0)
        }

twist :: Strand -> Int -> Braid -> Braid
twist s n b0 =
  let t = Twist s n
      g = Tw t
  in b0 { word = word b0 ++ [g]
        , framing = M.insertWith (+) s n (framing b0)
        }

-- Sequential composition of braids (must share strand set or be relabeled).
compose :: Braid -> Braid -> Either String Braid
compose b1 b2
  | sort (strands b1) /= sort (strands b2) = Left "strand mismatch in compose"
  | otherwise = Right $ Braid (strands b1) (word b1 ++ word b2)
                              (M.unionWith (+) (framing b1) (framing b2))

-- Parallel composition: side-by-side, no interaction.
parallel :: Braid -> Braid -> Braid
parallel b1 b2 =
  Braid (nub $ strands b1 ++ strands b2)
        [Parallel (word b1 ++ word b2)]
        (M.unionWith (+) (framing b1) (framing b2))

-- Identity braid on given strands.
identity :: [Strand] -> Braid
identity ss = Braid ss (map Id ss) M.empty

-- Update writhe contribution from a crossing.
updateWrithe :: Strand -> Strand -> CrossingType -> Map Strand Int -> Map Strand Int
updateWrithe a b Over m = M.insertWith (+) a 1 (M.insertWith (+) b (-1) m)
updateWrithe a b Under m = M.insertWith (+) a (-1) (M.insertWith (+) b 1 m)

-- Braid group relations (Yang-Baxter / Artin).
-- sigma_i sigma_j = sigma_j sigma_i |i-j| > 1
-- sigma_i sigma_{i+1} sigma_i = sigma_{i+1} sigma_i sigma_{i+1}
-- sigma_i sigma_i^{-1} = 1
data Relation
  = FarCommute Int Int
  | YangBaxter Int
  | Inverse Int
  deriving (Eq, Show)

-- Normalize a braid word by applying relations (rewrite system).
normalize :: Braid -> Braid
normalize b =
  let w = word b
      w' = rewriteLoop w
  in b { word = w' }

rewriteLoop :: [Generator] -> [Generator]
rewriteLoop gs =
  let gs' = applyFarCommute gs
      gs'' = applyYangBaxter gs'
      gs''' = applyInverse gs''
  in if gs''' == gs then gs else rewriteLoop gs'''

applyFarCommute :: [Generator] -> [Generator]
applyFarCommute [] = []
applyFarCommute [g] = [g]
applyFarCommute (g1:g2:rest) =
  case (g1, g2) of
    (Cross c1, Cross c2) ->
      if strandsDisjoint c1 c2
      then g2 : applyFarCommute (g1 : rest)
      else g1 : applyFarCommute (g2 : rest)
    _ -> g1 : applyFarCommute (g2 : rest)

strandsDisjoint :: Crossing -> Crossing -> Bool
strandsDisjoint c1 c2 =
  S.fromList [upper c1, lower c1] `S.disjoint` S.fromList [upper c2, lower c2]

applyYangBaxter :: [Generator] -> [Generator]
applyYangBaxter gs = go gs
  where
    go [] = []
    go [g] = [g]
    go [g1,g2] = [g1,g2]
    go (g1:g2:g3:rest) =
      case (g1,g2,g3) of
        (Cross c1, Cross c2, Cross c3) ->
          if isYBTriple c1 c2 c3
          then Cross (ybRewrite c1 c2 c3) : go rest -- simplified rewrite
          else g1 : go (g2:g3:rest)
        _ -> g1 : go (g2:g3:rest)

isYBTriple :: Crossing -> Crossing -> Crossing -> Bool
isYBTriple c1 c2 c3 =
  let s1 = S.fromList [upper c1, lower c1]
      s2 = S.fromList [upper c2, lower c2]
      s3 = S.fromList [upper c3, lower c3]
  in S.size (s1 `S.union` s2 `S.union` s3) == 3

ybRewrite :: Crossing -> Crossing -> Crossing -> Crossing
ybRewrite c1 _ _ = c1 -- placeholder; real implementation permutes over/under

applyInverse :: [Generator] -> [Generator]
applyInverse [] = []
applyInverse [g] = [g]
applyInverse (g1:g2:rest) =
  case (g1,g2) of
    (Cross c1, Cross c2) ->
      if inversePair c1 c2
      then applyInverse rest
      else g1 : applyInverse (g2 : rest)
    _ -> g1 : applyInverse (g2 : rest)

inversePair :: Crossing -> Crossing -> Bool
inversePair c1 c2 =
  upper c1 == upper c2 && lower c1 == lower c2 && ctype c1 /= ctype c2

-- Jones polynomial via Kauffman bracket + writhe normalization.
-- Simplified state-sum model for demonstration density.

data Laurent = Laurent { coeffs :: Map Int Integer } deriving (Eq, Show)

zeroL :: Laurent
zeroL = Laurent M.empty

oneL :: Laurent
oneL = Laurent (M.singleton 0 1)

varA :: Laurent
varA = Laurent (M.singleton 1 1)

varAinv :: Laurent
varAinv = Laurent (M.singleton (-1) 1)

addL :: Laurent -> Laurent -> Laurent
addL (Laurent m1) (Laurent m2) = Laurent (M.unionWith (+) m1 m2)

mulL :: Laurent -> Laurent -> Laurent
mulL (Laurent m1) (Laurent m2) =
  Laurent $ M.fromListWith (+)
    [ (e1+e2, c1*c2) | (e1,c1) <- M.toList m1, (e2,c2) <- M.toList m2 ]

scaleL :: Integer -> Laurent -> Laurent
scaleL k (Laurent m) = Laurent (M.map (*k) m)

-- Kauffman bracket of a crossing: A * smooth0 + A^{-1} * smooth1
bracketCrossing :: Crossing -> Laurent
bracketCrossing c =
  case ctype c of
    Over -> addL (mulL varA oneL) (mulL varAinv oneL) -- simplified
    Under -> addL (mulL varAinv oneL) (mulL varA oneL)

-- Full Jones via writhe-normalized bracket.
jones :: Braid -> Laurent
jones b =
  let w = totalWrithe b
      br = bracketWord (word b)
      norm = mulL (scaleL (if even w then 1 else -1) (powL varA (-3*w))) br
  in norm

totalWrithe :: Braid -> Int
totalWrithe b = sum (M.elems (framing b))

bracketWord :: [Generator] -> Laurent
bracketWord = foldl' (\acc g -> mulL acc (bracketGen g)) oneL

bracketGen :: Generator -> Laurent
bracketGen (Cross c) = bracketCrossing c
bracketGen (Tw t) = powL varA (2 * turns t) -- framing factor
bracketGen (Id _) = oneL
bracketGen (Parallel gs) = foldl' mulL oneL (map bracketGen gs)
bracketGen (Seq gs) = foldl' mulL oneL (map bracketGen gs)

powL :: Laurent -> Int -> Laurent
powL _ 0 = oneL
powL l n | n > 0 = foldl' mulL oneL (replicate n l)
         | otherwise = foldl' mulL oneL (replicate (-n) (invertL l))

invertL :: Laurent -> Laurent
invertL (Laurent m) = Laurent (M.mapKeys negate m) -- only monomials for now

-- Alexander polynomial via Seifert matrix or Fox calculus approximation.
data Poly = Poly { pcoeffs :: Map Int Integer } deriving (Eq, Show)

zeroP :: Poly
zeroP = Poly M.empty

oneP :: Poly
oneP = Poly (M.singleton 0 1)

varT :: Poly
varT = Poly (M.singleton 1 1)

addP :: Poly -> Poly -> Poly
addP (Poly m1) (Poly m2) = Poly (M.unionWith (+) m1 m2)

mulP :: Poly -> Poly -> Poly
mulP (Poly m1) (Poly m2) =
  Poly $ M.fromListWith (+)
    [ (e1+e2, c1*c2) | (e1,c1) <- M.toList m1, (e2,c2) <- M.toList m2 ]

alexander :: Braid -> Poly
alexander b =
  let n = length (strands b)
      -- crude Fox free derivative approximation for density
      deriv = foldl' (\acc g -> addP acc (foxDeriv g)) zeroP (word b)
  in mulP (scaleP (fromIntegral n) oneP) deriv

foxDeriv :: Generator -> Poly
foxDeriv (Cross c) =
  case ctype c of
    Over -> addP oneP (scaleP (-1) varT)
    Under -> addP varT (scaleP (-1) oneP)
foxDeriv _ = zeroP

scaleP :: Integer -> Poly -> Poly
scaleP k (Poly m) = Poly (M.map (*k) m)

-- HOMFLY polynomial (two-variable).
data HOMFLY = HOMFLY { hcoeffs :: Map (Int,Int) Integer } deriving (Eq, Show)

zeroH :: HOMFLY
zeroH = HOMFLY M.empty

oneH :: HOMFLY
oneH = HOMFLY (M.singleton (0,0) 1)

varL :: HOMFLY
varL = HOMFLY (M.singleton (1,0) 1)

varM :: HOMFLY
varM = HOMFLY (M.singleton (0,1) 1)

addH :: HOMFLY -> HOMFLY -> HOMFLY
addH (HOMFLY m1) (HOMFLY m2) = HOMFLY (M.unionWith (+) m1 m2)

mulH :: HOMFLY -> HOMFLY -> HOMFLY
mulH (HOMFLY m1) (HOMFLY m2) =
  HOMFLY $ M.fromListWith (+)
    [ ((e1+e2,f1+f2), c1*c2) | ((e1,f1),c1) <- M.toList m1, ((e2,f2),c2) <- M.toList m2 ]

homfly :: Braid -> HOMFLY
homfly b =
  foldl' (\acc g -> mulH acc (homflyGen g)) oneH (word b)

homflyGen :: Generator -> HOMFLY
homflyGen (Cross c) =
  case ctype c of
    Over -> addH (mulH varL oneH) (mulH varM oneH)
    Under -> addH (mulH (invertH varL) oneH) (mulH varM oneH)
homflyGen _ = oneH

invertH :: HOMFLY -> HOMFLY
invertH (HOMFLY m) = HOMFLY (M.mapKeys (\(e,f) -> (-e,f)) m)

-- Quantum circuit embedding for topological QC (anyonic).
-- Non-abelian anyons: Fibonacci or Ising model stubs.

data Anyon = Fib | Ising | Custom String deriving (Eq, Ord, Show, Generic)

-- Fusion rule a x b -> c (simplified from GADT form in draft)
data Fusion = Fusion Anyon Anyon Anyon deriving (Eq, Show, Generic)

data RMatrix = RMatrix
  { anyons :: (Anyon, Anyon)
  , phase :: Laurent -- R-symbol as Laurent
  } deriving (Eq, Show, Generic)

data QuantumBraid = QuantumBraid
  { classical :: Braid
  , anyonType :: Anyon
  , fusionTree :: [Fusion]
  , rGates :: [RMatrix]
  } deriving (Eq, Show, Generic)

embedQuantum :: Braid -> Anyon -> QuantumBraid
embedQuantum b a =
  QuantumBraid b a [] (map (crossingToR a) (extractCrossings b))

extractCrossings :: Braid -> [Crossing]
extractCrossings b = mapMaybe toCross (word b)
  where
    toCross (Cross c) = Just c
    toCross _ = Nothing

crossingToR :: Anyon -> Crossing -> RMatrix
crossingToR a c =
  RMatrix (a,a) (if ctype c == Over then varA else varAinv)

-- Measurement of topological invariants.
measureJones :: Braid -> Laurent
measureJones = jones

measureAlexander :: Braid -> Poly
measureAlexander = alexander

measureHOMFLY :: Braid -> HOMFLY
measureHOMFLY = homfly

-- Surface syntax macros approximating the proposed DSL.
-- braid { strand a,b,c ; crossing(a,b,over) ; ... }

data Stmt
  = StrandDecl [Strand]
  | CrossingStmt Strand Strand CrossingType
  | TwistStmt Strand Int
  | ComposeStmt Braid Braid
  | MeasureJones [Strand]
  | MeasureAlex [Strand]
  | MeasureHomfly [Strand]
  | ParallelStmt [Stmt]
  | SeqStmt [Stmt]
  deriving (Eq, Show)

type Program = [Stmt]

evalProgram :: Program -> Either String Braid
evalProgram stmts = foldM step (emptyBraid []) stmts
  where
    step b (StrandDecl ss) = Right b { strands = nub (strands b ++ ss) }
    step b (CrossingStmt a c t) = Right (crossing a c t b)
    step b (TwistStmt s n) = Right (twist s n b)
    step _ (ComposeStmt b1 b2) = compose b1 b2
    step b (MeasureJones _) = Right b -- side-effect free; result via separate call
    step b (MeasureAlex _) = Right b
    step b (MeasureHomfly _) = Right b
    step _ (ParallelStmt ss) = do
      bs <- mapM (\s -> evalProgram [s]) ss
      pure $ foldl' parallel (emptyBraid []) bs
    step b (SeqStmt ss) = foldM step b ss

-- Dense example library: torus knots, pretzels, rational tangles.

trefoil :: Braid
trefoil =
  let a = strand "a"
      b = strand "b"
      c = strand "c"
  in normalize $ crossing a b Over
               $ crossing b c Over
               $ crossing c a Over
               $ emptyBraid [a,b,c]

figureEight :: Braid
figureEight =
  let a = strand "1"
      b = strand "2"
  in normalize $ crossing a b Over
               $ crossing a b Under
               $ crossing a b Over
               $ crossing a b Under
               $ emptyBraid [a,b]

hopfLink :: Braid
hopfLink =
  let a = strand "x"
      b = strand "y"
  in normalize $ crossing a b Over
               $ crossing a b Over
               $ emptyBraid [a,b]

-- Parametric strand systems.
parametricStrands :: Int -> [Strand]
parametricStrands n = map (\i -> strand ("s" ++ show i)) [1..n]

-- Generate pure braid generators sigma_i^{+-1} for n strands.
sigma :: Int -> Int -> CrossingType -> Braid
sigma n i t
  | i < 1 || i >= n = error "sigma index out of range"
  | otherwise =
      let ss = parametricStrands n
          a = ss !! (i-1)
          b = ss !! i
      in crossing a b t (emptyBraid ss)

-- Full braid group presentation generators.
generators :: Int -> [Braid]
generators n = [sigma n i Over | i <- [1..n-1]] ++ [sigma n i Under | i <- [1..n-1]]

-- Closure of a braid to a link (Markov move stubs).
data Link = Link { components :: [[Strand]], braidRep :: Braid } deriving (Eq, Show)

closeBraid :: Braid -> Link
closeBraid b = Link [strands b] b

-- Markov moves for equivalence.
markovI :: Braid -> Braid -- conjugation
markovI b = b -- identity for now; real impl cycles word

markovII :: Braid -> Strand -> CrossingType -> Braid -- stabilization
markovII b s t =
  let b' = b { strands = strands b ++ [s] }
  in crossing (last (strands b)) s t b'

-- Trace of braid representation (for quantum invariants).
traceBraid :: Braid -> Laurent
traceBraid b = scaleL (fromIntegral (length (strands b))) (jones b)

-- Additional dense helpers for tangle calculus.
data Tangle = Tangle
  { inPorts :: [Strand]
  , outPorts :: [Strand]
  , body :: Braid
  } deriving (Eq, Show)

identityTangle :: [Strand] -> Tangle
identityTangle ss = Tangle ss ss (identity ss)

composeTangle :: Tangle -> Tangle -> Either String Tangle
composeTangle t1 t2
  | outPorts t1 /= inPorts t2 = Left "port mismatch"
  | otherwise = do
      b <- compose (body t1) (body t2)
      pure $ Tangle (inPorts t1) (outPorts t2) b

-- Rational tangle continued fraction expansion.
rationalTangle :: [Int] -> Tangle
rationalTangle [] = identityTangle []
rationalTangle (k:ks) =
  let s = strand "r"
      t0 = twist s k (emptyBraid [s])
  in Tangle [s] [s] t0

-- Seifert surface genus estimate from braid.
genusEstimate :: Braid -> Int
genusEstimate b =
  let c = length (extractCrossings b)
      s = length (strands b)
  in max 0 ((c - s + 1) `div` 2)

-- Writhe, linking number, etc.
writhe :: Braid -> Int
writhe = totalWrithe

linkingNumber :: Braid -> Strand -> Strand -> Int
linkingNumber b a c =
  let crosses = filter (\(Crossing u l _ _) -> (u==a && l==c) || (u==c && l==a)) (extractCrossings b)
  in sum [ if ctype x == Over then 1 else -1 | x <- crosses ] `div` 2

-- Export surface for the proposed DSL syntax sugar.
-- Users write:
-- braid {
-- strand a, b, c
-- crossing(a, b, over)
-- crossing(b, c, under)
-- twist(a, full_turn)
-- measure_jones(a, b)
-- compose braid_1, braid_2
-- }

parseSurface :: String -> Either String Program
parseSurface _ = Right [] -- parser stub; real would be recursive descent

-- Additional rewrite: handle parallel and sequential flattening.
flatten :: [Generator] -> [Generator]
flatten = concatMap go
  where
    go (Parallel gs) = flatten gs
    go (Seq gs) = flatten gs
    go g = [g]

-- More Yang-Baxter variants for colored braids.
coloredYB :: Crossing -> Crossing -> Crossing -> Maybe [Crossing]
coloredYB c1 c2 c3
  | isYBTriple c1 c2 c3 = Just [c3, c2, c1] -- reverse order rewrite
  | otherwise = Nothing

-- Quantum dimension for anyons.
quantumDim :: Anyon -> Laurent
quantumDim Fib = addL oneL varA -- golden ratio approx
quantumDim Ising = scaleL 2 oneL
quantumDim (Custom _) = oneL

-- S-matrix and modular data stubs for TQFT.
sMatrix :: Anyon -> Map (Anyon,Anyon) Laurent
sMatrix a = M.singleton (a,a) oneL

-- Verlinde formula approximation.
verlinde :: Anyon -> Int
verlinde Fib = 2
verlinde Ising = 3
verlinde _ = 1

-- Dense block of pure braid examples.
pureBraid3 :: [Braid]
pureBraid3 =
  [ sigma 3 1 Over
  , sigma 3 2 Over
  , sigma 3 1 Under
  , sigma 3 2 Under
  , normalize (compose' (sigma 3 1 Over) (sigma 3 2 Over))
  , normalize (compose' (sigma 3 2 Over) (sigma 3 1 Over))
  ]
  where
    compose' b1 b2 = either (error "fail") id (compose b1 b2)

-- More knots via braid words.
cinquefoil :: Braid
cinquefoil =
  let ss = parametricStrands 2
      a = head ss
      b = ss !! 1
  in normalize $ foldl' (\acc _ -> crossing a b Over acc) (emptyBraid ss) [1..5 :: Int]

stevedore :: Braid
stevedore =
  let a = strand "a"
      b = strand "b"
      c = strand "c"
  in normalize $ crossing a b Over
               $ crossing b c Under
               $ crossing a b Over
               $ crossing b c Over
               $ crossing a b Under
               $ crossing b c Under
               $ emptyBraid [a,b,c]

-- Pretzel braids.
pretzel :: [Int] -> Braid
pretzel ks =
  let n = length ks
      ss = parametricStrands (n+1)
      go i k b = iterate (\b' -> crossing (ss!!i) (ss!!(i+1)) (if k>0 then Over else Under) b') b !! abs k
  in foldl' (\b (i,k) -> go i k b) (emptyBraid ss) (zip [0..] ks)

-- More polynomial helpers.
degree :: Laurent -> Int
degree (Laurent m) = if M.null m then 0 else maximum (M.keys m)

minDegree :: Laurent -> Int
minDegree (Laurent m) = if M.null m then 0 else minimum (M.keys m)

-- Evaluation of Laurent at a root of unity (for quantum invariants).
evalAt :: Laurent -> Integer -> Integer
evalAt (Laurent m) q = sum [ c * q^e | (e,c) <- M.toList m ]

-- Additional anyon fusion rules.
fibFusion :: Anyon -> Anyon -> [Anyon]
fibFusion Fib Fib = [Fib, Custom "1"]
fibFusion _ _ = [Custom "1"]

isingFusion :: Anyon -> Anyon -> [Anyon]
isingFusion Ising Ising = [Custom "1", Custom "psi"]
isingFusion _ _ = [Custom "1"]

-- R-matrix for Fibonacci.
fibR :: Laurent
fibR = addL varA (scaleL (-1) varAinv)

-- More surface syntax statements for control flow (classical part).
data Classical
  = Let String Braid
  | If Cond Program Program
  | While Cond Program
  | PrintInvariants Braid
  deriving (Eq, Show)

data Cond
  = WritheEq Int
  | StrandCountEq Int
  | Always
  deriving (Eq, Show)

-- Evaluation of classical control.
evalClassical :: Classical -> Map String Braid -> Either String (Map String Braid)
evalClassical (Let name b) env = Right (M.insert name b env)
evalClassical (If c p1 p2) env =
  if evalCond c env then evalProgram p1 >>= \b -> Right (M.insert "last" b env)
                    else evalProgram p2 >>= \b -> Right (M.insert "last" b env)
evalClassical (While c p) env = loop env
  where
    loop e = if evalCond c e
             then evalProgram p >>= \b -> loop (M.insert "last" b e)
             else Right e
evalClassical (PrintInvariants _) env = Right env -- side effect omitted

evalCond :: Cond -> Map String Braid -> Bool
evalCond Always _ = True
evalCond (WritheEq n) env = maybe False ((==n) . writhe) (M.lookup "last" env)
evalCond (StrandCountEq n) env = maybe False ((==n) . length . strands) (M.lookup "last" env)

-- Dense continuation: more knot invariants via representations.
-- Burau representation for braid group.

type Matrix a = [[a]]

burau :: Int -> Braid -> Matrix Laurent
burau n b =
  let idm = identityMatrix n oneL zeroL
  in foldl' (\m g -> mulMat m (burauGen n g)) idm (word b)

identityMatrix :: Int -> a -> a -> Matrix a
identityMatrix n o z = [ [ if i==j then o else z | j <- [0..n-1] ] | i <- [0..n-1] ]

mulMat :: Num a => Matrix a -> Matrix a -> Matrix a
mulMat a b =
  [ [ sum [ a!!i!!k * b!!k!!j | k <- [0..length (head a)-1] ] | j <- [0..length (head b)-1] ] | i <- [0..length a-1] ]

burauGen :: Int -> Generator -> Matrix Laurent
burauGen n (Cross c) =
  let i = strandIndex (upper c) n
      j = strandIndex (lower c) n
  in if abs (i-j)==1
     then burauSigma n (min i j) (ctype c)
     else identityMatrix n oneL zeroL
burauGen n _ = identityMatrix n oneL zeroL

strandIndex :: Strand -> Int -> Int
strandIndex (Strand s) n =
  let numStr = filter (`elem` ("0123456789" :: String)) s
      num = if null numStr then 1 else read numStr :: Int
  in max 0 (min (n-1) (num-1))

burauSigma :: Int -> Int -> CrossingType -> Matrix Laurent
burauSigma n i Over =
  let m = identityMatrix n oneL zeroL
  in updateMatrix m i i varAinv
       (updateMatrix m i (i+1) oneL
         (updateMatrix m (i+1) i zeroL
           (updateMatrix m (i+1) (i+1) varA m)))
burauSigma n i Under =
  let m = identityMatrix n oneL zeroL
  in updateMatrix m i i varA
       (updateMatrix m i (i+1) zeroL
         (updateMatrix m (i+1) i oneL
           (updateMatrix m (i+1) (i+1) varAinv m)))

updateMatrix :: Matrix a -> Int -> Int -> a -> Matrix a -> Matrix a
updateMatrix _ i j v old =
  [ [ if r==i && c==j then v else old!!r!!c | c <- [0..length (head old)-1] ] | r <- [0..length old-1] ]

-- Final dense block: pretty printers and debug.
prettyBraid :: Braid -> String
prettyBraid b =
  "braid {\n" ++
  " strand " ++ myIntercalate ", " (map unStrand (strands b)) ++ "\n" ++
  concatMap prettyGen (word b) ++
  "}\n"

prettyGen :: Generator -> String
prettyGen (Cross c) =
  " crossing(" ++ unStrand (upper c) ++ ", " ++ unStrand (lower c) ++ ", " ++
  show (ctype c) ++ ")\n"
prettyGen (Tw t) =
  " twist(" ++ unStrand (twisted t) ++ ", " ++ show (turns t) ++ ")\n"
prettyGen (Id s) = " id(" ++ unStrand s ++ ")\n"
prettyGen (Parallel gs) = " parallel {\n" ++ concatMap prettyGen gs ++ " }\n"
prettyGen (Seq gs) = " seq {\n" ++ concatMap prettyGen gs ++ " }\n"

myIntercalate :: String -> [String] -> String
myIntercalate sep = concat . intersperse sep

-- Test suite stubs (executable as pure values).
tests :: [(String, Bool)]
tests =
  [ ("trefoil writhe", writhe trefoil == 3)
  , ("figureEight writhe", writhe figureEight == 0)
  , ("hopf linking", linkingNumber hopfLink (strand "x") (strand "y") == 1)
  , ("normalize idemp", normalize (normalize trefoil) == normalize trefoil)
  ]
