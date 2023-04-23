
local cs = cs_common
local pal = cs.pal
local bn = pal.bn
local spn = pal.spn





pal.Bless = cs.create_class()

pal.Bless.rebuff_timeout = 250

function pal.Bless.build(bless_name, unit)
  local bless = cs.Buff.build(bless_name, unit, pal.Bless.rebuff_timeout)

  return bless
end


local bless_dict = {}

pal.bless = {}
pal.bless.get_buff = function(spell_name)
  return bless_dict[spell_name]
end






-- party blessing

local player_buffs = {}

local rebuff_unit = function(unit)

  local player_name = UnitName(unit) or ""
  local buff_name = cs.find_buff(bn.list_all, unit)
  if buff_name then
    player_buffs[player_name] = buff_name
  else
    buff_name = player_buffs[player_name]
  end

  local buffs = {
    WARRIOR = bn.Might,
    PALADIN = bn.Might,
    HUNTER = bn.Might,
    ROGUE = bn.Might,
    SHAMAN = bn.Might,

    DRUID = bn.Wisdom,
    PRIEST = bn.Wisdom,
    MAGE = bn.Wisdom,
    WARLOCK = bn.Wisdom,
  }

  local _, class = UnitClass(unit)

  if not buff_name then
    buff_name = class and buffs[class] or bn.Might
    if not buff_name then
      cs.print("BUFF NOT FOUND FOR "..class)
      buff_name = bn.Might
    end
  end

  local buff = cs.Buff.build(buff_name, unit)
  if cs.find_buff(bn.list_all, unit) then
    return
  end

  local result = buff:rebuff()

  if result == cs.Buff.success then
    cs.print("BUFF: ".. pal.to_short(buff:get_name()) .. " FOR ".. player_name..
            " "..pfUI.api.GetUnitColor(unit) .. class)
  end

  return result
end

local buff_party = function()
  local size = GetNumPartyMembers()
  for i=1, size do
    local unit = "party"..i
    rebuff_unit(unit)
    local pet = "partypet"..i
    rebuff_unit(pet)
  end
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
    -- TODO
    --cs.Buff.build(spn.Righteous):rebuff()
    buff_party()
  end
  if cs.check_target(cs.t.fr_player) then
    rebuff_unit(cs.u.target)
  elseif cs.check_mouse(cs.t.fr_player) then
    rebuff_unit(cs.u.mouseover)
  end
end





pal.bless.init = function()
  -- self bless list
  for bless_name, spell_name in pairs(bn.dict_all) do

    if spell_name ~= bn.Kings or cs.get_talent_rank("Blessing of Kings") == 1 then
      cs.debug(spell_name)
      local bless = pal.Bless.build(spell_name)
      -- pal.bless[bless_name] = bless
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




















