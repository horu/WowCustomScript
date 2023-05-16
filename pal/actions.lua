
local cs = cs_common
local pal = cs.pal
local spn = pal.spn
local seal = pal.seal



---@class Action
local Action = cs.class()

---@param main_seal pal.Seal
function Action:build(main_seal, run_func, init_func)
  ---@type pal.Seal
  self.main_seal = main_seal
  ---@type function(self, state_type)
  self.run = run_func

  if init_func then
    init_func(self)
  end
end

function Action:get_seal_name()
  return self.main_seal:get_name()
end

---@param state_type pal.stt
function Action:_seal_action(state_type)
  if not cs.check_target(cs.t.close_30) then
    -- the target is far away
    return
  end

  if seal.Righteousness:wait_cd_and_judgement() then
    -- First wait Righteousness seal to judgement on the target ( damage )
    return
  end

  if not pal.seal.get_current() then
    self.main_seal:reseal()
  end

  -- cast shield for def
  if pal.sp.HolyShield:cast() then return end

  if cs.is_low_mana() then
    return
  end

  if not self:_has_any_seal_debuff() then
    -- the target has no debuffs. judgement it.
    if self:_judgement_other() then
      -- wait another seal to judgement on the target
      return
    end

    if self.main_seal:wait_cd_and_judgement() then return end
  end

  self.main_seal:reseal()
end

function Action:_judgement_other()
  for _, it_seal in pairs(seal.list_all) do
    if it_seal ~= self.main_seal then
      if it_seal:wait_cd_and_judgement(true) then
        return true
      end
    end
  end
end

function Action:_has_any_seal_debuff()
  for _, it_seal in pairs(seal.list_all) do
    if it_seal:check_target_debuff() then
      return true
    end
  end
end



---@class FreeAction
local FreeAction = cs.class()

---@param main_seal pal.Seal
function FreeAction:build(default_action, run_func, init_func)
  ---@type Action
  self.saved_action = default_action
  ---@type function(self, state_type)
  self.run = run_func

  if init_func then
    init_func(self)
  end
end

function FreeAction:get_seal_name()
  return
end

function FreeAction:update_saved_action(except_action)
  local cur_seal_name = pal.seal.get_current()
  if not cur_seal_name then
    return
  end

  for _, action in pairs(pal.actions.dict) do
    local seal_name = action:get_seal_name()
    if action ~= except_action and seal_name == cur_seal_name then
      self.saved_action = action
      return
    end
  end
end

function FreeAction:run_saved_action(state_type)
  self.saved_action:run(state_type)
end



pal.actions = {}
pal.actions.init = function()
  pal.actions.damage = Action:create(seal.Righteousness, function(self, state_type)
    if not cs.check_target(cs.t.close_30) then return end

    if self.cast_order:cast() then return end

    local current_seal = pal.seal.get_current()
    if not current_seal or current_seal == pal.sn.Righteousness then
      if self.main_seal:reseal() then return end
      if not cs.is_low_mana() then
        if self.main_seal:judgement_it() then return end
      end
    end

    pal.sp.CrusaderStrike:cast()

  end, function(self)
    self.cast_order = cs.SpellOrder.build(pal.sp.Exorcism, pal.sp.HammerWrath, spn.HolyStrike, pal.sp.HolyShield)
  end)

  pal.actions.right = Action:create(seal.Righteousness, function(self, state_type)
    -- TODO: dont cast judgement if no mana to rebuff Righteousness
    if not cs.check_target(cs.t.close_30) then return end

    if self:_judgement_other() then
      return
    end

    self.main_seal:reseal_and_judgement()
  end)

  pal.actions.crusader = Action:create(seal.Crusader, function(self, state_type)
    if not cs.check_target(cs.t.close_10) then return end

    if self:_judgement_other() then
      return
    end

    self.main_seal:reseal()
  end)

  pal.actions.wisdom = Action:create(seal.Wisdom, Action._seal_action)

  pal.actions.light = Action:create(seal.Light, Action._seal_action)

  pal.actions.justice = Action:create(seal.Justice, Action._seal_action)

  pal.actions.null = FreeAction:create(nil, function() end)

  pal.actions.splash = FreeAction:create(pal.actions.wisdom, function(self, state_type)
    cs.auto_attack_nearby()

    self:update_saved_action()
    if not cs.is_low_mana() then
      self:run_saved_action(state_type)
    end

    pal.sp.HolyShield_force:cast()
  end)

  pal.actions.stun = FreeAction:create(nil, function(self, state_type)
    self.cast_order:cast()
  end, function(self)
    self.cast_order = cs.SpellOrder.build(pal.sp.TurnUndead, pal.spn.HammerJustice)
  end)

  pal.actions.taunt = FreeAction:create(pal.actions.wisdom, function(self, state_type)
    self:update_saved_action(pal.actions.justice)

    if self.main_seal:judgement_only() then return end

    if not cs.is_low_mana() then
      self:run_saved_action(state_type)
    end
  end, function(self)
    self.main_seal = seal.Justice
  end)

  pal.actions.dict = cs.filter_dict(pal.actions, "table")
end


-- PUBLIC
function cs_free_action(name)
  local action = pal.actions[name]
  action:run(pal.stt.damage)
end

