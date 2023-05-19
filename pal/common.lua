local cs = cs_common
cs.pal = {}
local pal = cs.pal

-- AuraName
pal.an = {}
local an = pal.an
an.Concentration = "Concentration Aura"
an.Sanctity = "Sanctity Aura"

an.Devotion = "Devotion Aura"
an.Retribution = "Retribution Aura"
an.Shadow = "Shadow Resistance Aura"
an.Frost = "Frost Resistance Aura"
an.Fire = "Fire Resistance Aura"
an.list_all = cs.dict_to_list(an, "string")
an.list_att =                   { an.Sanctity, an.Devotion, an.Retribution, an.Shadow, an.Frost, an.Fire }
an.list_def =                                { an.Devotion, an.Retribution, an.Shadow, an.Frost, an.Fire }


-- BlessName
pal.bn = {}
local bn = pal.bn

bn.Wisdom = "Blessing of Wisdom"
bn.Salvation = "Blessing of Salvation"
bn.Sanctuary = "Blessing of Sanctuary"
bn.Might = "Blessing of Might"
bn.Light = "Blessing of Light"
bn.Kings = "Blessing of Kings"
bn.Sacrifice = "Blessing of Sacrifice"

bn.GreaterWisdom = "Greater Blessing of Wisdom"
bn.GreaterSalvation = "Greater Blessing of Salvation"
bn.GreaterSanctuary = "Greater Blessing of Sanctuary"
bn.GreaterMight = "Greater Blessing of Might"
bn.GreaterLight = "Greater Blessing of Light"
bn.GreaterKings = "Greater Blessing of Kings"

bn.list_all = cs.dict_to_list(bn, "string")
bn.dict_all = cs.filter_dict(bn, "string")


-- SealName
pal.sn = {}
local sn = pal.sn
sn.Righteousness = "Seal of Righteousness"
sn.Crusader = "Seal of the Crusader"
sn.Justice = "Seal of Justice"
sn.Light = "Seal of Light"
sn.Wisdom = "Seal of Wisdom"
sn.list_all = cs.dict_to_list(sn, "string")


-- SPellName
pal.spn = {}
local spn = pal.spn
spn.Righteous = "Righteous Fury"

spn.Judgement = "Judgement"
spn.CrusaderStrike = "Crusader Strike"
spn.HolyStrike = "Holy Strike"
spn.HammerWrath = "Hammer of Wrath"
spn.HammerJustice = "Hammer of Justice"
spn.HolyShield = "Holy Shield"

spn.Exorcism = "Exorcism"
spn.TurnUndead = "Turn Undead"


-- HealName
pal.hn = {}
pal.hn.DivineShield = "Divine Shield"
pal.hn.DivineProtection = "Divine Protection"
pal.hn.BlessingProtection = "Blessing of Protection"
pal.hn.LayOnHands = "Lay on Hands"
pal.hn.Cleanse = "Cleanse"
pal.hn.FOL = "Flash of Light"
pal.hn.HL = "Holy Light"
pal.hn.shield_list = {pal.hn.DivineShield, pal.hn.BlessingProtection}


local to_print_list = {}
to_print_list[an.Concentration] = cs.color.yellow .. "CA" .. "|r"
to_print_list[an.Devotion] = cs.color.white .. "DA" .. "|r"
to_print_list[an.Sanctity] = cs.color.red .. "SA" .. "|r"
to_print_list[an.Retribution] = cs.color.purple .. "RA" .. "|r"
to_print_list[an.Shadow] = cs.color.purple .. "SH" .. "|r"
to_print_list[an.Frost] = cs.color.blue .. "FR" .. "|r"
to_print_list[an.Fire] = cs.color.orange_1 .. "FI" .. "|r"

to_print_list[bn.Wisdom] = cs.color.blue .. "BW" .. "|r"
to_print_list[bn.Might] = cs.color.red .. "BM" .. "|r"
to_print_list[bn.Salvation] = cs.color.orange .. "BV" .. "|r"
to_print_list[bn.Light] = cs.color.yellow .. "BL" .. "|r"
to_print_list[bn.Sanctuary] = cs.color.white .. "BS" .. "|r"
to_print_list[bn.Kings] = cs.color.purple .. "BK" .. "|r"

to_print_list[bn.GreaterWisdom] = cs.color.blue .. "GBW" .. "|r"
to_print_list[bn.GreaterMight] = cs.color.red .. "GBM" .. "|r"
to_print_list[bn.GreaterSalvation] = cs.color.orange .. "GBV" .. "|r"
to_print_list[bn.GreaterLight] = cs.color.yellow .. "GBL" .. "|r"
to_print_list[bn.GreaterSanctuary] = cs.color.white .. "GBS" .. "|r"
to_print_list[bn.GreaterKings] = cs.color.purple .. "GBK" .. "|r"

to_print_list[sn.Righteousness] = cs.color.purple .. "SR" .. "|r"
to_print_list[sn.Crusader] = cs.color.orange_1 .. "SC" .. "|r"
to_print_list[sn.Light] = cs.color.yellow .. "SL" .. "|r"
to_print_list[sn.Justice] = cs.color.green .. "SJ" .. "|r"
to_print_list[sn.Wisdom] = cs.color.blue .. "SW" .. "|r"

pal.to_print = function(spell_name)
  if spell_name then
    local result = to_print_list[spell_name]
    if result then
      return result
    end
  end
  return cs.color.grey.."XX".."|r"
end

-- UnitDebuff
pal.ud = {}

-- SPell
pal.sp = {}

local buff_conc_aura_on_combat = function()
  -- TODO cast aura on damage
  if cs.check_combat(1) then
    return cs.Buff.build(an.Concentration):rebuff()
  end
  return cs.Buff.exists
end

pal.common = {}
pal.common.init = function()
  pal.sp.CrusaderStrike = cs.Spell.build(spn.CrusaderStrike, function(spell)
    if not cs.has_debuffs(cs.u.target, "Spell_Holy_CrusaderStrike", 5) then
      return true
    end

    local duration_limit = 30 * 0.7
    return not cs.compare_time(duration_limit, spell.cast_ts)
  end)

  pal.sp.HammerWrath = cs.Spell.build(spn.HammerWrath, function(spell)
    if not cs.compare_unit_hp_rate(0.19, cs.u.target) then
      return
    end

    return not cs.services.speed_checker:is_moving()
  end)

  pal.sp.Exorcism = cs.Spell.build(spn.Exorcism, function(spell)
    return cs.check_target(cs.t.undead)
  end)

  pal.sp.TurnUndead = cs.Spell.build(spn.TurnUndead, function(spell)
    local is_moving = cs.services.speed_checker:is_moving()
    local target_is_undead = cs.check_target(cs.t.undead)
    if target_is_undead and not is_moving then
      return buff_conc_aura_on_combat() == cs.Buff.exists
    end
  end)

  pal.sp.HolyShield = cs.Spell.build(spn.HolyShield, function(spell)
    if not cs.slot.id.is_equipped(cs.slot.id.off_hand) then
      return
    end

    local last_phy_ts = cs.damage.analyzer:get_last_ts(cs.damage.st.Physical)
    -- cs.debug(GetTime() - last_phy_ts)
    return cs.compare_time(5, last_phy_ts)
  end)
  pal.sp.HolyShield_force = cs.Spell.build(spn.HolyShield)

  pal.sp.Righteous = cs.Buff.build(pal.spn.Righteous, 28 * 60)

  pal.sp.Cleanse = cs.Spell.build(pal.hn.Cleanse)
  pal.sp.FOL = cs.Spell.build(pal.hn.FOL, function()
    return buff_conc_aura_on_combat() == cs.Buff.exists
  end)
  pal.sp.HL = cs.Spell.build(pal.hn.HL, function()
    return buff_conc_aura_on_combat() == cs.Buff.exists
  end)
end








