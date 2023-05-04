
local cs = cs_common
local pal = cs.pal
local bn = pal.bn
local spn = pal.spn




---@class pal.Bless
pal.Bless = cs.create_class()

-- Bless can by anavailable, but buffed on the target.
function pal.Bless.try_build(bless_name, unit)
  if not cs.is_spell_available(bless_name) then
    return
  end

  local rebuff_timeout = 5 * 60 - 50
  if string.find(bless_name, "Greater") then
    rebuff_timeout = 15 * 60 - 50
  end

  local bless = pal.Bless:new()
  bless.buff = cs.Buff.build(bless_name, unit, rebuff_timeout)

  return bless
end

function pal.Bless:get_name()
  return self.buff:get_name()
end

function pal.Bless:rebuff()
  if cs.check_combat() and self.buff:check_exists() then
    return cs.Buff.exists
  end

  return self.buff:rebuff()
end

local bless_dict = {}

pal.bless = {}
pal.bless.get_buff = function(spell_name)
  return bless_dict[spell_name]
end






-- party blessing

cs_players_bless_dict = {}

local rebuff_unit = function(unit)

  local _, class = UnitClass(unit)
  local player_name = UnitName(unit) or ""
  local player_bless = cs_players_bless_dict[player_name]

  local exists_buff = cs.find_buff(bn.list_all, unit)
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
      WARRIOR = bn.Might,
      PALADIN = bn.Might,
      HUNTER = bn.Might,
      ROGUE = bn.Might,

      SHAMAN = bn.Might,
      DRUID = bn.Might,

      PRIEST = bn.Wisdom,
      MAGE = bn.Wisdom,
      WARLOCK = bn.Wisdom,
    }


    local buff_name = class and buff_map[class] or bn.Might
    if not buff_name then
      cs.print("BUFF NOT FOUND FOR "..class)
      buff_name = bn.Might
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
    rebuff_unit(unit)
    local class = UnitClass(unit)
    if class == cs.cl.HUNTER or class == cs.cl.WARLOCK then
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

pal.bless.blessing_everywhere = function()
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

pal.bn.get_available = function()
  local list = cs.dict_keys_to_list(bless_dict, "string")
  return list
end




pal.bless.init = function()
  -- self bless list
  for bless_name, spell_name in pairs(bn.dict_all) do
    local bless = pal.Bless.try_build(spell_name)
    -- pal.bless[bless_name] = bless
    if bless then
      -- cs.print(bless:get_name())
      bless_dict[spell_name] = bless
    end
  end
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




















