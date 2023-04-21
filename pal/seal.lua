
local cs = cs_common
local pal = cs.pal
local cast = pal.cast



local seal_Righteousness = "Seal of Righteousness"
local seal_Crusader = "Seal of the Crusader"
local seal_Justice = "Seal of Justice"
local seal_Light = "Seal of Light"
local seal_Wisdom = "Seal of Wisdom"
local seal_list_all = { seal_Righteousness, seal_Crusader, seal_Justice, seal_Light, seal_Wisdom }


local to_short_list = {}
to_short_list[seal_Righteousness] = cs.color_purple.."SR".."|r"
to_short_list[seal_Crusader] = cs.color_orange_1.."SC".."|r"
to_short_list[seal_Light] = cs.color_yellow.."SL".."|r"
to_short_list[seal_Justice] = cs.color_green.."SJ".."|r"
to_short_list[seal_Wisdom] = cs.color_blue.."SW".."|r"

local to_short = function(spell_name)
    if not spell_name then
        return cs.color_grey.."XX".."|r"
    end
    return to_short_list[spell_name]
end




-- SEAL
---@class pal.Seal
pal.Seal = cs.create_class()

pal.Seal.build = function(buff, target_debuff, target_hp_limit)
    local seal = pal.Seal:new()

    seal.buff = cs.Buff.build(buff)
    seal.target_debuff = target_debuff
    seal.judgement = cs.Spell.build(cast.Judgement)
    seal.target_hp_limit = target_hp_limit or 0

    cs.debug(seal)

    return seal
end

pal.Seal.init = function()
    pal.Seal.seal_Righteousness = pal.Seal.build(seal_Righteousness)
    pal.Seal.seal_Crusader = pal.Seal.build(seal_Crusader)
    pal.Seal.seal_Light = pal.Seal.build(
            seal_Light,
            "Spell_Holy_HealingAura",
            UnitHealthMax(cs.u_player) * 0.2
    )
    pal.Seal.seal_Wisdom = pal.Seal.build(
            seal_Wisdom,
            "Spell_Holy_RighteousnessAura",
            UnitHealthMax(cs.u_player) * 0.2
    )
    pal.Seal.seal_Justice = pal.Seal.build(seal_Justice,"Spell_Holy_SealOfWrath")
end

pal.Seal.to_string = function()
    local seal_name = cs.find_buff(seal_list_all)
    return to_short(seal_name)
end


-- const
function pal.Seal:is_judgement_available()
    if self:check_target_debuff() then
        return
    end

    return self:is_reseal_available()
end

function pal.Seal:check_target_debuff()
    if not self.target_debuff then
        return
    end

    return cs.has_debuffs(cs.u_target, self.target_debuff)
end

-- const
function pal.Seal:check_exists()
    return self.buff:check_exists()
end

-- seal can be casted
-- const
function pal.Seal:is_reseal_available()
    if not cs.check_target(cs.t_attackable) then
        return
    end

    local target_hp = UnitHealth(cs.u_target) or 0
    return target_hp >= self.target_hp_limit
end

function pal.Seal:reseal()
    if not self:is_reseal_available() then
        return cs.Buff.failed
    end
    return self.buff:rebuff()
end

-- return true on success cast
function pal.Seal:reseal_and_cast(...)
    if self:reseal() then
        return
    end

    local order = cs.SpellOrder.build(unpack(arg))
    return order:cast()
end

-- check the seal exists and the target has no the seal debuff
function pal.Seal:judgement_it()
    if self:check_exists() and self:is_judgement_available() then
        self.judgement:cast()
        return true
    end
end

