
local cs = cs_common

cs.party = {}

cs_players_data = {}


---@class cs.party.Player
cs.party.Player = cs.class()

function cs.party.Player:build(unit)
  self.unit = unit
  self.name = UnitName(self.unit) or ""

  cs_players_data[self.name] = cs_players_data[self.name] or {}
  self.data = cs_players_data[self.name]
end

local rebuff_unit = function(unit)
  ---@type pal.party.Player
  local player = cs.party.Player:create(unit)
  player:rebuff()
end

local buff_party = function()
  cs.iterate_party(function(unit, i)
    rebuff_unit(unit)
    if cs.cl.get(unit) == cs.cl.HUNTER then
      -- if class == cs.cl.HUNTER or class == cs.cl.WARLOCK then
      local unit_pet = cs.u.partypet[i]
      rebuff_unit(unit_pet)
    end
  end)
end

local alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
local function rebuff_anybody()
  if not cs.check_combat(cs.c.affect) and not cs.check_target(cs.t.exists) then
    for i=1,strlen(alphabet) do
      local name = string.sub(alphabet, i, i)
      TargetByName(name)
      if cs.check_target(cs.t.fr_player) then
        rebuff_unit("target")
      end
      ClearTarget()
    end
  end
end

cs.party.rebuff = function()
  if cs.check_combat(cs.c.affect) then
    return
  end

  if cs.is_in_party() then
    buff_party()
  end

  if cs.check_target(cs.t.fr_player) then
    rebuff_unit(cs.u.target)
  elseif cs.check_mouse(cs.t.fr_player) then
    rebuff_unit(cs.u.mouseover)
  end
end



cs.party.init = function()
end




-- PUBLIC

function cs_rebuff_unit()
  local unit = cs.u.target
  if not cs.check_target(cs.t.exists) then
    unit = cs.u.mouseover
  end
  rebuff_unit(unit)
end

function cs_rebuff_anybody()
  rebuff_anybody()
end