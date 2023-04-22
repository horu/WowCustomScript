local cs = cs_common
local pal = cs.pal
local spn = pal.spn

-- SealName
local sn = {}
sn.Righteousness = "Seal of Righteousness"
sn.Crusader = "Seal of the Crusader"
sn.Justice = "Seal of Justice"
sn.Light = "Seal of Light"
sn.Wisdom = "Seal of Wisdom"
sn.list_all = cs.dict_to_list(sn, "string")

local to_short_list = {}
to_short_list[sn.Righteousness] = cs.color.purple .. "SR" .. "|r"
to_short_list[sn.Crusader] = cs.color.orange_1 .. "SC" .. "|r"
to_short_list[sn.Light] = cs.color.yellow .. "SL" .. "|r"
to_short_list[sn.Justice] = cs.color.green .. "SJ" .. "|r"
to_short_list[sn.Wisdom] = cs.color.blue .. "SW" .. "|r"

local to_short = function(spell_name)
  if not spell_name then
    return cs.color.grey .. "XX" .. "|r"
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
    seal.judgement = cs.Spell.build(spn.Judgement)
  end
  seal.target_hp_limit = target_hp_limit or 0

  --cs.debug(seal)

  return seal
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

  return cs.has_debuffs(cs.u.target, self.target_debuff)
end

-- const
function pal.Seal:check_exists()
  return self.buff:check_exists()
end

-- seal can be casted
-- const
function pal.Seal:is_reseal_available()
  if not cs.check_target(cs.t.attackable) then
    return
  end

  local target_hp = UnitHealth(cs.u.target) or 0
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

pal.seal.current_to_string = function()
  local seal_name = cs.find_buff(sn.list_all)
  return to_short(seal_name)
end

pal.seal.init = function()
  ---@type pal.Seal
  pal.seal.Righteousness = pal.Seal.build(sn.Righteousness)
  ---@type pal.Seal
  pal.seal.Crusader = pal.Seal.build(sn.Crusader, nil, nil, true)
  ---@type pal.Seal
  pal.seal.Light = pal.Seal.build(
          sn.Light,
          "Spell_Holy_HealingAura",
          UnitHealthMax(cs.u.player) * 0.2
  )
  ---@type pal.Seal
  pal.seal.Wisdom = pal.Seal.build(
          sn.Wisdom,
          "Spell_Holy_RighteousnessAura",
          UnitHealthMax(cs.u.player) * 0.2
  )
  ---@type pal.Seal
  pal.seal.Justice = pal.Seal.build(sn.Justice, "Spell_Holy_SealOfWrath")
  ---@type pal.Seal[]
  pal.seal.list_all = cs.dict_to_list(pal.seal, "table")
end

