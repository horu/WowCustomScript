
local cs = cs_common

cs.prof = {}

local slot = {}
slot.MiningPick = 16

---@type cs.Slot
local mining_pick_slot = cs.Slot.build(slot.MiningPick)

---@class cs.prof.Mining
cs.prof.Mining = cs.create_class()

cs.prof.Mining.build = function()
  local mining = cs.prof.Mining:new()

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