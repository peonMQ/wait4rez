# wait4rez

Re-implementation of the old Wait4Rez macro in Lua for those of you who want macro control of character deaths. Code is writting from scratch but inspired by the old wait4rez.inc

When character dies, its set in a waiting for resurrection mode. Once resurrected, it attempts to loot a single corpse.

Runs as a state machine inside other macros or can be called from a stand alone script.

```lua
local wait4Rez = require('wait4rez')

-- add following call into your bot loop
wait4Rez()
```


## Supports the following bind commands

* `/wait4rez` sets character in wait4rez mode
* `/waitforrez` sets character in wait4rez mode
* `/dead` sets character in wait4rez mode
* `/lootCorpse` sets character in loot corpse mode
