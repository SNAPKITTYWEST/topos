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
