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
bless.list_all = { bless.Wisdom, bless.Might, bless.Salvation, bless.Light }


pal.cast = {}
local cast = pal.cast
cast.Righteous = "Righteous Fury"

cast.DivineShield = "Divine Shield"
cast.DivineProtection = "Divine Protection"
cast.BlessingProtection = "Blessing of Protection"
cast.LayOnHands = "Lay on Hands"
cast.shield_list = {cast.DivineShield, cast.BlessingProtection}

cast.Judgement = "Judgement"
cast.CrusaderStrike = "Crusader Strike"
cast.HolyStrike = "Holy Strike"
cast.Exorcism = "Exorcism"


local to_short_list = {}
to_short_list[aura.Concentration] = cs.color_yellow .. "CA" .. "|r"
to_short_list[aura.Devotion] = cs.color_white .. "DA" .. "|r"
to_short_list[aura.Sanctity] = cs.color_red .. "SA" .. "|r"
to_short_list[aura.Retribution] = cs.color_purple .. "RA" .. "|r"
to_short_list[aura.Shadow] = cs.color_purple .. "SH" .. "|r"
to_short_list[aura.Frost] = cs.color_blue .. "FR" .. "|r"
to_short_list[aura.Fire] = cs.color_orange_1 .. "FI" .. "|r"

to_short_list[bless.Wisdom] = cs.color_blue .. "BW" .. "|r"
to_short_list[bless.Might] = cs.color_red .. "BM" .. "|r"
to_short_list[bless.Salvation] = cs.color_white .. "BV" .. "|r"
to_short_list[bless.Light] = cs.color_yellow .. "BL" .. "|r"

pal.to_short = function(spell_name)
  if not spell_name then
    return cs.color_grey.."XX".."|r"
  end
  return to_short_list[spell_name]
end





-- party blessing

local rebuff_unit = function(unit)
  local buffs = {
    WARRIOR = bless.Might,
    PALADIN = bless.Might,
    HUNTER = bless.Might,
    ROGUE = bless.Might,
    SHAMAN = bless.Might,

    DRUID = bless.Wisdom,
    PRIEST = bless.Wisdom,
    MAGE = bless.Wisdom,
    WARLOCK = bless.Wisdom,
  }

  local _, class = UnitClass(unit)

  local buff_name = class and buffs[class] or bless.Might
  if not buff_name then
    print("BUFF NOT FOUND FOR "..class)
    buff_name = bless.Might
  end

  local buff = cs.Buff.build(buff_name, unit)
  if cs.find_buff(bless.list_all, unit) then
    return
  end

  local result = buff:rebuff()

  if result == cs.Buff.success then
    print("BUFF: ".. pal.to_short(buff:get_name()) .. " FOR ".. pfUI.api.GetUnitColor(unit) .. class)
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
  if not cs.check_combat(cs.c_affect) and not cs.check_target(cs.t_exists) then
    for i=1,strlen(alphabet) do
      local name = string.sub(alphabet, i, i)
      TargetByName(name)
      if cs.check_target(cs.t_fr_player) then
        rebuff_unit("target")
      end
      ClearTarget()
    end
  end
end

pal.blessing_everywhere = function()
  if cs.is_in_party() then
    cs.Buff.build(cast.Righteous):rebuff()
    buff_party()
  end
  if cs.check_target(cs.t_fr_player) then
    rebuff_unit(cs.u_target)
  elseif cs.check_mouse(cs.t_fr_player) then
    rebuff_unit(cs.u_mouseover)
  end
end











local EmegryCaster = cs.create_class()

EmegryCaster.build = function()
  local caster = EmegryCaster:new()
  caster.shield_ts = 0
  caster.spell_order = cs.SpellOrder.build(unpack(cast.shield_list))
  caster.lay_spell = cs.Spell.build(cast.LayOnHands)
  return caster
end

function EmegryCaster:has_debuff_protection()
  return cs.has_debuffs(cs.u_target, "Spell_Holy_RemoveCurse")
end

function EmegryCaster:em_buff(lay)
  local casted_shield = self:has_debuff_protection()
  if not casted_shield then
    local spell = self.spell_order:cast(cs.u_player)
    if spell then
      self.shield_ts = spell.cast_ts
      return cs.Buff.success
    end
  end

  if cs.compare_time(8, self.shield_ts) or cs.find_buff({cast.DivineShield, cast.BlessingProtection}) then
    return cs.Buff.exists
  end

  if cs.get_spell_cd(cast.LayOnHands) then
    return cs.Buff.exists
  end

  if not lay then
    return cs.Buff.exists
  end

  cs.debug("Lay")
  self.lay_spell:cast_to_unit(cs.u_player)
  return cs.Buff.success
end



pal.common_init = function()
  pal.sl_em_caster = EmegryCaster.build()
end



-- PUBLIC
function cs_emegrancy()
  pal.sl_em_caster:em_buff(true)
end

function cs_rebuff_unit()
  local unit = cs.u_target
  if not cs.check_target(cs.t_exists) then
    unit = cs.u_mouseover
  end
  rebuff_unit(unit)
end

function cs_rebuff_anybody()
  rebuff_anybody()
end
























