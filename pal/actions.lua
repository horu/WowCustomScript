
local cs = cs_common
local pal = cs.pal
local spn = pal.spn
local seal = pal.seal

---@type pal.Seal[]
local debuffed_seal_list = {}



---@class Action
local Action = cs.create_class()

---@param main_seal pal.Seal
Action.build = function(main_seal, run_func)
  local action = Action:new()

  action.main_seal = main_seal
  ---@type function(self, state_type)
  action.run = run_func

  --cs.debug(action)
  return action
end

---@param state_type pal.stt
function Action:_seal_action(state_type)
  if not cs.check_target(cs.t.close_10) then
    -- the target is far away
    return
  end

  if seal.Righteousness:judgement_it() then
    -- First wait Righteousness seal to judgement on the target ( damage )
    return
  end

  if self.main_seal:reseal() == cs.Buff.success then
    -- reseal and wait when it will be casted
      return
  end

  -- cast spells
  if state_type == pal.stt.def then
    if pal.sp.HolyShield:cast() then return end
  end

  if not self:_has_any_seal_debuff() then
    -- the target has no debuffs. judgement it.
    if self:_judgement_other() then
      -- wait another seal to judgement on the target
      return
    end

    self.main_seal:judgement_it()
  end
end

function Action:_judgement_other()
  for _, it_seal in pairs(seal.list_all) do
    if it_seal ~= self.main_seal then
      if it_seal:judgement_it(true) then
        return true
      end
    end
  end
end

function Action:_has_any_seal_debuff()
  for _, it_seal in pairs(debuffed_seal_list) do
    if it_seal:check_target_debuff() then
      return true
    end
  end
end



pal.actions = {}
pal.actions.init = function()
  debuffed_seal_list = { seal.Light, seal.Wisdom, seal.Justice }

  pal.actions.damage = Action.build(seal.Righteousness, function(self, state_type)
    if not cs.check_target(cs.t.close_30) then return end

    self.cast_order:cast()

    local current_seal = pal.seal.get_current()
    if not current_seal or current_seal == pal.sn.Righteousness then
      self.main_seal:reseal_and_judgement()
    end

  end)
  pal.actions.damage.cast_order = cs.SpellOrder.build(
          pal.sp.Exorcism, pal.sp.HammerWrath, spn.HolyStrike, pal.sp.HolyShield, pal.sp.CrusaderStrike)

  pal.actions.right = Action.build(seal.Righteousness, function(self, state_type)
    -- TODO: dont cast judgement if no mana to rebuff Righteousness
    if not cs.check_target(cs.t.close_30) then return end

    if state_type ~= pal.stt.damage then
      if self:_judgement_other() then
        return
      end
    end

    self.main_seal:reseal_and_judgement()
  end)

  pal.actions.crusader = Action.build(seal.Crusader, function(self, state_type)
    if not cs.check_target(cs.t.close_10) then return end

    if self:_judgement_other() then
      return
    end

    self.main_seal:reseal()
  end)

  pal.actions.wisdom = Action.build(seal.Wisdom, function(self, state_type)
    self:_seal_action(state_type, {seal.Wisdom, seal.Light, seal.Justice})
  end)

  pal.actions.light = Action.build(seal.Light, function(self, state_type)
    self:_seal_action(state_type, {seal.Light, seal.Wisdom, seal.Justice})
  end)

  pal.actions.justice = Action.build(seal.Justice, function(self, state_type)
    self:_seal_action(state_type, {seal.Justice, seal.Light, seal.Wisdom})
  end)

  pal.actions.null = Action.build(seal.Wisdom, function(self, state_type)
    -- cs.cast(spn.HolyStrike)
  end)

  pal.actions.splash = Action.build(seal.Wisdom, function(self, state_type)
    cs.auto_attack_nearby()
    -- TODO: add detect wisdom/light
    pal.actions.wisdom:_seal_action(state_type)
    pal.sp.HolyShield_force:cast()
  end)

  pal.actions.stun = Action.build(seal.Crusader, function(self, state_type)
    self.cast_order:cast()
  end)
  pal.actions.stun.cast_order = cs.SpellOrder.build(pal.sp.TurnUndead, pal.spn.HammerJustice)

  pal.actions.dict = cs.filter_dict(pal.actions, "table")
end


-- PUBLIC
function cs_free_action(name)
  local action = pal.actions[name]
  action:run(pal.stt.damage)
end

