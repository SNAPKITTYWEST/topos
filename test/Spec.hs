/* ========================================================================
 * SOVEREIGN LEVIATHAN COVENANT — FRAGMENT BINDING
 * ========================================================================
 *
 * License-ID:        SL-AGPL3-001
 * Covenant-Version:  1.0
 * Node-ID:           TOPOS-FILE-013-Spec
 * Parent-Covenant:   SL-AGPL3-001
 * Copyright:         2026 SNAPKITTYWEST
 * Source-Hash:       sha256:0e5803eed612d8a3f8202fd8734af54dfb86b2a6472cf050486f5e69a138ff57
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
module Main where

import Topos.Core
import qualified Data.Map.Strict as M
import Test.HUnit
import Test.QuickCheck (quickCheck, property)

main :: IO ()
main = do
  _ <- runTestTT testsHUnit
  putStrLn "QuickCheck: normalize idempotent on trefoil"
  quickCheck (property $ normalize (normalize trefoil) == normalize trefoil)
  putStrLn "done"

testsHUnit :: Test
testsHUnit = TestList
  [ "trefoil writhe 3" ~: writhe trefoil ~?= 3
  , "figureEight writhe 0" ~: writhe figureEight ~?= 0
  , "hopf linking 1" ~: linkingNumber hopfLink (strand "x") (strand "y") ~?= 1
  , "normalize idempotent" ~: normalize (normalize trefoil) ~?= normalize trefoil
  , "parallel strands additive" ~: length (strands (parallel trefoil hopfLink)) ~?= length (nubStrands trefoil hopfLink)
  , "trace non-empty" ~: (not . M.null . coeffs $ traceBraid trefoil) ~? "trace empty"
  , "degree >= minDegree" ~: degree (jones trefoil) >= minDegree (jones trefoil) ~? "degree violation"
  ]
  where
    nubStrands a b = foldr (\s acc -> if s `elem` acc then acc else s:acc) [] (strands a ++ strands b)
