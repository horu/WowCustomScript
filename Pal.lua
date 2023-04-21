local cs = cs_common

-- +TODO: Combat bless
-- invit overmouse


local state_holder_frame = {"StateHolder.build", "BOTTOMLEFT",415, 69, "", "LEFT", true, false, }


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
local bless_Light = "Blessing of Light"
local bless_list_all = { bless_Wisdom, bless_Might, bless_Salvation, bless_Light }

local seal_Righteousness = "Seal of Righteousness"
local seal_Crusader = "Seal of the Crusader"
local seal_Justice = "Seal of Justice"
local seal_Light = "Seal of Light"
local seal_Wisdom = "Seal of Wisdom"
local seal_list_all = { seal_Righteousness, seal_Crusader, seal_Justice, seal_Light, seal_Wisdom }

local slot_TwoHand = 13
local slot_OneHand = 14
local slot_OffHand = 15


local to_short_list = {}
to_short_list[aura_Concentration] = cs.color_yellow .. "CA" .. "|r"
to_short_list[aura_Devotion] = cs.color_white .. "DA" .. "|r"
to_short_list[aura_Sanctity] = cs.color_red .. "SA" .. "|r"
to_short_list[aura_Retribution] = cs.color_purple .. "RA" .. "|r"
to_short_list[aura_Shadow] = cs.color_purple .. "SH" .. "|r"
to_short_list[aura_Frost] = cs.color_blue .. "FR" .. "|r"
to_short_list[aura_Fire] = cs.color_orange_1 .. "FI" .. "|r"

to_short_list[bless_Wisdom] = cs.color_blue .. "BW" .. "|r"
to_short_list[bless_Might] = cs.color_red .. "BM" .. "|r"
to_short_list[bless_Salvation] = cs.color_white .. "BV" .. "|r"
to_short_list[bless_Light] = cs.color_yellow .. "BL" .. "|r"

to_short_list[seal_Righteousness] = cs.color_purple.."SR".."|r"
to_short_list[seal_Crusader] = cs.color_orange_1.."SC".."|r"
to_short_list[seal_Light] = cs.color_yellow.."SL".."|r"
to_short_list[seal_Justice] = cs.color_green.."SJ".."|r"
to_short_list[seal_Wisdom] = cs.color_blue.."SW".."|r"

local to_short = function(cast)
  if not cast then
    return cs.color_grey.."XX".."|r"
  end
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

  local buff_name = class and buffs[class] or bless_Might
  if not buff_name then
    print("BUFF NOT FOUND FOR "..class)
    buff_name = bless_Might
  end

  local buff = cs.Buff.build(buff_name, unit)
  if cs.find_buff(bless_list_all, unit) then
    return
  end

  local result = buff:rebuff()

  if result == cs.Buff.success then
    print("BUFF: ".. to_short(buff:get_name()) .. " FOR ".. pfUI.api.GetUnitColor(unit) .. class)
  end
  return result
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

local alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
local function rebuff_anybody()
  if not cs.check_combat(cs.c_affect) and not cs.check_target(cs.t_exists) then
    for i=1,strlen(alphabet) do
      local name = string.sub(alphabet, i, i)
      TargetByName(name)
      if cs.check_target(cs.t_fr_player) then
        rebuff_unit("target")
      end
      ClearTarget()
    end
  end
end







-- CAST

local cast_DivineShield = "Divine Shield"
local cast_DivineProtection = "Divine Protection"
local cast_BlessingProtection = "Blessing of Protection"
local cast_LayOnHands = "Lay on Hands"

local cast_shield_list = {cast_DivineShield, cast_BlessingProtection}

local cast_Judgement = "Judgement"
local cast_CrusaderStrike = "Crusader Strike"
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

local function has_debuff_protection()
  return cs.has_debuffs(cs.u_target, "Spell_Holy_RemoveCurse")
end









-- SEAL
---@class Seal
local Seal = cs.create_class()

Seal.init = function()
  -- TODO: dont debuff one unit with low hp ( dps and npc )
  Seal.seal_Righteousness = Seal.build(seal_Righteousness)
  Seal.seal_Crusader = Seal.build(seal_Crusader)
  Seal.seal_Light = Seal.build(
          seal_Light,
          UnitHealthMax(cs.u_player) * 0.2,
          "Spell_Holy_HealingAura"
  )
  Seal.seal_Wisdom = Seal.build(
          seal_Wisdom,
          UnitHealthMax(cs.u_player) * 0.2,
          "Spell_Holy_RighteousnessAura"
  )
end

Seal.build = function(buff, target_hp_limit, target_debuff)
  local seal = Seal:new()

  seal.buff = cs.Buff.build(buff)
  seal.target_debuff = target_debuff
  seal.judgement = cs.Spell.build(cast_Judgement)
  seal.target_hp_limit = target_hp_limit or 0

  cs.debug(seal)

  return seal
end

-- const
function Seal:is_judgement_available()
  if self:check_target_debuff() then
    return
  end

  return self:is_available()
end

function Seal:check_target_debuff()
  if not self.target_debuff then
    return
  end

  return cs.has_debuffs(cs.u_target, self.target_debuff)
end

-- const
function Seal:check_exists()
  return self.buff:check_exists()
end

-- const
function Seal:is_available()
  if not cs.check_target(cs.t_attackable) then
    return
  end

  local target_hp = UnitHealth(cs.u_target) or 0
  return target_hp >= self.target_hp_limit
end

function Seal:reseal()
  if not self:is_available() then
    return cs.Buff.failed
  end
  return self.buff:rebuff()
end

-- return true on success cast
function Seal:reseal_and_cast(...)
  if self:reseal() then
    return
  end

  local order = cs.SpellOrder.build(unpack(arg))
  return order:cast()
end

function Seal:judgement_it()
  if self:check_exists() and self:is_judgement_available() then
    self.judgement:cast()
    return true
  end
end











local EmegryCaster = cs.create_class()

EmegryCaster.build = function()
  local caster = EmegryCaster:new()
  caster.shield_ts = 0
  caster.spell_order = cs.SpellOrder.build(cast_shield_list)
  caster.lay_spell = cs.Spell.build(cast_LayOnHands)
  return caster
end

function EmegryCaster:em_buff(lay)
  local casted_shield = has_debuff_protection()
  if not casted_shield then
    local spell = self.spell_order:cast(cs.u_player)
    if spell then
      self.shield_ts = spell.cast_ts
      return cs.Buff.success
    end
  end

  if cs.compare_time(8, self.shield_ts) or cs.find_buff({cast_DivineShield, cast_BlessingProtection}) then
    return cs.Buff.exists
  end

  if cs.get_spell_cd(cast_LayOnHands) then
    return cs.Buff.exists
  end

  if not lay then
    return cs.Buff.exists
  end

  cs.debug("Lay")
  self.lay_spell:cast_to_unit(cs.u_player)
  return cs.Buff.success
end

local em_caster











-- ID
local state_RUSH = "RUSH"
local state_NORM = "NORM"
local state_DEF = "DEF"
local state_BASE = "BASE"
local state_HEAL = "HEAL"

---@class state_config
local state_config = {
      name = "",
      hotkey = 1,
      color = cs.color_red_1,
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
      name = state_RUSH,
      hotkey = 1,
      color = cs.color_red_1,

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
    DEF = {
      name = state_DEF,
      hotkey = 2,
      color = cs.color_white,

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
    NORM = {
      name = state_NORM,
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
    BASE = {
      name = state_BASE,
      hotkey = 4,
      color = cs.color_blue,

      aura = {
        default = aura_Retribution,
        list = aura_list_att,
      },
      bless = {
        default = bless_Wisdom,
        list = bless_list_all,
      },
    },
    HEAL = {
      name = state_HEAL,
      hotkey = 12 * 5 + 2,
      color = cs.color_yellow,

      aura = {
        default = aura_Concentration,
        list = { aura_Concentration },
      },
      bless = {
        default = bless_Light,
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
    HEAL = {
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
  ---@type cs.Buff
  buff.current = nil

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
    str = str .. to_short()
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
  local current = self.current and self.current:get_name()

  if buffed == default then
    return status_DEFAULT
  end
  if buffed == config then
    return status_MODIFIED
  end
  if buffed == current then
    return status_TEMP
  end
  return status_NONE
end


-- set temporary buff and dont save it to config
function StateBuff:tmp_rebuff(buff_name)
  if not buff_name or not self:_is_available(buff_name) then
    buff_name = self:_get_config(1).current
  end

  self.current = cs.Buff.build(buff_name)

  return self.current:rebuff()
end

-- set buff and save it to config
function StateBuff:reset(buff_name)
  self:tmp_rebuff(buff_name or self:_get_config().default)
  self:_get_config(1).current = self.current:get_name()
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
    return self.base and cs.compare_time(7, self.ts)
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

function State:rebuff_aura()
  return self.buff_list.aura:tmp_rebuff(self:_get_aura())
end

-- reacion for enenmy cast to change resist aura
---@param spell_data cs.SpellData
function State:on_cast_detected(spell_data)
  local spell_base = spell_data:get_base()
  if not spell_base then
    return
  end

  if not self.enemy_spell_base:is_valid() or self.enemy_spell_base.base ~= spell_base then
    cs.debug(spell_data)
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
  if self.enemy_spell_base:is_valid() then
    local spell_base = self.enemy_spell_base.base
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

  if not cs.check_target(cs.t_attackable) and not cs.check_combat(1, cs.c_affect) then -- 3 sec after combat
    bless = bless_Wisdom -- mana regen if not in combat
  end

  return bless
end

function State:_get_seal_string()
  local seal = cs.find_buff(seal_list_all)
  return to_short(seal)
end


function State:_standard_rebuff_attack()
  self:rebuff_aura()
  if self.buff_list.bless:tmp_rebuff(self:_get_bless()) then
    return
  end
  if not cs.check_combat(1) then
    if cs.is_in_party() then
      cs.Buff.build(buff_Righteous):rebuff()
      buff_party()
    end
    if cs.check_target(cs.t_fr_player) then
      rebuff_unit(cs.u_target)
    elseif cs.check_mouse(cs.t_fr_player) then
      rebuff_unit(cs.u_mouseover)
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

StateHolder.handler_Change = 0.55
StateHolder.handler_Save = 3
StateHolder.handler_Reset = 6
StateHolder.handler_FullReset = 10

StateHolder.build = function()
  ---@type StateHolder
  local holder = StateHolder:new()

  ---@type State
  holder.cur_state = nil
  ---@type State[]
  holder.states = {}

  holder.actions = {}

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

  for longkey in pairs(self.states) do
    cs.st_button_checker:add_button(longkey)
  end

  cs.st_button_checker:add_down_pattern(StateHolder.handler_Change, self, StateHolder._down_button_event)
  cs.st_button_checker:add_down_pattern(StateHolder.handler_Save, self, StateHolder._down_button_event)
  cs.st_button_checker:add_down_pattern(StateHolder.handler_Reset, self, StateHolder._down_button_event)
  cs.st_button_checker:add_down_pattern(StateHolder.handler_FullReset, self, StateHolder._down_button_event)

  cs.st_cast_checker:add_callback(self, self._on_cast_detected)
end

-- const
function StateHolder:add_action(action_name, action)
  self.actions[action_name] = action
end

function StateHolder:attack_action(action_name)
  cs.error_disabler:off()

  self.cur_state:recheck()
  self:_update_frame()

  cs.auto_attack()
  self:_do_action(action_name)

  cs.error_disabler:on()

end

function StateHolder:heal_action(heal_cast)
  cs.error_disabler:off()

  self:_rebuff_heal()
  if self.cur_state.id == state_HEAL and self.cur_state:rebuff_aura() then
    self:_update_frame()
    return
  end
  cs.cast_helpful(heal_cast)

  cs.error_disabler:on()
end

function StateHolder:_rebuff_heal()
  if cs.check_combat(1) then
    if self:_check_hp() then
      cs.Buff.build(aura_Concentration):rebuff()
    end
  end
end

function StateHolder:_update_frame()
  cs.add_loop_event("StateHolder:_update_frame", 0.3, self, function(holder)
    holder.frame:CS_SetText(holder.cur_state:to_string())
  end, 5)
end

function StateHolder:_down_button_event(longkey, duration)
  local state = self.states[longkey]

  if duration >= StateHolder.handler_FullReset then
    cs_states_dynamic_config = default_states_dynamic_config
    state:reset_buffs()
    print("RESET CONFIG!")
  elseif duration >= StateHolder.handler_Reset then
    state:reset_buffs()
    print("RESET STATE: "..self.cur_state:get_name())
  elseif duration >= StateHolder.handler_Save then
    self.cur_state:save_buffs()
    print("SAVE STATE: "..self.cur_state:get_name())
  elseif duration >= StateHolder.handler_Change then
    self:_change_state(longkey)
  end
end

function StateHolder:_on_cast_detected(spell_data)
  self.cur_state:on_cast_detected(spell_data)
end

function StateHolder:_change_state(state_number)
  local state = self.states[state_number]

  if state ~= self.cur_state then
    self.cur_state = state
    self.cur_state:init()
    self:_update_frame()
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
  -- TODO: fix bag
  local hp_level = cs.get_hp_level()
  if hp_level <= 0.2 then
    if em_caster:em_buff(hp_level <= 0.1) ~= cs.Buff.exists then
      return nil
    end
  end
  return true
end






---@type StateHolder
local state_holder

local on_load = function()
  Seal.init()

  em_caster = EmegryCaster.build()

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
      if Seal.seal_Light:judgement_it() or Seal.seal_Wisdom:judgement_it() then
        return
      end
    end

    Seal.seal_Righteousness:reseal_and_cast(build_cast_list({ cast_Judgement, cast_CrusaderStrike }))
  end)

  state_holder:add_action("fast", function(state)
    if not cs.check_target(cs.t_close) then return end

    if Seal.seal_Light:judgement_it() or Seal.seal_Righteousness:judgement_it() or Seal.seal_Wisdom:judgement_it() then
      return
    end

    Seal.seal_Crusader:reseal_and_cast(cast_HolyStrike, cast_CrusaderStrike)
  end)

  local def_mana_action = function(state, first_seal, second_seal)
    if not cs.check_target(cs.t_close) then return end

    if not first_seal:is_available() then
      cs.cast(cast_HolyStrike, cast_CrusaderStrike)
      return
    end

    if Seal.seal_Righteousness:judgement_it() or second_seal:judgement_it() then
      return
    end

    if first_seal:is_judgement_available() and second_seal:is_judgement_available() then
      first_seal:reseal_and_cast(cast_Judgement)
      return
    end

    if state.id == state_RUSH then
      cs.cast(cast_CrusaderStrike)
      return
    end

    first_seal:reseal_and_cast(cast_HolyStrike, cast_CrusaderStrike)
  end

  state_holder:add_action("def", function(state)
    def_mana_action(state, Seal.seal_Light, Seal.seal_Wisdom)
  end)

  state_holder:add_action( "mana", function(state)
    def_mana_action(state, Seal.seal_Wisdom, Seal.seal_Light)
  end)

end







local main = function()
  -- defer load
  local main_frame = cs.create_simple_frame("pal_main_frame")
  main_frame:RegisterEvent("VARIABLES_LOADED")
  main_frame:SetScript("OnEvent", function()
    if event ~= "VARIABLES_LOADED" then
      return
    end

    cs.add_loop_event_once("main_frame", 0.2, nil, on_load)
  end)
end

main()


-- PUBLIC
function cs_attack_action(name)
  state_holder:attack_action(name)
end

function cs_cast_heal(heal_cast)
  state_holder:heal_action(heal_cast)
end

function cs_emegrancy()
  em_caster:em_buff(true)
end

function cs_rebuff_unit()
  local unit = cs.u_target
  if not cs.check_target(cs.t_exists) then
    unit = cs.u_mouseover
  end
  rebuff_unit(unit)
end

function cs_rebuff_anybody()
  rebuff_anybody()
end
























