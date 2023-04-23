
local cs = cs_common
local pal = cs.pal
local an = pal.an
local heal = pal.heal



local state_holder_frame = {x=415, y=69, text_relative=cs.ui.r.LEFT, mono=true }


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

  local str = pal.to_short(current)
  if not buffed then
    str = str .. pal.to_short()
  elseif buffed ~= current then
    str = str .. cs.color.green .. pal.to_short(buffed).."|r"
  else
    str = str .. "  "
  end

  return str
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
  return pal.get_state_config(self.id, dynamic)[self.name]
end

-- const
function StateBuff:_is_available(value)
  return cs.list_to_dict(self:_get_config().list, "string")[value]
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
          pal.seal.current_to_string()
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
  -- TODO: add reaction on type damage
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
  return pal.get_state_config(self.id, dynamic)
end

-- const
function State:_get_aura()
  local aura_name
  -- buff spell defended auras if enemy casts one
  if self.enemy_spell_base:is_valid() then
    local spell_base = self.enemy_spell_base.base
    if spell_base == cs.spell_base_Frost then
      aura_name = an.Frost
    end
    if spell_base == cs.spell_base_Shadow then
      aura_name = an.Shadow
    end
    if spell_base == cs.spell_base_Fire then
      aura_name = an.Fire
    end
  end

  return aura_name
end

-- const
function State:_get_bless()
  local bless_name = nil

  if not cs.check_target(cs.t.close_10) and not cs.check_combat(1, cs.c.affect) then -- 3 sec after combat
    -- bless_name = bn.Wisdom -- mana regen if not in combat
  end

  return bless_name
end


function State:_standard_rebuff_attack()
  self:rebuff_aura()
  if self.buff_list.bless:tmp_rebuff(self:_get_bless()) then
    return
  end
  if not cs.check_combat(1) then
    pal.blessing_everywhere()
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

  holder.frame = cs.ui.Text:build_from_config(state_holder_frame)

  return holder
end


-- before init
function StateHolder:add_state(id)
  local config = pal.get_state_config(id)
  self.states[config.hotkey] = State.build(id)
end

function StateHolder:init()
  self:_change_state(pal.get_state_holder_config().cur_state)

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

  -- TODO: cast before change state and rebuf ?
  cs.auto_attack()
  self.cur_state:recheck()
  self:_update_frame()

  -- TODO: add usage blessing of freedom on freeze
  self:_do_action(action_name)

  cs.error_disabler:on()

end

function StateHolder:heal_action(heal_cast)
  cs.error_disabler:off()

  if cs.check_combat(1) then
    cs.Buff.build(an.Concentration):rebuff()
    if not pal.heal.check_hp() then
      return
    end
  end

  if self.cur_state.id == pal.stn.HEAL and self.cur_state:rebuff_aura() then
    -- wait rebuff aura
    self:_update_frame()
    return
  end
  cs.cast_helpful(heal_cast)

  cs.error_disabler:on()
end

function StateHolder:_update_frame()
  cs.add_loop_event("StateHolder:_update_frame", 0.3, self, function(holder)
    holder.frame:SetText(holder.cur_state:to_string())
  end, 5)
end

function StateHolder:_down_button_event(longkey, duration)
  local state = self.states[longkey]

  if duration >= StateHolder.handler_FullReset then
    pal.reset_dynamic_config()
    state:reset_buffs()
    cs.print("RESET CONFIG!")
  elseif duration >= StateHolder.handler_Reset then
    state:reset_buffs()
    cs.print("RESET STATE: "..self.cur_state:get_name())
  elseif duration >= StateHolder.handler_Save then
    self.cur_state:save_buffs()
    cs.print("SAVE STATE: "..self.cur_state:get_name())
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
    pal.get_state_holder_config().cur_state = state_number
    cs.print("NEW STATE: "..self.cur_state:get_name())
    return true
  end
end

-- const
function StateHolder:_do_action(name)
  local action = self.actions[name]
  action:run(self.cur_state)
end


---@type StateHolder
local st_state_holder






pal.states = {}
pal.states.init = function()
  st_state_holder = StateHolder.build()

  local states = cs_states_config.states
  for id in pairs(states) do
    st_state_holder:add_state(id)
  end
  st_state_holder:init()

  for action_name, action in pairs(pal.actions) do
    st_state_holder:add_action(action_name, action)
  end

  cs.print(cs.color.green.."CS LOADED")
end





-- PUBLIC
function cs_attack_action(name)
  st_state_holder:attack_action(name)
end

function cs_cast_heal(heal_cast)
  st_state_holder:heal_action(heal_cast)
end
