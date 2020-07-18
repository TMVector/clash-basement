{-# LANGUAGE DataKinds         #-}
{-# LANGUAGE DeriveAnyClass    #-}
{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TypeApplications  #-}

module Demo where

import           Data.Functor                ((<&>))
import qualified Prelude                     as P

import qualified Clash.Explicit.Prelude      as C
import           Clash.Prelude               hiding (assert, (&&), (||))
import           Clash.Prelude.Moore         (moore)
import qualified Clash.Prelude.Testbench     as C

import           Clash.Explicit.Verification (Assertion, AssertionValue,
                                              Property)
import qualified Clash.Explicit.Verification as Verif
import           Clash.Verification.DSL


topEntity clk rst = assertions clk rst (withClockResetEnable @System clk rst enableGen demo)

assertions
  :: KnownDomain dom
  => Clock dom
  -> Reset dom
  -> (Signal dom (Unsigned 8) -> Signal dom (Unsigned 8))
  -> Signal dom (Unsigned 8)
  -> Signal dom (Unsigned 8)
assertions clk rst f inp = withAssertions out
  where
    out = f inp

    withAssertions =
      Verif.checkI clk rst "p0" Verif.SVIA (Verif.assume resetAssertedOnInit)
      . Verif.checkI clk rst "p1" Verif.SVIA (Verif.assert twoLsbAlwaysLow)

    twoLsbAlwaysLow = whenOutOfReset rst $ out <&> \v ->
      (truncateB v :: Unsigned 2) == 0

    resetAssertedOnInit = withClockResetEnable clk rst enableGen $
      register False (pure True) .||. unsafeFromReset hasReset

-- | Only check the given property when the reset isn't asserted.
whenOutOfReset :: (KnownDomain dom, AssertionValue dom a) => Reset dom -> a -> Assertion dom
whenOutOfReset rst a = unsafeToLowPolarity rst ||| a

data DemoState = DemoState
    { buffer :: Unsigned 8
    , state  :: Index 3
    , output :: Unsigned 8
    }
    deriving (Generic, NFDataX)

demo
  :: HiddenClockResetEnable dom
  => Signal dom (Unsigned 8)
  -> Signal dom (Unsigned 8)
demo = moore transitionF output initState
  where
    initState = DemoState
      { buffer = errorX "DemoState.buffer: uninitialised"
      , state = 0
      , output = 0
      }
    transitionF s@DemoState{..} inp = case state of
      0 -> s
        { buffer = inp
        , state = 1
        }
      1 ->
        if (truncateB buffer :: Unsigned 2) /= 0 then
          s { buffer = buffer + 1 }
        else
          s { state = 2 }
      2 -> s
        { output = output + buffer
        , state = 0
        }
