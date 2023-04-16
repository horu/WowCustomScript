

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

local slot_TwoHand = 13
local slot_OneHand = 14
local slot_OffHand = 15

local slot_two_hands = cs.Slot.build(slot_TwoHand)
local slot_one_off_hands = cs.MultiSlot.build({cs.Slot.build(slot_OneHand), cs.Slot.build(slot_OffHand)})



local to_short_list = {}
to_short_list[aura_Concentration] = "CONC"
to_short_list[aura_Devotion] = "DEVO"
to_short_list[aura_Sanctity] = "SANC"
to_short_list[aura_Retribution] = "RETR"
to_short_list[aura_Shadow] = "SHAD"
to_short_list[aura_Frost] = "FROS"

to_short_list[bless_Wisdom] = "WISD"
to_short_list[bless_Might] = "MIGH"
to_short_list[bless_Salvation] = "SALV"

local to_short = function(cast)
  return to_short_list[cast]
end


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
  local size = GetNumPartyMembers()
  for i=1, size do
    local unit = "party"..i
    rebuff_party_member(unit)
    local pet = "partypet"..i
    rebuff_party_member(pet)
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

local function has_debuff_protection()
  return cs.has_debuffs("player", "Spell_Holy_RemoveCurse")
end


-- CAST

local cast_DivineProtection = "Divine Protection"
local cast_BlessingProtection = "Blessing of Protection"


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




---@class State
local State = cs.create_class()

State.build = function(name, aura_list, bless_list, slot_to_use, default_aura, default_bless)
  ---@type State
  local state = State:new()

  state.name = name
  state.aura_list = aura_list
  state.bless_list = bless_list
  state.slot_to_use = slot_to_use

  state.aura = default_aura or aura_list[1]
  state.bless = default_bless or bless_list[1]

  state.is_init = nil
  state.combat_bless = nil

  state.msg = "NONE"

  return state
end

function State:init()
  self.is_init = nil
  self:on_buff_changed()
end

function State:reuse_slot()
  if self.slot_to_use then
    self.slot_to_use:try_use()
  end
end

function State:recheck()
  self:reuse_slot()
  self:standard_rebuff_attack()
end

function State:to_string()
  local bless = self.bless and to_short(self.bless) or "NONE"
  local combat_bless = self.combat_bless and to_short(self.combat_bless) or "NONE"
  local msg = self.name.."   "..to_short(self.aura).."   ".. bless .. "/".. combat_bless .."   "..self.msg
  return msg
end

function State:standard_rebuff_attack()
  self:rebuff_aura()
  self:rebuff_bless()
  if cs.is_in_party() and not cs.in_combat() then
    cs.rebuff(buff_Righteous)
    buff_party()
  end
end

function State:rebuff_aura()
  if cs.rebuff(self.aura) then
    self.is_init = nil
  end
end

function State:rebuff_bless()
  if not cs.check_target(cs.t_attackable) then
    -- buff BoW for mana regen
    if not self.combat_bless then
      self.combat_bless = self.bless
      self.bless = bless_Wisdom
    end
  elseif self.combat_bless then
    self.bless = self.combat_bless
    self.combat_bless = nil
  end

  if cs.rebuff(self.bless) then
    self.is_init = nil
  end
end

function State:on_buff_changed()
  if not self.is_init then
    -- state is not initializated yet. Ignore new buffs.
    self.is_init = cs.find_buff(self.aura) and cs.find_buff(self.bless)
    if self.is_init then
      self.msg = "INIT"
    end
    return
  end

  local _, aura = cs.find_buff(self.aura_list)
  if aura and self.aura ~= aura then
    self.aura = aura
    self.msg = "CHAN"
  end

  local _, bless = cs.find_buff(self.bless_list)
  if bless and self.bless ~= bless then
    self.bless = bless
    self.msg = "CHAN"
  end
end


---@class StateHolder
local StateHolder = cs.create_class()

StateHolder.build = function()
  ---@type StateHolder
  local holder = StateHolder:new()

  ---@type State
  holder.cur_state = nil
  holder.states = {}

  holder.actions = {}

  local f = cs.create_simple_frame("StateHolder.build")
  f:RegisterEvent("UNIT_AURA")
  f:SetScript("OnEvent", function()
    if this.cs_holder.cur_state then
      this.cs_holder.cur_state:on_buff_changed()
    end
  end)

  f.cs_holder = holder
  holder.looper = nil
  holder.states_clicks = {}
  holder.states_buttons = {}

  holder.frame = cs.create_simple_text_frame("StateHolder.build", "BOTTOMLEFT",10, 95, "S")

  return holder
end

function StateHolder:init()
  cs.Looper.delay_q(function()

    local _, state = next(self.states)
    self:change_state(state)
    self.looper = cs.Looper.build(self.check_loop, self, 0.2)

    for i in pairs(self.states) do
      cs.ActionBarProxy.add_proxy(1, i, StateHolder.button_callback, self)
    end
  end)
end

function StateHolder:button_callback(bar, button)
  --cs.debug({bar, button, keystate})
  self.states_buttons[button] = {keystate = keystate, ts = GetTime()}
end

function StateHolder:check_loop()
  local ts = GetTime()

  for but, keyinfo in pairs(self.states_buttons) do
    if keyinfo.keystate == cs.ActionBarProxy.key_state_down and ts - keyinfo.ts >= 0.55 then
      local state = self.states[but]
      self:change_state(state)
      break
    elseif keyinfo.keystate == cs.ActionBarProxy.key_state_up then
      self.states_buttons[but] = nil
    end
  end

  for state, clicks in pairs(self.states_clicks) do
    if clicks >= 3 then
      self:change_state(state)
      break
    end
  end
  self.states_clicks = {}
  self.frame.cs_text:SetText(self.cur_state:to_string())
end

function StateHolder:change_state(state)
  if state ~= self.cur_state then
    self.cur_state = state
    self.cur_state:init()
    print("NEW STATE: "..self.cur_state.name)
  end
end

function StateHolder:attack_action(action_name)
  cs.error_disabler:off()

  cs.auto_attack()

  self.cur_state:recheck()
  self:do_action(action_name)

  cs.error_disabler:on()

end

function StateHolder:add_state(button, state_name, a1, a2, a3, a4, a5, a6, a7)
  local state = State.build(state_name, a1, a2, a3, a4, a5, a6, a7)
  self.states[button] = state
end

function StateHolder:add_action(state_name, action_name, action)
  self.actions[action_name] = {state_name, action}
end

function StateHolder:do_action(name)
  local state_name, action = unpack(self.actions[name])
  action()
  --local state = self.states[state_name]
  --self.states_clicks[state] = self.states_clicks[state] and self.states_clicks[state] + 1 or 0
end

function StateHolder:check_hp()
  local hp_level = cs.get_hp_level()
  if not has_debuff_protection() and hp_level <= 0.3 then
    DoOrder(cast_DivineProtection, cast_BlessingProtection)
    return nil
  end
  return true
end

function StateHolder:rebuff_heal()
  if cs.in_aggro() or cs.in_combat() then
    self:check_hp()
    cs.rebuff(aura_Concentration)
  end
end

local state_holder = StateHolder.build()

-- ATTACKS
state_holder:add_state(4, "RUSH", { aura_Sanctity }, { bless_Might }, slot_two_hands, nil, nil)
state_holder:add_state(3, "NORM", aura_list_def, bless_list_all, nil, aura_Retribution, bless_Might)
state_holder:add_state(2, "DEFE", aura_list_def, bless_list_all, slot_one_off_hands)
state_holder:add_state(1, "NULL", aura_list_att, bless_list_all, nil, aura_Shadow)

state_holder:add_action("RUSH", "rush", function(state)
  cast(cast_HolyStrike)

  seal_and_cast(seal_Righteousness, build_cast_list({ cast_Judgement, cast_CrusaderStrike }))
end)

state_holder:add_action("NORM", "mid", function(state)
  if cs.find_buff(seal_Light) and not target_has_debuff_seal_Light() then
    cast(cast_Judgement)
    return
  end

  seal_and_cast(seal_Righteousness, build_cast_list({ cast_CrusaderStrike }))
end)

state_holder:add_action("NORM", "fast", function(state)
  if cs.check_target(cs.t_close) then
    if cs.find_buff(seal_Light) and not target_has_debuff_seal_Light() then
      cast(cast_Judgement)
      return
    end

    seal_and_cast(seal_Crusader, cast_CrusaderStrike, {seal_Crusader, seal_Righteousness})
  end
end)

state_holder:add_action("DEFE", "def", function(state)
  if cs.check_target(cs.t_close) then
    if cs.find_buff(seal_Righteousness) then
      cast(cast_Judgement)
      return
    end

    if not target_has_debuff_seal_Light() then
      seal_and_cast(seal_Light, cast_Judgement)
      return
    end

    buff_seal(seal_Light)
  end
end)

state_holder:add_action("NULL", "null", function(state)
end)

state_holder:init()

function attack_action(name)
  state_holder:attack_action(name)
end

function cast_heal(heal_cast)
  state_holder:rebuff_heal()
  cast(heal_cast)
end




























