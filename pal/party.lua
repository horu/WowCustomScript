
local cs = cs_common
local pal = cs.pal

cs_players_bless_dict = {}

local rebuff_unit = function(unit)
  -- TODO: rebuff with other pal
  local _, class = UnitClass(unit)
  class = class or ""
  local player_name = UnitName(unit) or ""
  local player_bless = cs_players_bless_dict[player_name]

  local exists_buff = cs.find_buff(pal.bn.list_all, unit)
  if exists_buff then
    if not player_bless or player_bless:get_name() ~= exists_buff then
      player_bless = pal.Bless.try_build(exists_buff, unit)
      if not player_bless then
        -- unavailable bless. can not rebuff it.
        return
      end

      cs_players_bless_dict[player_name] = player_bless
    end

    return
  end

  if not player_bless then
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

    player_bless = pal.Bless.try_build(buff_name, unit)
    cs_players_bless_dict[player_name] = player_bless
  end

  local result = player_bless:rebuff()

  if result == cs.Buff.success then
    local short = pal.to_print(player_bless:get_name())
    local color = pfUI.api.GetUnitColor(unit)
    cs.print(string.format("BUFF: %s FOR %s [%s] %s", short, player_name, unit, color .. class))
  end

  return result
end

local buff_party = function()
  cs.iterate_party(function(unit, i)
    if cs.check_unit(cs.t.dead, unit) or not cs.check_unit(cs.t.close_30, unit) then
      return
    end

    rebuff_unit(unit)
    local _, class = UnitClass(unit)
    if class == cs.cl.HUNTER then
      -- if class == cs.cl.HUNTER or class == cs.cl.WARLOCK then
      rebuff_unit(cs.u.partypet[i])
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

pal.party = {}
pal.party.rebuff = function()
  if cs.is_in_party() then
    pal.sp.Righteous:rebuff()
    buff_party()
  end
  if cs.check_target(cs.t.fr_player) then
    rebuff_unit(cs.u.target)
  elseif cs.check_mouse(cs.t.fr_player) then
    rebuff_unit(cs.u.mouseover)
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
  cs.debug(bless_name)
end

local buff_bar



pal.party.init = function()
  buff_bar = pal.party.BuffBar:create()
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

function cs_buff_bar()
  buff_bar:show()
end