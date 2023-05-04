local cs = cs_common
local pal = cs.pal
local spn = pal.spn

local sn = pal.sn

-- SEAL
---@class pal.Seal
pal.Seal = cs.create_class()

pal.Seal.no_judgement = 999999

pal.Seal.build = function(spell, target_debuff, target_hp_limit, judgement_target_hp_limit)
  ---@type pal.Seal
  local seal = pal.Seal:new()

  seal.buff = cs.Buff.build(spell)
  seal.target_debuff = target_debuff
  seal.judgement = cs.Spell.build(spn.Judgement)
  seal.judgement_target_hp_limit = judgement_target_hp_limit or 0
  seal.target_hp_limit = target_hp_limit or 0

  --cs.debug(seal)

  return seal
end

--region
-- const
function pal.Seal:get_name()
  return self.buff:get_name()
end

-- const
function pal.Seal:is_judgement_available(from_other)
  if self:check_target_debuff() then
    return
  end

  local limit = from_other and self.target_hp_limit or self.judgement_target_hp_limit
  return not cs.check_target_hp(limit)
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

  return not cs.check_target_hp(self.target_hp_limit)
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
    return true
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
function pal.Seal:judgement_it(from_other)
  if self:check_exists() and self:is_judgement_available(from_other) then
    self.judgement:cast()
    return true
  end
end
--endregion


pal.seal = {}

pal.seal.get_current = function()
  local seal_name = cs.find_buff(sn.list_all)
  return seal_name
end

pal.seal.init = function()
  ---@type pal.Seal
  pal.seal.Righteousness = pal.Seal.build(sn.Righteousness)
  ---@type pal.Seal
  pal.seal.Crusader = pal.Seal.build(sn.Crusader, nil, nil, pal.Seal.no_judgement)
  ---@type pal.Seal
  pal.seal.Light = pal.Seal.build(
          sn.Light,
          "Spell_Holy_HealingAura",
          UnitHealthMax(cs.u.player) * 0.1,
          UnitHealthMax(cs.u.player) * 0.5
          -- TODO: add party dependenc
  )
  ---@type pal.Seal
  pal.seal.Wisdom = pal.Seal.build(
          sn.Wisdom,
          "Spell_Holy_RighteousnessAura",
          UnitHealthMax(cs.u.player) * 0.1,
          UnitHealthMax(cs.u.player) * 0.5
  )
  ---@type pal.Seal
  pal.seal.Justice = pal.Seal.build(sn.Justice, "Spell_Holy_SealOfWrath")
  ---@type pal.Seal[]
  pal.seal.list_all = cs.dict_to_list(pal.seal, "table")
end

