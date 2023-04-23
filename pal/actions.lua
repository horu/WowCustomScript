
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
      if it_seal:judgement_it() then
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

  if not self.main_seal:is_reseal_available() then
    -- seal can not be casted with current situation, just cast other spells
    cs.cast(spn.HolyStrike, spn.CrusaderStrike)
    return
  end

  if self:has_any_seal_debuff() then
    -- the target has no other seal debuff. Lets reseal and judgement it.

    if state.id == pal.stn.RUSH then
      cs.cast(spn.CrusaderStrike)
      return
    end

    self.main_seal:reseal_and_cast(spn.HolyStrike, spn.CrusaderStrike)
    return
  end

  if self:judgement_other() then
    -- wait another seal to judgement on the target
    return
  end

  self.main_seal:reseal_and_judgement()
end

local build_cast_list = function(...)
  local cast_list = arg

  local target = UnitCreatureType("target")
  if target == "Demon" or target == "Undead" then
    table.insert(cast_list, 1, spn.Exorcism)
  end
  return unpack(cast_list)
end


pal.actions = {}
pal.actions.init = function()
  Action.debuffed_seal_list = { seal.Light, seal.Wisdom, seal.Justice }

  pal.actions.right = Action.build(seal.Righteousness, function(self, state)
    if not cs.check_target(cs.t.close_30) then return end

    cs.cast(spn.HolyStrike)

    if state.id ~= pal.stn.RUSH then
      if self:judgement_other() then
        return
      end
    end

    self.main_seal:reseal_and_judgement()
    cs.cast(build_cast_list(spn.CrusaderStrike))
  end)

  pal.actions.crusader = Action.build(seal.Crusader, function(self, state)
    if not cs.check_target(cs.t.close_10) then return end

    if self:judgement_other() then
      return
    end

    self.main_seal:reseal_and_cast(spn.HolyStrike, spn.CrusaderStrike)
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
    cs.cast(spn.HolyStrike)
  end)
  -- TODO: add null attack on midle mouse
end




