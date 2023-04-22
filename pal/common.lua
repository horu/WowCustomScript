local cs = cs_common
cs.pal = {}
local pal = cs.pal


pal.aura = {}
local aura = pal.aura
aura.Concentration = "Concentration Aura"
aura.Devotion = "Devotion Aura"
aura.Sanctity = "Sanctity Aura"
aura.Retribution = "Retribution Aura"
aura.Shadow = "Shadow Resistance Aura"
aura.Frost = "Frost Resistance Aura"
aura.Fire = "Fire Resistance Aura"
aura.list_all = { aura.Concentration, aura.Sanctity, aura.Devotion, aura.Retribution, aura.Shadow, aura.Frost, aura.Fire }
aura.list_att =                     { aura.Sanctity, aura.Devotion, aura.Retribution, aura.Shadow, aura.Frost, aura.Fire }
aura.list_def =                                    { aura.Devotion, aura.Retribution, aura.Shadow, aura.Frost, aura.Fire }


pal.bless = {}
local bless = pal.bless
bless.Wisdom = "Blessing of Wisdom"
bless.Might = "Blessing of Might"
bless.Salvation = "Blessing of Salvation"
bless.Light = "Blessing of Light"
bless.Kings = "Blessing of Kings"
bless.list_all = { bless.Wisdom, bless.Might, bless.Salvation, bless.Light, bless.Kings }


pal.spn = {}
local spn = pal.spn
spn.Righteous = "Righteous Fury"

spn.Judgement = "Judgement"
spn.CrusaderStrike = "Crusader Strike"
spn.HolyStrike = "Holy Strike"
spn.Exorcism = "Exorcism"


local to_short_list = {}
to_short_list[aura.Concentration] = cs.color.yellow .. "CA" .. "|r"
to_short_list[aura.Devotion] = cs.color.white .. "DA" .. "|r"
to_short_list[aura.Sanctity] = cs.color.red .. "SA" .. "|r"
to_short_list[aura.Retribution] = cs.color.purple .. "RA" .. "|r"
to_short_list[aura.Shadow] = cs.color.purple .. "SH" .. "|r"
to_short_list[aura.Frost] = cs.color.blue .. "FR" .. "|r"
to_short_list[aura.Fire] = cs.color.orange_1 .. "FI" .. "|r"

to_short_list[bless.Wisdom] = cs.color.blue .. "BW" .. "|r"
to_short_list[bless.Might] = cs.color.red .. "BM" .. "|r"
to_short_list[bless.Salvation] = cs.color.white .. "BV" .. "|r"
to_short_list[bless.Light] = cs.color.yellow .. "BL" .. "|r"
to_short_list[bless.Kings] = cs.color.purple .. "BK" .. "|r"

pal.to_short = function(spell_name)
  if not spell_name then
    return cs.color.grey.."XX".."|r"
  end
  return to_short_list[spell_name]
end





-- party blessing

local rebuff_unit = function(unit)
  local buffs = {
    WARRIOR = bless.Might,
    PALADIN = bless.Kings,
    HUNTER = bless.Kings,
    ROGUE = bless.Might,
    SHAMAN = bless.Kings,

    DRUID = bless.Kings,
    PRIEST = bless.Kings,
    MAGE = bless.Kings,
    WARLOCK = bless.Kings,
  }

  local _, class = UnitClass(unit)

  local buff_name = class and buffs[class] or bless.Kings
  if not buff_name then
    cs.print("BUFF NOT FOUND FOR "..class)
    buff_name = bless.Kings
  end

  local buff = cs.Buff.build(buff_name, unit)
  if cs.find_buff(bless.list_all, unit) then
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
























