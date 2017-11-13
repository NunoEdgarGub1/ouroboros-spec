module DeltaQ.Chart
    ( layoutStats
    , toPNG
    , deltaQToPNG
    ) where

import Control.Monad                          (void)
import Data.Colour.SRGB
import DeltaQ.Core
import DeltaQ.Stats
import Graphics.Rendering.Chart.Easy
import Graphics.Rendering.Chart.Backend.Cairo
import Simulation.Time
import System.Random                          (StdGen)
import Text.Printf                            (printf)

layoutStats :: String -> DeltaQStats -> Layout Double Double
layoutStats title dqst = layout_title     .~ title
                       $ layout_grid_last .~ True
                       $ layout_plots     .~ ps
                       $ def
  where
    ps :: [Plot Double Double]
    ps = case dqstStats dqst of
        Nothing -> []
        Just st -> plots (dqstTangible dqst) st

plots :: Rational -> Stats -> [Plot Double Double]
plots tangible st = [ toPlot graph
                    , minLine
                    , maxLine
                    , tangibleLine
                    , meanLine
                    ] ++ sigmaLines
  where
    graph :: PlotFillBetween Double Double
    graph = plot_fillbetween_style .~ solidFillStyle (opaque $ sRGB 0.5 1 0.5)
          $ plot_fillbetween_values .~ [(x, (0, y)) | (x, y) <- vs]
          $ def

    minLine :: Plot Double Double
    minLine =
        let tMin' = toDouble $ stMin st
            style = line_color .~ opaque (sRGB 0 0 1)
                  $ line_width .~ 2
                  $ line_dashes .~ [6, 6]
                  $ def
        in  vlinePlot (printf "min (%.4fs)" tMin') style tMin'

    maxLine :: Plot Double Double
    maxLine =
        let tMax' = toDouble $ stMax st
            style = line_color .~ opaque (sRGB 0 0 1)
                  $ line_width .~ 2
                  $ line_dashes .~ [6, 6]
                  $ def
        in  vlinePlot (printf "max (%.4fs)" tMax') style tMax'

    tangibleLine :: Plot Double Double
    tangibleLine =
        let tangible' = fromRational tangible
        in  hlinePlot (printf "tangible mass (%.4f)" tangible') def tangible'

    meanLine :: Plot Double Double
    meanLine =
        let mean' = toDouble $ stMean st
            style = line_color .~ opaque (sRGB 1 0 0)
                  $ line_width .~ 2
                  $ def
        in  vlinePlot (printf "mean (%.4f)" mean') style mean'

    sigmaLines :: [Plot Double Double]
    sigmaLines = case stVar st of
        Nothing -> []
        Just v  ->
            let s     = sqrt $ fromRational v
                m     = toDouble $ stMean st
                m1    = m - s
                m2    = m + s
                style = line_color .~ opaque (sRGB 1 0 0)
                      $ line_width .~ 2
                      $ line_dashes .~ [6, 6]
                      $ def
                l1    = vlinePlot (printf "mean - sigma (%.4f)" m1) style m1
                l2    = vlinePlot (printf "mean + sigma (%.4f)" m2) style m2
            in  [l1, l2]

    vs :: [(Double, Double)]
    vs = [(toDouble x, fromRational y) | (x, y) <- stCDF st]

    toDouble :: Seconds -> Double
    toDouble = fromRational . toRational

toPNG :: FilePath -> Layout Double Double -> IO ()
toPNG file layout = void $ renderableToFile def file $ toRenderable layout

deltaQToPNG :: Int -> StdGen -> FilePath -> String -> DeltaQ -> IO ()
deltaQToPNG n g file title = toPNG file . layoutStats title . stats n g
