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
to_short_list[aura_Concentration] = "CA"
to_short_list[aura_Devotion] = "DA"
to_short_list[aura_Sanctity] = "SA"
to_short_list[aura_Retribution] = "RA"
to_short_list[aura_Shadow] = "SRA"
to_short_list[aura_Frost] = "FRA"

to_short_list[bless_Wisdom] = "BW"
to_short_list[bless_Might] = "BM"
to_short_list[bless_Salvation] = "BV"

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


local default_state_config = {
  state_holder = {
    cur_state = 2,
  },
  states = {
    RUSH = {
      name = "RUSH",
      hotbar = 1,
      hotkey = 4,
      color = "|cffff2020",
      default_aura = aura_Sanctity,
      default_bless = bless_Might,
      aura_list = { aura_Sanctity, aura_Devotion, aura_Retribution },
      bless_list = bless_list_all,

      use_slots = { slot_TwoHand },

      aura = aura_Sanctity,
      bless = bless_Might,
    },
    NORM = {
      name = "NORM",
      hotbar = 1,
      hotkey = 3,
      color = "|cff20ff20",
      default_aura = aura_Retribution,
      default_bless = bless_Might,
      aura_list = aura_list_att,
      bless_list = bless_list_all,

      aura = aura_Retribution,
      bless = bless_Might,
    },
    DEFF = {
      name = "DEFF",
      hotbar = 1,
      hotkey = 2,
      color = "|c008692FF",
      default_aura = aura_Devotion,
      default_bless = bless_Wisdom,
      aura_list = aura_list_att,
      bless_list = bless_list_all,

      use_slots = { slot_OneHand, slot_OffHand },

      aura = aura_Devotion,
      bless = bless_Wisdom,
    },
    SIMP = {
      name = "SIMP",
      hotbar = 1,
      hotkey = 1,
      color = "|cffffffff",
      default_aura = aura_Devotion,
      default_bless = bless_Wisdom,
      aura_list = aura_list_att,
      bless_list = bless_list_all,

      aura = aura_Devotion,
      bless = bless_Wisdom,
    },
  }
}

---@class StateConfig
local StateConfig = {
  name = "RUSH",
  hotbar = 1,
  hotkey = 4,
  color = "|cffff2020",
  default_aura = aura_Sanctity,
  default_bless = bless_Might,
  use_slots = { slot_TwoHand },
  aura_list = { aura_Sanctity, aura_Devotion, aura_Retribution },

  aura = aura_Sanctity,
  bless = bless_Might,
}

---@class State
local State = cs.create_class()

State.build = function(config)
  ---@type State
  local state = State:new()

  ---@type StateConfig
  state.config = config

  state.slot_to_use = state.config.use_slots and cs.MultiSlot.build(state.config.use_slots)

  state.is_init = nil

  state.enemy_spell_base = { base = nil, ts = 0 }
  state.enemy_spell_base.is_valid = function(self)
    return self.base and GetTime() - self.ts <= 10
  end

  return state
end

function State:get_name()
  return self.config.color..self.config.name
end

function State:init()
  self.is_init = nil
  self:on_buff_changed()
end

function State:reset_buffs()
  self.is_init = nil
  self.config.aura = self.config.default_aura
  self.config.bless = self.config.default_bless
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
  local aura_is_default = self.config.aura == self.config.default_aura
  local bless_is_default = self.config.bless == self.config.default_bless
  local state = not self.is_init and "N" or ( (aura_is_default and bless_is_default) and "D" or "M")
  local bless = self.config.bless and to_short(self.config.bless) or "N"

  local msg = self.config.color..string.sub(self.config.name, 1, 1).."   "..
          to_short(self.config.aura).."   "..
          bless .. "   "..
          state
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
  local aura = self.config.aura

  local spell_base = self.enemy_spell_base.base
  if self.enemy_spell_base:is_valid() then
    if spell_base == cs.spell_base_Frost then
      aura = aura_Frost
    end
    if spell_base == cs.spell_base_Shadow then
      aura = aura_Shadow
    end

    if not self:is_available_aura(aura) then
      aura = self.config.aura
    end
  end

  if cs.rebuff(aura) then
    self.is_init = nil
  end
end

function State:is_available_aura(aura)
  return cs.to_dict(self.config.aura_list)[aura]
end

function State:rebuff_bless()
  if cs.rebuff(self.config.bless) then
    self.is_init = nil
  end
end

function State:on_buff_changed()
  if not self.is_init then
    -- state is not initializated yet. Ignore new buffs.
    self.is_init = cs.find_buff(self.config.aura) and cs.find_buff(self.config.bless)
    return
  end

  local _, aura = cs.find_buff(self.config.aura_list)
  if aura then
    self.config.aura = aura
  end

  local _, bless = cs.find_buff(self.config.bless_list)
  if bless then
    self.config.bless = bless
  end
end

-- reacion for enenmy cast to change resist aura
function State:on_cast_detected(spell_base)
  if not spell_base or self.enemy_spell_base:is_valid() then
    return
  end

  self.enemy_spell_base.base = spell_base
  self.enemy_spell_base.ts = GetTime()
end



---@class StateHolder
local StateHolder = cs.create_class()

StateHolder.build = function(config)
  ---@type StateHolder
  local holder = StateHolder:new()

  holder.config = config

  ---@type State
  holder.cur_state = nil
  ---@type State[]
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
  holder.states_clicks = {}
  holder.states_buttons = {}

  holder.frame = cs.create_simple_text_frame(
          "StateHolder.build", "BOTTOM",-290, 72, "", "CENTER")

  return holder
end

function StateHolder:init()
  cs.Looper.add_event("once", 0, nil, function()

    self:change_state(self.config.cur_state)
    cs.Looper.add_event("StateHolder",0.2, self, self.check_loop)

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
    if keyinfo.keystate == cs.ActionBarProxy.key_state_down then
      local state = self.states[but]
      if ts - keyinfo.ts >= 5 then
        cs_state_config = default_state_config
        print("RESET CONFIG!")
      elseif ts - keyinfo.ts >= 3 then
        state:reset_buffs()
        print("RESET STATE: "..self.cur_state:get_name())
      elseif ts - keyinfo.ts >= 0.55 then
        self:change_state(but)
      end
    elseif keyinfo.keystate == cs.ActionBarProxy.key_state_up then
      self.states_buttons[but] = nil
    end
  end

  self.frame.cs_text:SetText(self.cur_state:to_string())

  if cs.check_target(cs.t_attackable) then
    local data = cs.get_cast_info("target")
    if data and data.spell_base then
      self.cur_state:on_cast_detected(data.spell_base)
    end
  end
end

function StateHolder:change_state(state_number)
  local state = self.states[state_number]

  if state ~= self.cur_state then
    self.cur_state = state
    self.cur_state:init()
    self.config.cur_state = state_number
    print("NEW STATE: "..self.cur_state:get_name())
  end
end

function StateHolder:attack_action(action_name)
  cs.error_disabler:off()

  cs.auto_attack()

  self.cur_state:recheck()
  self:do_action(action_name)

  cs.error_disabler:on()

end

function StateHolder:add_state(state_config)
  self.states[state_config.hotkey] = State.build(state_config)
end

function StateHolder:add_action(action_name, action)
  self.actions[action_name] = action
end

function StateHolder:do_action(name)
  local action = self.actions[name]
  action()
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
    if self:check_hp() then
      cs.rebuff(aura_Concentration)
    end
  end
end

local state_holder

cs_state_config = default_state_config

local main_frame = cs.create_simple_frame("pal_main_frame")
main_frame:RegisterEvent("VARIABLES_LOADED")
main_frame:SetScript("OnEvent", function()
  if event ~= "VARIABLES_LOADED" then
    return
  end

  for state_name, state in pairs(cs_state_config.states) do
    for name, value in pairs(state) do
      if name ~= "aura" and name ~= "bless" then
        state[name] = default_state_config.states[state_name][name]
      end
    end
  end



  state_holder = StateHolder.build(cs_state_config.state_holder)

  local states = cs_state_config.states
  for _, state_config in pairs(states) do
    state_holder:add_state(state_config)
  end
  state_holder:init()




  -- ATTACKS
  state_holder:add_action("rush", function(state)
    cast(cast_HolyStrike)

    seal_and_cast(seal_Righteousness, build_cast_list({ cast_Judgement, cast_CrusaderStrike }))
  end)

  state_holder:add_action("mid", function(state)
    if cs.find_buff(seal_Light) and not target_has_debuff_seal_Light() then
      cast(cast_Judgement)
      return
    end

    seal_and_cast(seal_Righteousness, build_cast_list({ cast_CrusaderStrike }))
  end)

  state_holder:add_action("fast", function(state)
    if cs.check_target(cs.t_close) then
      if cs.find_buff(seal_Light) and not target_has_debuff_seal_Light() then
        cast(cast_Judgement)
        return
      end

      seal_and_cast(seal_Crusader, cast_CrusaderStrike, {seal_Crusader, seal_Righteousness})
    end
  end)

  state_holder:add_action("def", function(state)
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

  state_holder:add_action( "null", function(state)
  end)

end)

function attack_action(name)
  state_holder:attack_action(name)
end

function cast_heal(heal_cast)
  state_holder:rebuff_heal()
  cast(heal_cast)
end




























