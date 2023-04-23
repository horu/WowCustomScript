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
bn.Might = "Blessing of Might"
bn.Salvation = "Blessing of Salvation"
bn.Light = "Blessing of Light"
bn.Kings = "Blessing of Kings"
bn.list_all = cs.dict_to_list(bn, "string")
bn.dict_all = cs.filter_dict(bn, "string")


-- SealName
local sn = {}
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













