-- COMMENT SOVEREIGN LEVIATHAN COVENANT - FRAGMENT BINDING;
-- COMMENT Node-ID: TOPOS-FILE-013-Spec;
-- COMMENT Parent-Work: topos;
-- COMMENT Parent-Covenant: SL-AGPL3-001;
-- COMMENT Copyright: 2026 SNAPKITTYWEST;
-- COMMENT License-ID: SL-AGPL3-001 / MGPLv3;
-- COMMENT Covenant-Version: 1.0;
-- COMMENT Source-Hash: sha256:0e5803eed612d8a3f8202fd8734af54dfb86b2a6472cf050486f5e69a138ff57;
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
-- COMMENT SOVEREIGN NODE KEY: TOPOS-FILE-013-Spec-BLK-001-001-1;
-- COMMENT Parent-ID: TOPOS-FILE-013-Spec;
-- COMMENT License-ID: SL-AGPL3-001 / MGPLv3;
-- COMMENT Covenant-Version: 1.0;
-- COMMENT Copyright: 2026 SNAPKITTYWEST;
-- COMMENT License-Location: LICENSE;
-- COMMENT Provenance: docs/NODE_MANIFEST.json;
-- COMMENT BLOCK 001;
-- COMMENT Component: Spec.hs;
-- COMMENT Purpose: HUnit/QuickCheck tests, normalize idempotent;
-- COMMENT Inputs: varies;
-- COMMENT Outputs: varies;
-- COMMENT ===========================================================;
-- COMMENT 
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
