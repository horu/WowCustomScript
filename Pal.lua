local cs = cs_common

-- +TODO: Combat bless

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

local procast_on_seal_Light = function()
  if cs.find_buff(seal_Light) and not target_has_debuff_seal_Light() then
    cast(cast_Judgement)
    return true
  end
end


-- ID
local state_RUSH = "RUSH"
local state_NORM = "NORM"
local state_DEF = "DEF"
local state_SIMP = "SIMP"

---@class state_config
local state_config = {
      name = "",
      hotbar = 1,
      hotkey = 1,
      color = "|cffff2020",
      default_aura = aura_Sanctity,
      default_bless = bless_Might,
      aura_list = { aura_Sanctity, aura_Devotion, aura_Retribution },
      bless_list = bless_list_all,

      use_slots = { slot_TwoHand },
    }


---@class states_config
local default_states_config = {
  states = {
    ---@type state_config
    RUSH = {
      name = "RUSH",
      hotbar = 1,
      hotkey = 4,
      color = "|cffff8888",

      use_slots = { slot_TwoHand },

      aura = {
        default = aura_Sanctity,
        list = { aura_Sanctity, aura_Devotion, aura_Retribution },
      },
      bless = {
        default = bless_Might,
        list = bless_list_all,
      },
    },
    NORM = {
      name = "NORM",
      hotbar = 1,
      hotkey = 3,
      color = "|cff20ff20",
      aura = {
        default = aura_Retribution,
        list = aura_list_att,
      },
      bless = {
        default = bless_Might,
        list = bless_list_all,
      },
    },
    DEF = {
      name = "DEF",
      hotbar = 1,
      hotkey = 2,
      color = "|c00bbbbFF",

      use_slots = { slot_OneHand, slot_OffHand },

      aura = {
        default = aura_Devotion,
        list = aura_list_att,
      },
      bless = {
        default = bless_Wisdom,
        list = bless_list_all,
      },
    },
    SIMP = {
      name = "SIMP",
      hotbar = 1,
      hotkey = 1,
      color = "|cffffffff",

      aura = {
        default = aura_Devotion,
        list = aura_list_att,
      },
      bless = {
        default = bless_Wisdom,
        list = bless_list_all,
      },
    },
  }
}

---@class state_holder_config
local state_holder_config = {
  cur_state = 2,
}

---@class states_dynamic_config
local default_states_dynamic_config = {
  state_holder = state_holder_config,
  states = {
    RUSH = {
      aura = {  },
      bless = {  },
    },
    NORM = {
      aura = {  },
      bless = {  },
    },
    DEF = {
      aura = {  },
      bless = {  },
    },
    SIMP = {
      aura = {  },
      bless = {  },
    },
  }
}

cs_states_config = default_states_config
cs_states_dynamic_config = default_states_dynamic_config


local get_state_holder_config = function()
  return cs_states_dynamic_config.state_holder
end

---@return state_config
local get_state_config = function(id, dynamic)
  if dynamic then
    return cs_states_dynamic_config.states[id]
  end
  return cs_states_config.states[id]
end






local status_NONE = "N"
local status_DEFAULT = "D"
local status_MODIFIED = "M"
local status_TEMP = "T"


---@class StateBuff
local StateBuff = cs.create_class()

StateBuff.build = function(state_id, buff_name)
  ---@type StateBuff
  local buff = StateBuff:new()

  buff.id = state_id
  buff.name = buff_name
  buff.is_ready = nil

  buff:get_config(1).current = buff:get_config(1).current or buff:get_config().default
  buff.set = nil

  return buff
end

function StateBuff:get_config(dynamic)
  return get_state_config(self.id, dynamic)[self.name]
end

function StateBuff:init()
  self.is_ready = nil
end

function StateBuff:reset()
  self.is_ready = nil
  self:get_config(1).current = self:get_config().default
end

function StateBuff:to_string()
  return self:get_config(1).current
end

function StateBuff:is_available(value)
  return cs.to_dict(self:get_config().list)[value]
end

function StateBuff:rebuff(value)
  self.set = value
  if not self.set or not self:is_available(self.set) then
    self.set = self:get_config(1).current
  end

  if cs.rebuff(self.set) then
    self.is_ready = nil
  end
end

function StateBuff:on_buff_changed()
  if not self.is_ready then
    -- state is not initializated yet. Ignore new buffs.
    cs.debug(self)
    self.is_ready = cs.find_buff(self.set)
    return
  end

  -- Set new custom buffs
  local _, new = cs.find_buff(self:get_config().list)
  if new and self.set ~= new then
    self:get_config(1).current = new
  end
end

function StateBuff:get_status()
  local config = self:get_config(1).current
  local default = self:get_config().default
  local set = self.set

  local is_default = config == default
  local is_modified = config == set
  local is_temp = config ~= set

  local status = status_NONE
  if self.is_ready then
    if is_default and is_modified then
      status = status_DEFAULT
    elseif is_modified then
      status = status_MODIFIED
    else
      status = status_TEMP
    end
  end
  return status
end






















---@class State
local State = cs.create_class()

State.build = function(id)
  ---@type State
  local state = State:new()

  state.id = id
  state.buff_list = {
    aura = StateBuff.build(id, "aura"),
    bless = StateBuff.build(id, "bless"),
  }

  state.slot_to_use = state:get_config().use_slots and cs.MultiSlot.build(state:get_config().use_slots)

  state.enemy_spell_base = { base = nil, ts = 0 }
  state.enemy_spell_base.is_valid = function(self)
    return self.base and cs.compare_time(10, self.ts)
  end

  return state
end

function State:get_config(dynamic)
  return get_state_config(self.id, dynamic)
end

function State:get_name()
  return self:get_config().color..self:get_config().name
end

function State:every_buff(fun, a1, a2, a3)
  for _, buff in pairs(self.buff_list) do
    fun(buff, a1, a2, a3)
  end
end

function State:init()
  self:every_buff(StateBuff.init)
  self:recheck()
  self:on_buff_changed()
end

function State:reset_buffs()
  self:every_buff(StateBuff.reset)
  self:recheck()
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
  local aura_status = self.buff_list.aura:get_status()
  local bless_status = self.buff_list.bless:get_status()

  local msg = self:get_config().color..string.sub(self:get_config().name, 1, 1).."   "..
          to_short(self.buff_list.aura:to_string()).."(".. aura_status ..")   "..
          to_short(self.buff_list.bless:to_string()).."(".. bless_status ..")"
  return msg
end

function State:standard_rebuff_attack()
  self.buff_list.aura:rebuff(self:get_aura())
  self.buff_list.bless:rebuff(self:get_bless())
  if cs.is_in_party() and not cs.in_combat() then
    cs.rebuff(buff_Righteous)
    buff_party()
  end
end

function State:get_aura()
  local aura
  -- buff spell defended auras if enemy casts one
  local spell_base = self.enemy_spell_base.base
  if self.enemy_spell_base:is_valid() then
    if spell_base == cs.spell_base_Frost then
      aura = aura_Frost
    end
    if spell_base == cs.spell_base_Shadow then
      aura = aura_Shadow
    end
  end

  return aura
end

function State:get_bless()
  local bless = bless_Wisdom -- mana regen if not in combat

  if cs.check_target(cs.t_attackable) and cs.check_target(cs.t_close) or
          cs.in_combat() or cs.compare_time(5, cs.get_combat_info().ts_leave) -- 5 sec after combat
  then
    bless = nil
  end

  return bless
end

function State:on_buff_changed()
  self:every_buff(StateBuff.on_buff_changed)
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

  holder.frame = cs.create_simple_text_frame(
          "StateHolder.build", "BOTTOM",-290, 72, "", "CENTER")

  return holder
end

function StateHolder:init()
  self:change_state(get_state_holder_config().cur_state)
  cs.Looper.add_event("StateHolder",0.2, self, self.check_loop)

  for i in pairs(self.states) do
    cs.ActionBarProxy.add_proxy(1, i, StateHolder.button_callback, self)
  end
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
        cs_states_dynamic_config = default_states_dynamic_config
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
    get_state_holder_config().cur_state = state_number
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

function StateHolder:add_state(id)
  local config = get_state_config(id)
  self.states[config.hotkey] = State.build(id)
end

function StateHolder:add_action(action_name, action)
  self.actions[action_name] = action
end

function StateHolder:do_action(name)
  local action = self.actions[name]
  action(self.cur_state)
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

local main_frame = cs.create_simple_frame("pal_main_frame")
main_frame:RegisterEvent("VARIABLES_LOADED")
main_frame:SetScript("OnEvent", function()
  if event ~= "VARIABLES_LOADED" then
    return
  end

  local states = cs_states_config.states
  for id in pairs(states) do
    state_holder:add_state(id)
  end
  state_holder:init()


  -- ATTACKS
  state_holder:add_action("rush", function(state)
    if not cs.check_target(cs.t_close_30) then return end

    cast(cast_HolyStrike)

    if state.id ~= state_RUSH then
      if procast_on_seal_Light() then
        return
      end
    end

    seal_and_cast(seal_Righteousness, build_cast_list({ cast_Judgement, cast_CrusaderStrike }))
  end)

  state_holder:add_action("mid", function(state)
    if procast_on_seal_Light() then
      return
    end

    seal_and_cast(seal_Righteousness, build_cast_list({ cast_CrusaderStrike }))
  end)

  state_holder:add_action("fast", function(state)
    if not cs.check_target(cs.t_close) then return end

    if procast_on_seal_Light() then
      return
    end

    if state.id == state_RUSH then
      if cs.find_buff(seal_Righteousness) then
        cast(cast_Judgement)
        return
      end
    end

    seal_and_cast(seal_Crusader, cast_CrusaderStrike, {seal_Crusader, seal_Righteousness})
  end)

  state_holder:add_action("def", function(state)
    if not cs.check_target(cs.t_close) then return end

    if cs.find_buff(seal_Righteousness) then
      cast(cast_Judgement)
      return
    end

    if not target_has_debuff_seal_Light() then
      seal_and_cast(seal_Light, cast_Judgement)
      return
    end

    seal_and_cast(seal_Light, cast_CrusaderStrike)
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




























