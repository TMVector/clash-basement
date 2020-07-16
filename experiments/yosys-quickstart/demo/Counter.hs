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


-- We would like to generate 'assume'/'restrict'/'assert' verilog statements
-- from within Clash.
-- Also useful to do this in initial blocks?

topEntity clk = withClockResetEnable @System clk rst enableGen $
  svaAssertion
  -- . preludeAssertion -- symbiyosys doesn't like $display
  $ c
  where
    rst = resetGen
    c = counter

    svaAssertion =
      Verif.hideAssertion
      . Verif.check clk rst "svaAssert" Verif.SVA
      . Verif.assert
      . Verif.always
      $ c .<. pure 32

    preludeAssertion =
      (\p -> C.assert "preludeAssert" p (pure True))
      $ c .<. pure 32

-- | Counter implementation copied from a Yosys quickstart example.
counter :: HiddenClockResetEnable dom => Signal dom (Unsigned 6)
counter = medvedev f 0 $ pure ()
  where
    f 32 () = 0
    f v ()  = v + 1
