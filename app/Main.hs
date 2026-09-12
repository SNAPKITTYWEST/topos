-- COMMENT SOVEREIGN LEVIATHAN COVENANT - FRAGMENT BINDING;
-- COMMENT Node-ID: TOPOS-FILE-012-Main;
-- COMMENT Parent-Work: topos;
-- COMMENT Parent-Covenant: SL-AGPL3-001;
-- COMMENT Copyright: 2026 SNAPKITTYWEST;
-- COMMENT License-ID: SL-AGPL3-001 / MGPLv3;
-- COMMENT Covenant-Version: 1.0;
-- COMMENT Source-Hash: sha256:e86267848013425899158197d8fa32b1e400d1879b1214b21d06f1550b793586;
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
-- COMMENT SOVEREIGN NODE KEY: TOPOS-FILE-012-Main-BLK-001-001-1;
-- COMMENT Parent-ID: TOPOS-FILE-012-Main;
-- COMMENT License-ID: SL-AGPL3-001 / MGPLv3;
-- COMMENT Covenant-Version: 1.0;
-- COMMENT Copyright: 2026 SNAPKITTYWEST;
-- COMMENT License-Location: LICENSE;
-- COMMENT Provenance: docs/NODE_MANIFEST.json;
-- COMMENT BLOCK 001;
-- COMMENT Component: Main.hs;
-- COMMENT Purpose: demo runner, writhe, Jones, YB demo;
-- COMMENT Inputs: varies;
-- COMMENT Outputs: varies;
-- COMMENT ===========================================================;
-- COMMENT 
module Main where

import Topos.Core
import qualified Data.Map.Strict as M

main :: IO ()
main = do
  putStrLn "=== Topos Demo ==="
  putStrLn $ prettyBraid trefoil
  putStrLn $ "trefoil writhe: " ++ show (writhe trefoil)
  putStrLn $ "trefoil jones: " ++ show (jones trefoil)
  putStrLn $ "figureEight writhe: " ++ show (writhe figureEight)
  putStrLn $ "hopf linking (x,y): " ++ show (linkingNumber hopfLink (strand "x") (strand "y"))
  putStrLn $ "hopf jones: " ++ show (jones hopfLink)
  putStrLn $ "cinquefoil genus est: " ++ show (genusEstimate cinquefoil)
  putStrLn $ "pureBraid3 count: " ++ show (length pureBraid3)
  putStrLn "--- Burau trefoil (2x2 over Laurent) ---"
  let b = burau 3 trefoil
  mapM_ print b
  putStrLn "--- Quantum embedding (Fib) ---"
  print (embedQuantum trefoil Fib)
  putStrLn "--- Tests ---"
  mapM_ (\(n,ok) -> putStrLn $ (if ok then "[PASS] " else "[FAIL] ") ++ n) tests
  putStrLn "--- Timing bound (from prolog/timing.lp) ---"
  putStrLn "lambda_max for tau=0.001ms = 150 entropy/ms"
  putStrLn $ "valid_reset(0.001,10): " ++ show (0.001 <= 0.15/10 :: Bool)
  putStrLn $ "valid_reset(0.02,10): " ++ show (0.02 <= 0.15/10 :: Bool)
  putStrLn $ "unscalable(150): " ++ show (150 >= 150 :: Bool)
