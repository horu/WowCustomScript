local cs = cs_common
cs.pal = {}
local pal = cs.pal

-- AuraName
pal.an = {}
local an = pal.an
an.Concentration = "Concentration Aura"
an.Devotion = "Devotion Aura"
an.Sanctity = "Sanctity Aura"
an.Retribution = "Retribution Aura"
an.Shadow = "Shadow Resistance Aura"
an.Frost = "Frost Resistance Aura"
an.Fire = "Fire Resistance Aura"
an.list_all = { an.Concentration, an.Sanctity, an.Devotion, an.Retribution, an.Shadow, an.Frost, an.Fire }
an.list_att =                   { an.Sanctity, an.Devotion, an.Retribution, an.Shadow, an.Frost, an.Fire }
an.list_def =                                { an.Devotion, an.Retribution, an.Shadow, an.Frost, an.Fire }

-- BlessName
pal.bn = {}
local bn = pal.bn
bn.Wisdom = "Blessing of Wisdom"
bn.Might = "Blessing of Might"
bn.Salvation = "Blessing of Salvation"
bn.Light = "Blessing of Light"
bn.Kings = "Blessing of Kings"
bn.list_all = { bn.Wisdom, bn.Might, bn.Salvation, bn.Light, bn.Kings }

-- SPellName
pal.spn = {}
local spn = pal.spn
spn.Righteous = "Righteous Fury"

spn.Judgement = "Judgement"
spn.CrusaderStrike = "Crusader Strike"
spn.HolyStrike = "Holy Strike"
spn.Exorcism = "Exorcism"


local to_short_list = {}
to_short_list[an.Concentration] = cs.color.yellow .. "CA" .. "|r"
to_short_list[an.Devotion] = cs.color.white .. "DA" .. "|r"
to_short_list[an.Sanctity] = cs.color.red .. "SA" .. "|r"
to_short_list[an.Retribution] = cs.color.purple .. "RA" .. "|r"
to_short_list[an.Shadow] = cs.color.purple .. "SH" .. "|r"
to_short_list[an.Frost] = cs.color.blue .. "FR" .. "|r"
to_short_list[an.Fire] = cs.color.orange_1 .. "FI" .. "|r"

to_short_list[bn.Wisdom] = cs.color.blue .. "BW" .. "|r"
to_short_list[bn.Might] = cs.color.red .. "BM" .. "|r"
to_short_list[bn.Salvation] = cs.color.white .. "BV" .. "|r"
to_short_list[bn.Light] = cs.color.yellow .. "BL" .. "|r"
to_short_list[bn.Kings] = cs.color.purple .. "BK" .. "|r"

pal.to_short = function(spell_name)
  if not spell_name then
    return cs.color.grey.."XX".."|r"
  end
  return to_short_list[spell_name]
end





-- party blessing

local rebuff_unit = function(unit)
  local buffs = {
    WARRIOR = bn.Might,
    PALADIN = bn.Kings,
    HUNTER = bn.Kings,
    ROGUE = bn.Might,
    SHAMAN = bn.Kings,

    DRUID = bn.Kings,
    PRIEST = bn.Kings,
    MAGE = bn.Kings,
    WARLOCK = bn.Kings,
  }

  local _, class = UnitClass(unit)

  local buff_name = class and buffs[class] or bn.Kings
  if not buff_name then
    cs.print("BUFF NOT FOUND FOR "..class)
    buff_name = bn.Kings
  end

  local buff = cs.Buff.build(buff_name, unit)
  if cs.find_buff(bn.list_all, unit) then
    return
  end

  local result = buff:rebuff()

  if result == cs.Buff.success then
    cs.print("BUFF: ".. pal.to_short(buff:get_name()) .. " FOR ".. pfUI.api.GetUnitColor(unit) .. class)
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

pal.blessing_everywhere = function()
  if cs.is_in_party() then
    cs.Buff.build(spn.Righteous):rebuff()
    buff_party()
  end
  if cs.check_target(cs.t.fr_player) then
    rebuff_unit(cs.u.target)
  elseif cs.check_mouse(cs.t.fr_player) then
    rebuff_unit(cs.u.mouseover)
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
























