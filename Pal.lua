local cs = cs_common

-- +TODO: Combat bless

local state_holder_frame = {"StateHolder.build", "BOTTOM",-330, 69, "", "LEFT", true}


-- buffs
local buff_Righteous = "Righteous Fury"

local aura_Concentration = "Concentration Aura"
local aura_Devotion = "Devotion Aura"
local aura_Sanctity = "Sanctity Aura"
local aura_Retribution = "Retribution Aura"
local aura_Shadow = "Shadow Resistance Aura"
local aura_Frost = "Frost Resistance Aura"
local aura_Fire = "Fire Resistance Aura"
local aura_list_all = { aura_Concentration, aura_Sanctity, aura_Devotion, aura_Retribution, aura_Shadow, aura_Frost, aura_Fire }
local aura_list_att =                     { aura_Sanctity, aura_Devotion, aura_Retribution, aura_Shadow, aura_Frost, aura_Fire }
local aura_list_def =                                    { aura_Devotion, aura_Retribution, aura_Shadow, aura_Frost, aura_Fire }

local bless_Wisdom = "Blessing of Wisdom"
local bless_Might = "Blessing of Might"
local bless_Salvation = "Blessing of Salvation"
local bless_list_all = { bless_Wisdom, bless_Might, bless_Salvation }

local seal_Righteousness = "Seal of Righteousness"
local seal_Crusader = "Seal of the Crusader"
local seal_Justice = "Seal of Justice"
local seal_Light = "Seal of Light"
local seal_list_all = { seal_Righteousness, seal_Crusader, seal_Justice, seal_Light }

local slot_TwoHand = 13
local slot_OneHand = 14
local slot_OffHand = 15


local to_short_list = {}
to_short_list[aura_Concentration] = "CA"
to_short_list[aura_Devotion] = "DA"
to_short_list[aura_Sanctity] = "SA"
to_short_list[aura_Retribution] = "RA"
to_short_list[aura_Shadow] = "SH"
to_short_list[aura_Frost] = "FR"
to_short_list[aura_Fire] = "FI"

to_short_list[bless_Wisdom] = "BW"
to_short_list[bless_Might] = "BM"
to_short_list[bless_Salvation] = "BV"

to_short_list[seal_Righteousness] = cs.color_green.."SR".."|r"
to_short_list[seal_Crusader] = cs.color_orange_1.."SC".."|r"
to_short_list[seal_Light] = cs.color_yellow.."SL".."|r"
to_short_list[seal_Justice] = cs.color_blue.."SJ".."|r"

local to_short = function(cast)
  return to_short_list[cast]
end





-- party

local function rebuff_unit(unit)
  local buffs = {
    WARRIOR = bless_Might,
    PALADIN = bless_Might,
    HUNTER = bless_Might,
    ROGUE = bless_Might,
    SHAMAN = bless_Might,

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
  cs.rebuff_unit(buff, bless_list_all, unit)
end

local function buff_party()
  local size = GetNumPartyMembers()
  for i=1, size do
    local unit = "party"..i
    rebuff_unit(unit)
    local pet = "partypet"..i
    rebuff_unit(pet)
  end
end





-- SEAL

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

  return cs.cast(cast_list)
end

local function target_has_debuff_seal_Light()
  -- TODO: add remaining check time and recast below 4 sec
  return cs.has_debuffs("target", "Spell_Holy_HealingAura")
end

local function has_debuff_protection()
  return cs.has_debuffs("player", "Spell_Holy_RemoveCurse")
end





-- CAST

local cast_DivineShield = "Divine Shield"
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
    cs.cast(cast_Judgement)
    return true
  end
end

local procast_on_seal_Righteousness = function()
  if cs.find_buff(seal_Righteousness) then
    cs.cast(cast_Judgement)
    return true
  end
end





-- ID
local state_RUSH = "RUSH"
local state_NORM = "NORM"
local state_DEF = "DEF"
local state_BASE = "BASE"

---@class state_config
local state_config = {
      name = "",
      hotbar = 1,
      hotkey = 1,
      color = cs.color_intense_red,
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
      color = cs.color_intense_red,

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
      color = cs.color_green,
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
      color = cs.color_blue,

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
    BASE = {
      name = "BASE",
      hotbar = 1,
      hotkey = 1,
      color = cs.color_white,

      aura = {
        default = aura_Retribution,
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
    BASE = {
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

  buff:_get_config(1).current = buff:_get_config(1).current or buff:_get_config().default
  buff.set = nil

  return buff
end


-- const
-- get current buffed buf ( not config )
function StateBuff:get_buffed()
  return cs.find_buff(self:_get_config().list)
end

-- const
function StateBuff:to_string()
  local buffed = self:get_buffed()
  local current = self:_get_config(1).current

  local str = to_short(current)
  if not buffed then
    str = str .. cs.color_red.."XX".."|r"
  elseif buffed ~= current then
    str = str .. cs.color_green .. to_short(buffed).."|r"
  else
    str = str .. "  "
  end

  return str
end

-- const
function StateBuff:get_status()
  local buffed = self:get_buffed()
  local config = self:_get_config(1).current
  local default = self:_get_config().default
  local set = self.set

  if buffed == default then
    return status_DEFAULT
  end
  if buffed == config then
    return status_MODIFIED
  end
  if buffed == set then
    return status_TEMP
  end
  return status_NONE
end


-- set temporary buff and dont save it to config
function StateBuff:tmp_rebuff(value)
  self.set = value
  if not self.set or not self:_is_available(self.set) then
    self.set = self:_get_config(1).current
  end

  cs.rebuff(self.set)

  return self.set == value
end

-- set buff and save it to config
function StateBuff:reset(value)
  self:tmp_rebuff(value or self:_get_config().default)
  self:_get_config(1).current = self.set
end

function StateBuff:save_buffed_to_config()
  local current = self:get_buffed()
  self:reset(current)
end


-- const
function StateBuff:_get_config(dynamic)
  return get_state_config(self.id, dynamic)[self.name]
end

-- const
function StateBuff:_is_available(value)
  return cs.to_dict(self:_get_config().list)[value]
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

  state.slot_to_use = state:_get_config().use_slots and cs.MultiSlot.build(state:_get_config().use_slots)

  state.enemy_spell_base = { base = nil, ts = 0 }
  state.enemy_spell_base.is_valid = function(self)
    return self.base and cs.compare_time(10, self.ts)
  end

  return state
end

-- const
function State:get_name()
  return self:_get_config().color..self:_get_config().name
end

--const
function State:to_string()
  local msg = self:_get_config().color..string.sub(self:_get_config().name, 1, 1).."|r "..
          self.buff_list.aura:to_string().." "..
          self.buff_list.bless:to_string().." "..
          self:_get_seal_string()
  return msg
end


function State:init()
  self:recheck()
end

-- save current custom buffs
function State:save_buffs()
  self:_every_buff(StateBuff.save_buffed_to_config)
end

function State:reset_buffs()
  self:_every_buff(StateBuff.reset)
end

function State:recheck()
  self:_reuse_slot()
  self:_standard_rebuff_attack()
end

-- reacion for enenmy cast to change resist aura
function State:on_cast_detected(spell_base)
  if not spell_base or self.enemy_spell_base:is_valid() then
    return
  end

  self.enemy_spell_base.base = spell_base
  self.enemy_spell_base.ts = GetTime()
end


-- const
function State:_get_config(dynamic)
  return get_state_config(self.id, dynamic)
end

-- const
function State:_get_aura()
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
    if spell_base == cs.spell_base_Fire then
      aura = aura_Fire
    end
  end

  return aura
end

-- const
function State:_get_bless()
  local bless = nil

  if not cs.check_target(cs.t_attackable) and not cs.check_combat(3, cs.c_affect) then -- 3 sec after combat
    bless = bless_Wisdom -- mana regen if not in combat
  end

  return bless
end

function State:_get_seal_string()
  local seal = cs.find_buff(seal_list_all)
  if seal then
    return to_short(seal)
  end
  return cs.color_red.."XX|r"
end


function State:_standard_rebuff_attack()
  self.buff_list.aura:tmp_rebuff(self:_get_aura())
  self.buff_list.bless:tmp_rebuff(self:_get_bless())
  if not cs.check_combat(cs.c_affect) then
    if cs.is_in_party() then
      cs.rebuff(buff_Righteous)
      buff_party()
    end
    if cs.check_target(cs.t_fr_player) then
      rebuff_unit("target")
    end
  end
end

function State:_reuse_slot()
  if self.slot_to_use then
    self.slot_to_use:try_use()
  end
end

function State:_every_buff(fun, a1, a2, a3)
  for _, buff in pairs(self.buff_list) do
    fun(buff, a1, a2, a3)
  end
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

  --local f = cs.create_simple_frame("StateHolder.build")
  --f:RegisterEvent("UNIT_AURA")
  --f:SetScript("OnEvent", function()
  --  if this.cs_holder.cur_state then
  --    this.cs_holder.cur_state:on_buff_changed()
  --  end
  --end)
  --
  --f.cs_holder = holder
  holder.states_clicks = {}
  holder.states_buttons = {}

  holder.frame = cs.create_simple_text_frame(unpack(state_holder_frame))

  return holder
end


-- before init
function StateHolder:add_state(id)
  local config = get_state_config(id)
  self.states[config.hotkey] = State.build(id)
end

function StateHolder:init()
  self:_change_state(get_state_holder_config().cur_state)
  cs.add_loop_event("StateHolder",0.2, self, self._check_loop)

  for i in pairs(self.states) do
    cs.ActionBarProxy.add_proxy(1, i, StateHolder._button_callback, self)
  end
end

-- const
function StateHolder:add_action(action_name, action)
  self.actions[action_name] = action
end

function StateHolder:attack_action(action_name)
  cs.error_disabler:off()

  cs.auto_attack()

  self.cur_state:recheck()
  self:_do_action(action_name)

  cs.error_disabler:on()

end

function StateHolder:rebuff_heal()
  if cs.check_combat(1, cs.c_normal, cs.c_aggro) then
    if self:_check_hp() then
      cs.rebuff(aura_Concentration)
    end
  end
end


local handler_None = 0
local handler_Change = 1
local handler_Save = 2
local handler_Reset = 3
local handler_FullReset = 4

function StateHolder:_button_callback(bar, button)
  --cs.debug({bar, button, keystate})
  self.states_buttons[button] = {keystate = keystate, ts = GetTime(), handler = handler_None}
end

function StateHolder:_check_loop()
  local ts = GetTime()

  for but, keyinfo in pairs(self.states_buttons) do
    if keyinfo.keystate == cs.ActionBarProxy.key_state_down then
      local state = self.states[but]

      if ts - keyinfo.ts >= 10 and keyinfo.handler < handler_FullReset then
        keyinfo.handler = handler_FullReset
        -- reset config
        cs_states_dynamic_config = default_states_dynamic_config
        state:reset_buffs()
        print("RESET CONFIG!")
      elseif ts - keyinfo.ts >= 6 and keyinfo.handler < handler_Reset then
        keyinfo.handler = handler_Reset
        -- reset state
        state:reset_buffs()
        print("RESET STATE: "..self.cur_state:get_name())
      elseif ts - keyinfo.ts >= 3 and keyinfo.handler < handler_Save then
        keyinfo.handler = handler_Save
        self.cur_state:save_buffs()
        print("SAVE STATE: "..self.cur_state:get_name())
      elseif ts - keyinfo.ts >= 0.55 and keyinfo.handler < handler_Change then
        keyinfo.handler = handler_Change
        -- change
        self:_change_state(but)
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

function StateHolder:_change_state(state_number)
  local state = self.states[state_number]

  if state ~= self.cur_state then
    self.cur_state = state
    self.cur_state:init()
    get_state_holder_config().cur_state = state_number
    print("NEW STATE: "..self.cur_state:get_name())
    return true
  end
end

-- const
function StateHolder:_do_action(name)
  local action = self.actions[name]
  action(self.cur_state)
end

-- const
function StateHolder:_check_hp()
  local hp_level = cs.get_hp_level()
  if not has_debuff_protection() and hp_level <= 0.2 then
    cs.cast(cast_DivineShield, cast_BlessingProtection)
    return nil
  end
  return true
end


---@type StateHolder
local state_holder

local on_load = function()
  if event ~= "VARIABLES_LOADED" then
    return
  end

  state_holder = StateHolder.build()

  local states = cs_states_config.states
  for id in pairs(states) do
    state_holder:add_state(id)
  end
  state_holder:init()


  -- ATTACKS
  state_holder:add_action("rush", function(state)
    if not cs.check_target(cs.t_close_30) then return end

    cs.cast(cast_HolyStrike)

    if state.id ~= state_RUSH then
      if procast_on_seal_Light() then
        return
      end
    end

    seal_and_cast(seal_Righteousness, build_cast_list({ cast_Judgement, cast_CrusaderStrike }))
  end)

  state_holder:add_action("fast", function(state)
    if not cs.check_target(cs.t_close) then return end

    if procast_on_seal_Light() then
      return
    end

    --if state.id == state_RUSH then
    if procast_on_seal_Righteousness() then
      return
    end
    --end

    if not buff_seal(seal_Crusader, {seal_Crusader, seal_Righteousness}) then
      cs.cast(cast_HolyStrike, cast_CrusaderStrike)
    end
  end)

  state_holder:add_action("def", function(state)
    if not cs.check_target(cs.t_close) then return end

    if procast_on_seal_Righteousness() then
      return
    end

    if not target_has_debuff_seal_Light() then
      seal_and_cast(seal_Light, cast_Judgement)
      return
    elseif state.id == state_RUSH then
      cs.cast(cast_CrusaderStrike)
      return
    end

    if not buff_seal(seal_Light) then
      cs.cast(cast_HolyStrike, cast_CrusaderStrike)
    end
  end)

  state_holder:add_action( "null", function(state)
  end)

  state_holder:add_action("mid", function(state)
    if procast_on_seal_Light() then
      return
    end

    seal_and_cast(seal_Righteousness, build_cast_list({ cast_CrusaderStrike }))
  end)

end

local main = function()
  local main_frame = cs.create_simple_frame("pal_main_frame")
  main_frame:RegisterEvent("VARIABLES_LOADED")
  main_frame:SetScript("OnEvent", on_load)
end

main()


-- PUBLIC
function attack_action(name)
  state_holder:attack_action(name)
end

function cast_heal(heal_cast)
  state_holder:rebuff_heal()
  cs.cast(heal_cast)
end




























