

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

State.build = function(name, aura, bless, slot_to_use, aura_list)
  ---@type State
  local state = State:new()

  state.name = name
  state.aura_list = aura_list or aura_list_all
  state.bless_list = bless_list_all
  state.slot_to_use = slot_to_use

  state.default_aura = aura
  state.default_bless = bless

  state.aura = state.default_aura
  state.bless = state.default_bless

  state.is_init = nil

  state.msg = "NONE"

  state.enemy_spell_base = { base = nil, ts = 0 }
  state.enemy_spell_base.is_valid = function(self)
    return self.base and GetTime() - self.ts <= 10
  end

  return state
end

function State:init()
  self.is_init = nil
  self:on_buff_changed()
end

function State:reset_buffs()
  self.is_init = nil
  self.aura = self.default_aura
  self.bless = self.default_bless
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

  local state = not self.is_init and "NONE" or (
          (self.aura ~= self.default_aura or self.bless ~= self.default_bless) and "MODI" or "INIT")
  local bless = self.bless and to_short(self.bless) or "NONE"
  local msg = self.name.."   "..to_short(self.aura).."   ".. bless .. "   "..state
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
  local aura = self.aura

  local spell_base = self.enemy_spell_base.base
  if self.enemy_spell_base:is_valid() then
    if spell_base == cs.spell_base_Frost then
      aura = aura_Frost
    end
    if spell_base == cs.spell_base_Shadow then
      aura = aura_Shadow
    end

    if not self:is_available_aura(aura) then
      aura = self.aura
    end
  end

  if cs.rebuff(aura) then
    self.is_init = nil
  end
end

function State:is_available_aura(aura)
  return cs.to_dict(self.aura_list)[aura]
end

function State:rebuff_bless()
  if cs.rebuff(self.bless) then
    self.is_init = nil
  end
end

function State:on_buff_changed()
  if not self.is_init then
    -- state is not initializated yet. Ignore new buffs.
    self.is_init = cs.find_buff(self.aura) and cs.find_buff(self.bless)
    return
  end

  local _, aura = cs.find_buff(self.aura_list)
  if aura and self.aura ~= aura then
    self.aura = aura
  end

  local _, bless = cs.find_buff(self.bless_list)
  if bless and self.bless ~= bless then
    self.bless = bless
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

StateHolder.build = function()
  ---@type StateHolder
  local holder = StateHolder:new()

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

  holder.frame = cs.create_simple_text_frame("StateHolder.build", "BOTTOM",-177, 123, "", "CENTER")

  return holder
end

function StateHolder:init()
  cs.Looper.add_event("once", 0, nil, function()

    local _, state = next(self.states)
    self:change_state(state)
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
      if ts - keyinfo.ts >= 3 then
        state:reset_buffs()
        print("RESET STATE: "..self.cur_state.name)
      elseif ts - keyinfo.ts >= 0.55 then
        self:change_state(state)
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

function StateHolder:add_state(button, state)
  self.states[button] = state
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

local state_holder = StateHolder.build()

-- ATTACKS
state_holder:add_state(4, State.build(
        "|cffff2020RUSH",
        aura_Sanctity,
        bless_Might,
        slot_two_hands,
        { aura_Sanctity, aura_Devotion, aura_Retribution }
))

state_holder:add_state(3, State.build(
        "|cff20ff20NORM",
        aura_Retribution,
        bless_Might
))

state_holder:add_state(2, State.build(
        "|cff9090ffDEFR",
        aura_Devotion,
        bless_Wisdom,
        slot_one_off_hands
))

state_holder:add_state(1, State.build(
        "|cffffffffNULL",
        aura_Shadow,
        bless_Wisdom
))

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

state_holder:init()

function attack_action(name)
  state_holder:attack_action(name)
end

function cast_heal(heal_cast)
  state_holder:rebuff_heal()
  cast(heal_cast)
end




























