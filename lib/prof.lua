
local cs = cs_common
cs.prof = {}



---@type cs.Slot
local mining_pick_slot = cs.Slot.build(cs.slot.prof)



---@class cs.prof.Mining
cs.prof.Mining = cs.create_class()

cs.prof.Mining.build = function()
  local mining = cs.prof.Mining:new()

  --local f = cs.create_simple_frame()
  --f:RegisterEvent("SPELLCAST_START")
  --f:RegisterEvent("SPELLCAST_FAILED")
  --f:RegisterEvent("SPELLCAST_INTERRUPTED")
  --f:RegisterEvent("SPELLCAST_STOP")
  --f:SetScript("OnEvent",function()
  --  cs.debug({event,arg1,arg2,arg3,arg4,arg5})
  --end)

  cs.st_player_cast_detector:subscribe(mining, mining._cast_detected)

  return mining
end

---@param unit_cast cs.spell.UnitCast
function cs.prof.Mining:_cast_detected(unit_cast)
  if not unit_cast:find_icon_name("Trade_Mining") then
    return
  end

  mining_pick_slot:try_use()
end



local mining = cs.prof.Mining.build()