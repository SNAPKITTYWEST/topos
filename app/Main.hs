/* ========================================================================
 * SOVEREIGN LEVIATHAN COVENANT — FRAGMENT BINDING
 * ========================================================================
 *
 * License-ID:        SL-AGPL3-001
 * Covenant-Version:  1.0
 * Node-ID:           TOPOS-FILE-012-Main
 * Parent-Covenant:   SL-AGPL3-001
 * Copyright:         2026 SNAPKITTYWEST
 * Source-Hash:       sha256:e86267848013425899158197d8fa32b1e400d1879b1214b21d06f1550b793586
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
