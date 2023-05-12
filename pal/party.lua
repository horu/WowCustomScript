
local cs = cs_common
local pal = cs.pal

pal.party = {}

cs_players_data = {}


---@class pal.party.Player
pal.party.Player = cs.class()

function pal.party.Player:build(unit)
  self.unit = unit
  self.name = UnitName(self.unit) or ""

  cs_players_data[self.name] = cs_players_data[self.name] or {}
  self.data = cs_players_data[self.name]
end

function pal.party.Player:set_bless(bless_name)
  self.data.bless = pal.Bless.try_build(bless_name, self.unit)
  assert(self.data.bless)
end

function pal.party.Player:rebless()
  if cs.check_unit(cs.t.dead, self.unit) or not cs.check_unit(cs.t.close_30, self.unit) then
    return cs.Buff.failed
  end

  local _, class = UnitClass(self.unit)
  class = class or "WARRIOR"

  if not self.data.bless then
    local buff_map = {
      WARRIOR = pal.bn.Might,
      PALADIN = pal.bn.Might,
      HUNTER = pal.bn.Might,
      ROGUE = pal.bn.Might,

      SHAMAN = pal.bn.Might,
      DRUID = pal.bn.Might,

      PRIEST = pal.bn.Wisdom,
      MAGE = pal.bn.Wisdom,
      WARLOCK = pal.bn.Wisdom,
    }


    local buff_name = class and buff_map[class] or pal.bn.Might
    if not buff_name then
      cs.print("BUFF NOT FOUND FOR "..class)
      buff_name = pal.bn.Might
    end

    self:set_bless(buff_name)
  end

  local result = self.data.bless:rebuff()

  if result == cs.Buff.success then
    local short = pal.to_print(self.data.bless:get_name())
    local color = pfUI.api.GetUnitColor(self.unit)
    cs.print(string.format("BUFF: %s FOR %s [%s] %s", short, self.name, self.unit, color .. class))
  end

  return result
end

local rebless_unit = function(unit)
  ---@type pal.party.Player
  local player = pal.party.Player:create(unit)
  player:rebless()
end

local buff_party = function()
  cs.iterate_party(function(unit, i)
    rebless_unit(unit)
    local _, class = UnitClass(unit)
    if class == cs.cl.HUNTER then
      -- if class == cs.cl.HUNTER or class == cs.cl.WARLOCK then
      local unit_pet = cs.u.partypet[i]
      rebless_unit(unit_pet)
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
        rebless_unit("target")
      end
      ClearTarget()
    end
  end
end

pal.party.rebuff = function()
  if cs.is_in_party() then
    pal.sp.Righteous:rebuff()
    buff_party()
  end
  if cs.check_target(cs.t.fr_player) then
    rebless_unit(cs.u.target)
  elseif cs.check_mouse(cs.t.fr_player) then
    rebless_unit(cs.u.mouseover)
  end
end



---@class pal.party.BuffBar
pal.party.BuffBar = cs.class()

function pal.party.BuffBar:build()
  local texture_dict = {} -- texture: bless_name

  local bless_name_list = pal.bn.get_available()
  for _, name in pairs(bless_name_list) do
    ---@type pal.Bless
    local bless = pal.bless.get_buff(name)
    local texture = bless:get_texture()
    texture_dict[texture] = bless:get_name()
  end

  self.bar = cs.spell.Bar:create(texture_dict, self, self._on_click)
end

function pal.party.BuffBar:show()
  self.bar:show()
end

function pal.party.BuffBar:_on_click(bless_name)
  if not cs.check_target(cs.t.exists) then
    return
  end

  local player = pal.party.Player:create(cs.u.target)
  player:set_bless(bless_name)
  player:rebless()
end

local buff_bar



pal.party.init = function()
  buff_bar = pal.party.BuffBar:create()
end




-- PUBLIC

function cs_rebless_unit()
  local unit = cs.u.target
  if not cs.check_target(cs.t.exists) then
    unit = cs.u.mouseover
  end
  rebless_unit(unit)
end

function cs_rebuff_anybody()
  rebuff_anybody()
end

function cs_buff_bar()
  buff_bar:show()
end