{-# LANGUAGE DataKinds         #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications  #-}

module Counter where

import qualified Prelude                     as P

import           Clash.Prelude               hiding (assert, (&&), (||))
import           Clash.Prelude.Moore         (medvedev)
import qualified Clash.Prelude.Testbench     as C

import qualified Clash.Explicit.Verification as Verif
-- (( #|# ), (|&|), (|->), (|||), (~>))
import           Clash.Verification.DSL


topEntity clk = withClockResetEnable @System clk rst enableGen $
  withAssertions c
  where
    rst = resetGen
    c = counter

    withAssertions =
      Verif.hideAssertion
      . Verif.check clk rst "upperBound" Verif.SVIA
      . Verif.assert
      $ c .<. pure 32

-- | Counter implementation copied from a Yosys quickstart example.
counter :: HiddenClockResetEnable dom => Signal dom (Unsigned 6)
counter = medvedev f 0 $ pure ()
  where
    f 32 () = 0
    f v ()  = v + 1
