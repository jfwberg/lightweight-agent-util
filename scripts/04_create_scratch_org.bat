REM *****************************
REM      INSTALL ON TEST ORG   
REM *****************************

REM Config
SET alias=lightweightagentutil
SET devHub=devHubAlias
SET dependencyOne=04tP30000014Ev3IAE
SET permSetName=Lightweight_Agent_Util

REM create scratch org
sf org:create:scratch --definition-file config\project-scratch-def.json --alias "%alias%" --duration-days 7 --set-default --json

REM Install the package dependencies
sf package:install -p %dependencyOne% --target-org %alias% --wait 30

REM Push Code
sf project:deploy:start --target-org "%alias%"

REM Assign permission set
sf org assign permset --name "%permSetName%" --target-org "%alias%"

REM Open Org
sf org open --target-org "%alias%"
