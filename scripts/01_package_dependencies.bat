REM --------------------------------------------------------
REM MANGED DEPENDENCIES (PICK EITHER MANAGED OR UNLOCKED)  -
REM --------------------------------------------------------
REM Lightweight - Apex SOAP Util@0.3.0-1
sf package install --package "04tP30000014Ev3IAE" -w 30

REM -------------------------------------------------------------------------------------------
REM                   UNLOCKED DEPENDENCIES (PICK EITHER MANAGED OR UNLOCKED)                 -
REM -------------------------------------------------------------------------------------------

REM Lightweight - Apex SOAP Util (Unlocked)@0.3.0-1
sf package install --package "04tP30000014EwfIAE" -w 30

REM --------------------------------------------------------
REM                  ASSIGN PERMISSION SETS                -
REM --------------------------------------------------------
REM DEPENDENCIES
sf org assign permset --name "Lightweight_SOAP_Util"
sf org assign permset --name "Lightweight_Agent_Util"