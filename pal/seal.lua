local cs = cs_common
local pal = cs.pal
local spn = pal.spn

local sn = pal.sn

-- SEAL
---@class pal.Seal
pal.Seal = cs.create_class()

pal.Seal.no_judgement = 999999

---@param target_hp_limit number percent target hp limit to party sum hp
---@param judgement_target_hp_limit number percent target hp limit to party sum hp for judgement
pal.Seal.build = function(spell, target_debuff, target_hp_limit, judgement_target_hp_limit)
  ---@type pal.Seal
  local seal = pal.Seal:new()

  ---@type cs.Buff
  seal.buff = cs.Buff.build(spell)
  seal.target_debuff = target_debuff
  ---@type cs.Spell
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
  if not self:check_exists() then
    return
  end

  if self:check_target_debuff() then
    return
  end

  local limit = from_other and self.target_hp_limit or self.judgement_target_hp_limit
  return not cs.check_target_hp(limit * cs.get_party_hp_sum())
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

  return not cs.check_target_hp(self.target_hp_limit * cs.get_party_hp_sum())
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

  return self:wait_cd_and_judgement()
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
function pal.Seal:wait_cd_and_judgement(from_other)
  if self:is_judgement_available(from_other) then
    self.judgement:cast()
    return true
  end
end

function pal.Seal:judgement(from_other)
  if self:is_judgement_available(from_other) then
    return self.judgement:cast()
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
  --TODO: add party korrect dependency
  pal.seal.Light = pal.Seal.build(sn.Light, "Spell_Holy_HealingAura", 0.1, 0.3)
  ---@type pal.Seal
  pal.seal.Wisdom = pal.Seal.build(sn.Wisdom, "Spell_Holy_RighteousnessAura", 0.1, 0.3)
  ---@type pal.Seal
  pal.seal.Justice = pal.Seal.build(sn.Justice, "Spell_Holy_SealOfWrath")
  ---@type pal.Seal[]
  pal.seal.list_all = cs.dict_to_list(pal.seal, "table")
end

