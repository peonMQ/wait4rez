local mq = require 'mq'
local logger = require 'utils/logging'
local mqutil = require 'utils/mqhelpers'
local broadcast = require 'broadcast/broadcast'

local Wait4RezStates = {
  Idle = "IDLE",
  Waiting4Rez = "WAITING4REZ",
  Looting = "LOOTING",
}

local state = Wait4RezStates.Idle

local function diedEvent()
	broadcast.Fail("%s died, awaiting rezs.", mq.TLO.Me.Name())
  mq.cmd("/beep")
  state = Wait4RezStates.Waiting4Rez
end

mq.event("slain", "You have been slain by #*#", diedEvent)
mq.event("died", "You died.", diedEvent)

local function doEvents()
  mq.doevents("slain")
  mq.doevents("died")
end

local function waitToZone()
	logger.Debug("Waiting to zone.")
  local me = mq.TLO.Me.Name()
  repeat
    mq.delay(100)
  until mq.TLO.Spawn(me.."'s").ID()

  mq.delay(500)
  logger.Debug("Completed zoneing to corpse.")
end

local function doLoot()
  local me = mq.TLO.Me.Name()
  if mqutil.EnsureTarget(mq.TLO.Spawn(me.."'s").ID()) then
    logger.Debug("Corpse distance <%s>", mq.TLO.Target.Distance())
    if mq.TLO.Target.Distance() and mq.TLO.Target.Distance() < 100 then
      while mq.TLO.Target.Distance() > 15 do
        mq.cmd("/corpse")
        mq.delay(20)
      end

      mq.cmd("/loot")
      mq.delay("5s", function() return mq.TLO.Window("LootWnd") and mq.TLO.Window("LootWnd").Open() end)
      mq.delay("5s", function() return mq.TLO.Corpse.Items() ~= nil end)
      mq.delay(500)
      if not mq.TLO.Window("LootWnd") or not mq.TLO.Corpse.Items then
        logger.Debug("Could not open loot window.")
      else
        mq.cmd("/notify LootWnd LootAllButton leftmouseup")
        mq.delay("30s", function() return not mq.TLO.Window("LootWnd").Open() end)
      end
    else
      logger.Debug("Corpse out of range. Could not loot.")
      broadcast.Fail("Corpse out of range. Could not loot.")
    end
  end
  state = Wait4RezStates.Idle
end

local function doWait4Rez()
  broadcast.Warn("Ready for rezz.")
  mq.cmd("/consent guild")

  repeat
    mq.delay(10)
  until mq.TLO.Window("ConfirmationDialogBox").Open() and mq.TLO.Window("ConfirmationDialogBox").Child("cd_textoutput").Text():find("percent)")

  mq.cmd("/nomodkey /notify ConfirmationDialogBox Yes_Button leftmouseup")
  waitToZone()
  doLoot()
  state = Wait4RezStates.Idle
  broadcast.Success("Ressurected, looted corpse and ready for action.")
end


local function createAliases()
  mq.unbind('/wait4rez')
  mq.unbind('/waitforrez')
  mq.unbind('/dead')
  mq.unbind('/lootCorpse')
  mq.bind("/wait4rez", function() state = Wait4RezStates.Waiting4Rez end)
  mq.bind("/waitforrez", function() state = Wait4RezStates.Waiting4Rez end)
  mq.bind("/dead", function() state = Wait4RezStates.Waiting4Rez end)
  mq.bind("/lootCorpse", function() state = Wait4RezStates.Looting end)
end

createAliases()

local function wait4RezStateMachine()
  doEvents()

  if state == Wait4RezStates.Idle then
    return
  end

  if state == Wait4RezStates.Waiting4Rez then
    doWait4Rez() 
  end

  if state == Wait4RezStates.Looting then
    doLoot()
  end
end

return wait4RezStateMachine