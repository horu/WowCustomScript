
local cs = cs_common
cs.prof = {}



---@class cs.prof.Mining
cs.prof.Mining = cs.class()
function cs.prof.Mining:build()
  --local f = cs.create_simple_frame()
  --f:RegisterEvent("SPELLCAST_START")
  --f:RegisterEvent("SPELLCAST_FAILED")
  --f:RegisterEvent("SPELLCAST_INTERRUPTED")
  --f:RegisterEvent("SPELLCAST_STOP")
  --f:SetScript("OnEvent",function()
  --  cs.debug({event,arg1,arg2,arg3,arg4,arg5})
  --end)

  --cs.st_player_cast_detector:subscribe(mining, mining._cast_detected)
end


function cs.prof.Mining:buff()
  if GetTrackingTexture() then
    return cs.Buff.exists
  end

  cs.cast("Find Minerals")
  cs_print("TRACK: Find Minerals")
  return cs.Buff.success
end

---@param unit_cast cs.spell.UnitCast
function cs.prof.Mining:_cast_detected(unit_cast)
  if not unit_cast:find_icon_name("Trade_Mining") then
    return
  end

  cs.slot.set_holder:equip_set(cs.slot.Set.id.mining)
end

cs.prof.mining = cs.prof.Mining:create()



-----@class cs.prof.Skinning
--cs.prof.Skinning = cs.class()
--function cs.prof.Skinning:build()
--  local f = cs.create_simple_frame()
--  f:RegisterEvent("LOOT_CLOSED")
--  f:SetScript("OnEvent",function()
--    cs.debug(1)
--    cs.cast("Skinning")
--  end)
--end
--
--cs.prof.skinning = cs.prof.Skinning:create()

cs.prof.test = function()
  --cs.prof.mining:_cast_detected({find_icon_name = function(self, name) return name == "Trade_Mining" end})
end