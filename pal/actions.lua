
local cs = cs_common
local pal = cs.pal
local spn = pal.spn
local seal = pal.seal



-- ATTACKS

---@class Action
local Action = cs.create_class()

---@type pal.Seal[]
Action.debuffed_seal_list = {}

---@param main_seal pal.Seal
Action.build = function(main_seal, run_func)
  local action = Action:new()

  action.main_seal = main_seal
  ---@type function(self, state)
  action.run = run_func

  --cs.debug(action)
  return action
end

function Action:judgement_other()
  for _, it_seal in pairs(seal.list_all) do
    if it_seal ~= self.main_seal then
      if it_seal:judgement_it(true) then
        return true
      end
    end
  end
end

function Action:has_any_seal_debuff()
  for _, it_seal in pairs(Action.debuffed_seal_list) do
    if it_seal:check_target_debuff() then
      return true
    end
  end
end

local cast_holy_sheild = function(state)
  if state.id == pal.stn.DEF or state.id == pal.stn.BACK then
    local last_phy_ts = cs.damage.analyzer:get_sourcetype(cs.damage.st.Physical):get_last_ts()
    if cs.compare_time(5, last_phy_ts) then
      return cs.cast(pal.sp.HolyShield)
    end
  end
end

---@param seal_list pal.Seal[]
function Action:seal_action(state, seal_list)
  if not cs.check_target(cs.t.close_10) then
    -- the target is far away
    return
  end

  if seal.Righteousness:judgement_it() then
    -- wait another seal to judgement on the target
    return
  end

  if self.main_seal:reseal() then
      return
  end

  cs.cast(spn.HolyStrike)
  if cast_holy_sheild(state) then return end

  if not self:has_any_seal_debuff() then
    if self:judgement_other() then
      -- wait another seal to judgement on the target
      return
    end

    self.main_seal:judgement_it()
  end
end

---@param seal_list pal.Seal[]
function Action:seal_action_old(state, seal_list)
  if not cs.check_target(cs.t.close_10) then
    -- the target is far away
    return
  end

  cs.cast(spn.HolyStrike)
  if cast_holy_sheild(state) then return end

  if seal.Righteousness:judgement_it() then
    -- wait another seal to judgement on the target
    return
  end

  if not self.main_seal:is_reseal_available() then
    -- seal can not be casted with current situation, just cast other spells
    --cs.cast(pal.sp.CrusaderStrike)
    return
  end

  if self:has_any_seal_debuff() then
    -- the target has no other seal debuff. Lets reseal and judgement it.

    if state.id == pal.stn.RUSH then
      cs.cast(pal.sp.CrusaderStrike)
      return
    end

    -- self.main_seal:reseal_and_cast(pal.sp.CrusaderStrike)
    self.main_seal:reseal()
    return
  end

  if self:judgement_other() then
    -- wait another seal to judgement on the target
    return
  end

  self.main_seal:reseal_and_judgement()
end


pal.actions = {}
pal.actions.init = function()
  Action.debuffed_seal_list = { seal.Light, seal.Wisdom, seal.Justice }

  pal.actions.right = Action.build(seal.Righteousness, function(self, state)
    -- TODO: dont cast judgement if no mana to rebuff Righteousness
    if not cs.check_target(cs.t.close_30) then return end

    cs.cast(spn.HolyStrike)
    if cs.cast(pal.sp.Exorcism, pal.sp.HammerWrath) then
      return
    end
    cast_holy_sheild(state)

    if state.id ~= pal.stn.RUSH then
      if self:judgement_other() then
        return
      end
    end

    self.main_seal:reseal_and_judgement()
    cs.cast(pal.sp.CrusaderStrike)
  end)

  pal.actions.crusader = Action.build(seal.Crusader, function(self, state)
    if not cs.check_target(cs.t.close_10) then return end

    cs.cast(spn.HolyStrike)

    if self:judgement_other() then
      return
    end

    self.main_seal:reseal_and_cast(pal.sp.CrusaderStrike)
  end)

  pal.actions.wisdom = Action.build(seal.Wisdom, function(self, state)
    self:seal_action(state, {seal.Wisdom, seal.Light, seal.Justice})
  end)

  pal.actions.light = Action.build(seal.Light, function(self, state)
    self:seal_action(state, {seal.Light, seal.Wisdom, seal.Justice})
  end)

  pal.actions.justice = Action.build(seal.Justice, function(self, state)
    self:seal_action(state, {seal.Justice, seal.Light, seal.Wisdom})
  end)

  pal.actions.null = Action.build(seal.Crusader, function(self, state)
    -- cs.cast(spn.HolyStrike)
  end)
  pal.actions.splash = Action.build(seal.Crusader, function(self, state)
    cs.auto_attack_nearby()
    cs.cast(pal.sp.HolyShield)
  end)
  pal.actions.dict = cs.filter_dict(pal.actions, "table")
end




