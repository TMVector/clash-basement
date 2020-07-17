{-# LANGUAGE DataKinds         #-}
{-# LANGUAGE DeriveAnyClass    #-}
{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE GADTs             #-}
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


topEntity :: Clock System -> Reset System -> Signal System (Unsigned 8) -> Signal System (Unsigned 8)
topEntity clk rst din = withClockResetEnable @System clk rst enableGen $ assertions demo din

assertions
  :: HiddenClockResetEnable dom
  => (Signal dom (Unsigned 8) -> Signal dom (Unsigned 8))
  -> Signal dom (Unsigned 8)
  -> Signal dom (Unsigned 8)
assertions f inp = withAssertions out
  where
    out = f inp

    -- withAssertions :: Signal System a -> Signal System a
    withAssertions =
      Verif.checkI hasClock hasReset "p0" Verif.SVIA assumeResetOnInit
      . Verif.checkI hasClock hasReset "p1" Verif.SVIA assertTwoLsbAlwaysLow

    assertTwoLsbAlwaysLow = Verif.assert . whenOutOfReset $ out <&> \v ->
       (truncateB v :: Unsigned 2) == 0

-- | Only check the given property when the reset isn't asserted.
whenOutOfReset :: (HiddenReset dom, AssertionValue dom a) => a -> Assertion dom
whenOutOfReset a = unsafeToLowPolarity hasReset ||| a

-- | Assume reset is asserted on the first cycle.
assumeResetOnInit :: HiddenClockResetEnable dom => Property dom
assumeResetOnInit = Verif.assume $
      register False (pure True) .||. unsafeFromReset hasReset

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
