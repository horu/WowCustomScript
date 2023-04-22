local cs = cs_common
local pal = cs.pal
local cast = pal.cast

-- cs.pal.seal.spell
local spell = {}
spell.Righteousness = "Seal of Righteousness"
spell.Crusader = "Seal of the Crusader"
spell.Justice = "Seal of Justice"
spell.Light = "Seal of Light"
spell.Wisdom = "Seal of Wisdom"
spell.list_all = cs.dict_to_list(spell)

local to_short_list = {}
to_short_list[spell.Righteousness] = cs.color_purple .. "SR" .. "|r"
to_short_list[spell.Crusader] = cs.color_orange_1 .. "SC" .. "|r"
to_short_list[spell.Light] = cs.color_yellow .. "SL" .. "|r"
to_short_list[spell.Justice] = cs.color_green .. "SJ" .. "|r"
to_short_list[spell.Wisdom] = cs.color_blue .. "SW" .. "|r"

local to_short = function(spell_name)
  if not spell_name then
    return cs.color_grey .. "XX" .. "|r"
  end
  return to_short_list[spell_name]
end




-- SEAL
---@class pal.Seal
pal.Seal = cs.create_class()


pal.Seal.build = function(spell, target_debuff, target_hp_limit, no_judgement)
  ---@type pal.Seal
  local seal = pal.Seal:new()

  seal.buff = cs.Buff.build(spell)
  seal.target_debuff = target_debuff
  if not no_judgement then
    seal.judgement = cs.Spell.build(cast.Judgement)
  end
  seal.target_hp_limit = target_hp_limit or 0

  --cs.debug(seal)

  return seal
end

pal.Seal.current_to_string = function()
  local seal_name = cs.find_buff(spell.list_all)
  return to_short(seal_name)
end

-- const
function pal.Seal:get_name()
  return self.buff:get_name()
end

-- const
function pal.Seal:is_judgement_available()
  if not self.judgement then
    -- seal no need to judgement never
    return
  end

  if self:check_target_debuff() then
    return
  end

  return self:is_reseal_available()
end

-- const
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
function pal.Seal:reseal_and_judgement()
  if self:reseal() then
    return
  end

  return self:judgement_it()
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



pal.seal = {}
pal.seal.init = function()
  ---@type pal.Seal
  pal.seal.Righteousness = pal.Seal.build(spell.Righteousness)
  ---@type pal.Seal
  pal.seal.Crusader = pal.Seal.build(spell.Crusader, nil, nil, true)
  ---@type pal.Seal
  pal.seal.Light = pal.Seal.build(
          spell.Light,
          "Spell_Holy_HealingAura",
          UnitHealthMax(cs.u_player) * 0.2
  )
  ---@type pal.Seal
  pal.seal.Wisdom = pal.Seal.build(
          spell.Wisdom,
          "Spell_Holy_RighteousnessAura",
          UnitHealthMax(cs.u_player) * 0.2
  )
  ---@type pal.Seal
  pal.seal.Justice = pal.Seal.build(spell.Justice, "Spell_Holy_SealOfWrath")
  ---@type pal.Seal[]
  pal.seal.list_all = cs.dict_to_list(pal.seal, "table")
end

