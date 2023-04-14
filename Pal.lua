

local cs = cs_common

-- buffs
local buff_Righteous = "Righteous Fury"

local aura_Concentration = "Concentration Aura"
local aura_Devotion = "Devotion Aura"
local aura_Sanctity = "Sanctity Aura"
local aura_Retribution = "Retribution Aura"
local aura_Shadow = "Shadow Resistance Aura"
local aura_Frost = "Frost Resistance Aura"
local aura_list_all = { aura_Concentration, aura_Sanctity, aura_Devotion, aura_Retribution, aura_Shadow, aura_Frost }
local aura_list_att =                     { aura_Sanctity, aura_Devotion, aura_Retribution, aura_Shadow, aura_Frost }
local aura_list_def =                                    { aura_Devotion, aura_Retribution, aura_Shadow, aura_Frost }

local bless_Wisdom = "Blessing of Wisdom"
local bless_Might = "Blessing of Might"
local bless_Salvation = "Blessing of Salvation"
local bless_list_all = { bless_Wisdom, bless_Might, bless_Salvation }







-- party

local function rebuff_party_member(unit)
    local buffs = {
        WARRIOR = bless_Might,
        PALADIN = bless_Might,
        HUNTER = bless_Might,
        ROGUE = bless_Might,

        DRUID = bless_Wisdom,
        PRIEST = bless_Wisdom,
        MAGE = bless_Wisdom,
        WARLOCK = bless_Wisdom,
    }

    local _, class = UnitClass(unit)

    local buff = class and buffs[class] or bless_Might
    if not buff then
        print("BUFF NOT FOUND FOR "..class)
        buff = bless_Might
    end
    cs.rebuff_target(buff, nil, unit)
end

local function buff_party()
    if cs.in_combat() then return end

    local size = GetNumPartyMembers()
    for i=1, size do
        local unit = "party"..i
        rebuff_party_member(unit)
        local pet = "partypet"..i
        rebuff_party_member(pet)
    end
end








--main


local aura_saver = cs.create_buff_saver(aura_list_all)
local bless_saver = cs.create_buff_saver(bless_list_all)
local function standard_rebuff_attack(aura_list)
    -- cs.rebuff last bless/aura
    cs.rebuff(aura_saver:get_buff(aura_list))
    cs.rebuff(bless_saver:get_buff())
    if cs.is_in_party() then
        cs.rebuff(buff_Righteous)
        buff_party()
    end
end

local function rebuff_heal()
    if cs.in_aggro() or cs.in_combat() then
        cs.rebuff(aura_Concentration)
    end
end







-- SEAL

local seal_Righteousness = "Seal of Righteousness"
local seal_Crusader = "Seal of the Crusader"
local seal_Justice = "Seal of Justice"
local seal_Light = "Seal of Light"
local seal_list_all = { seal_Righteousness, seal_Crusader, seal_Justice, seal_Light }

local function buff_seal(buff, custom_buff_check_list)
    if not cs.check_target(cs.t_attackable) then
        return true
    end
    return cs.rebuff(buff, custom_buff_check_list)
end

local function seal_and_cast(buff, cast_list, custom_buff_check_list)
    if buff_seal(buff, custom_buff_check_list) then
        return
    end

    if type(cast_list) ~= "table" then
        cast(cast_list)
    else
        DoOrder(unpack(cast_list))
    end
end

local function target_has_debuff_seal_Light()
    -- TODO: add remaining check time and recast below 4 sec
    return cs.has_debuffs("target", "Spell_Holy_HealingAura")
end



-- CAST

local cast_CrusaderStrike = "Crusader Strike"
local cast_Judgement = "Judgement"
local cast_HolyStrike = "Holy Strike"
local cast_Exorcism = "Exorcism"

local function build_cast_list(cast_list)
    cast_list = cs.to_table(cast_list)

    local target = UnitCreatureType("target")
    if target == "Demon" or target == "Undead" then
        table.insert(cast_list, 1, cast_Exorcism)
    end
    return cast_list
end


-- attack_wr
local function attack_wr(inside)
    cs.error_disabler:off()
    cs.auto_attack()
    inside()
    cs.error_disabler:on()
end





-- ATTACKS
function attack_rush()
    attack_wr(function()
        cast(cast_HolyStrike)

        local req_aura = { aura_Sanctity }
        standard_rebuff_attack(req_aura)
        if not cs.find_buff(req_aura) then
            return
        end

        -- seal_and_cast(seal_Righteousness, cast_HolyStrike)
        seal_and_cast(seal_Righteousness, build_cast_list({ cast_Judgement, cast_CrusaderStrike }))
    end)
end



function attack_mid()
    attack_wr(function()
        standard_rebuff_attack(aura_list_def)

        if cs.find_buff(seal_Light) and not target_has_debuff_seal_Light() then
            cast(cast_Judgement)
            return
        end

        --if not cs.has_debuffs("target", "Spell_Holy_HealingAura") then
        --if cs.find_buff(seal_Righteousness) then
        --   cast(cast_Judgement)
        --  return
        --  end

        --seal_and_cast(seal_Light, cast_Judgement)
        --return
        --end

        -- seal_and_cast(seal_Righteousness, cast_HolyStrike)
        seal_and_cast(seal_Righteousness, build_cast_list({ cast_CrusaderStrike }))
    end)
end



function attack_fast()
    attack_wr(function()
        standard_rebuff_attack(aura_list_def)
        if not cs.check_target(cs.t_close) then
            return
        end

        if cs.find_buff(seal_Light) and not target_has_debuff_seal_Light() then
            cast(cast_Judgement)
            return
        end

        seal_and_cast(seal_Crusader, cast_CrusaderStrike, {seal_Crusader, seal_Righteousness})
    end)
end


function attack_def()
    attack_wr(function()
        standard_rebuff_attack(aura_list_def)
        if not cs.check_target(cs.t_close) then
            return
        end

        if cs.find_buff(seal_Righteousness) then
            cast(cast_Judgement)
            return
        end

        if not target_has_debuff_seal_Light() then
            seal_and_cast(seal_Light, cast_Judgement)
            return
        end

        buff_seal(seal_Light)
        -- seal_and_cast(seal_Light, cast_HolyStrike)
        -- seal_and_cast(seal_Light, build_cast_list({ }))
    end)
end


function attack_null()
    attack_wr(function()
        standard_rebuff_attack(aura_list_att)
    end)
end

function cast_heal(heal_cast)
    rebuff_heal()
    cast(heal_cast)
end




























