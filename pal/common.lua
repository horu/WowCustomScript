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
an.list_all = cs.dict_to_list(an, "string")
an.list_att =                   { an.Sanctity, an.Devotion, an.Retribution, an.Shadow, an.Frost, an.Fire }
an.list_def =                                { an.Devotion, an.Retribution, an.Shadow, an.Frost, an.Fire }


-- BlessName
pal.bn = {}
local bn = pal.bn

bn.Wisdom = "Blessing of Wisdom"
bn.Salvation = "Blessing of Salvation"
bn.Sacrifice = "Blessing of Sacrifice"
bn.Might = "Blessing of Might"
bn.Light = "Blessing of Light"
bn.Kings = "Blessing of Kings"

bn.GreaterWisdom = "Greater Blessing of Wisdom"
bn.GreaterSanctuary = "Greater Blessing of Sanctuary"
bn.GreaterSalvation = "Greater Blessing of Salvation"
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
spn.Exorcism = "Exorcism"




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
to_print_list[bn.Salvation] = cs.color.white .. "BV" .. "|r"
to_print_list[bn.Light] = cs.color.yellow .. "BL" .. "|r"
to_print_list[bn.Kings] = cs.color.purple .. "BK" .. "|r"

to_print_list[sn.Righteousness] = cs.color.purple .. "SR" .. "|r"
to_print_list[sn.Crusader] = cs.color.orange_1 .. "SC" .. "|r"
to_print_list[sn.Light] = cs.color.yellow .. "SL" .. "|r"
to_print_list[sn.Justice] = cs.color.green .. "SJ" .. "|r"
to_print_list[sn.Wisdom] = cs.color.blue .. "SW" .. "|r"

pal.to_print = function(spell_name)
  if not spell_name then
    return cs.color.grey.."XX".."|r"
  end
  return to_print_list[spell_name]
end

-- UnitDebuff
pal.ud = {}
pal.ud.CrusaderStrike = cs.spell.UnitBuff.build("Spell_Holy_CrusaderStrike", 5, "Magic", 30)

-- SPell
pal.sp = {}
pal.ud.CrusaderStrike = cs.Spell.build(spn.CrusaderStrike, pal.ud.CrusaderStrike)








