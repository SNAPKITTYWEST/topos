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
