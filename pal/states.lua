
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
  local current = self:_get_config_current()

  local str = pal.to_print(current)
  if not buffed then
    str = str .. pal.to_print()
  elseif buffed ~= current then
    str = str .. cs.color.green .. pal.to_print(buffed).."|r"
  else
    str = str .. "  "
  end

  return str
end


-- set temporary buff and dont save it to config
function StateBuff:rebuff(buff_name)
  local combat = cs.check_target(cs.t.attackable) and cs.check_target(cs.t.close_30) or cs.check_combat(1, cs.c.affect)
  if not buff_name and not combat then
    -- no combat
    buff_name = self:_get_config().no_combat or buff_name
  end

  if not buff_name or not self:_is_available(buff_name) then
    -- set current
    buff_name = self:_get_config_current()
  end

  -- aura/bless
  self.current = pal[self.name].get_buff(buff_name)

  return self.current:rebuff()
end

-- set buff and save it to config
function StateBuff:set_current(buff_name)
  self:rebuff(buff_name or self:_get_config().default)
  self:_set_config_current(self.current:get_name())
end

function StateBuff:save_buffed_to_config()
  local current = self:get_buffed()
  self:set_current(current)
end

function StateBuff:_get_config_current()
  self:_get_config(1).current = self:_get_config(1).current or self:_get_config().default
  return self:_get_config(1).current
end

function StateBuff:_set_config_current(value)
  self:_get_config(1).current = value
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

  ---@type cs.MultiSlot
  state.default_slot = state:_get_config().use_slot
  state.slot = nil

  return state
end

-- const
function State:get_type()
  return self:_get_config().type
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
          pal.to_print(pal.seal.get_current())
  return msg
end


function State:init()
  if self.default_slot then
    self.slot = self.default_slot
  else
    self.slot = cs.slot.two_hand:is_equipped() and cs.slot.two_hand or cs.slot.one_hand_shield
  end
  self:recheck()
end

-- save current custom buffs
function State:save_buffs()
  self:_every_buff(StateBuff.save_buffed_to_config)
end

function State:reset_buffs()
  self:_every_buff(StateBuff.set_current)
end

function State:recheck()
  self.slot:try_use()
  self:_standard_rebuff_attack()
end

function State:rebuff_aura()
  return self.buff_list.aura:rebuff(self:_get_aura())
end


-- const
function State:_get_config(dynamic)
  return pal.get_state_config(self.id, dynamic)
end

-- const
function State:_get_aura()
  local aura_name
  -- buff spell defended auras if enemy casts one
  local spell_school = pal.resist.analyzer:get_school()
  if spell_school then
    if spell_school == cs.ss.Frost then
      aura_name = an.Frost
    end
    if spell_school == cs.ss.Shadow then
      aura_name = an.Shadow
    end
    if spell_school == cs.ss.Fire then
      aura_name = an.Fire
    end
  end

  return aura_name
end


function State:_standard_rebuff_attack()
  self:rebuff_aura()
  if self.buff_list.bless:rebuff() then
    -- rebless player first,
    return
  end
  if not cs.check_combat(1) then
    pal.bless.blessing_everywhere()
  end
end

function State:_every_buff(fun, ...)
  for _, buff in pairs(self.buff_list) do
    fun(buff, unpack(arg))
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

  if not pal.heal.check_no_control() then
    return
  end

  -- TODO cast aura on damage
  if cs.check_combat(1) then
    cs.Buff.build(an.Concentration):rebuff()
    if not pal.heal.check_hp() then
      return
    end
  end
  --
  --if cs.services.speed_checker:is_moving() then
  --  pal.sp.Cleanse:cast_helpful()
  --  return
  --end

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
    holder.frame:set_text(holder.cur_state:to_string())
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
  action:run(self.cur_state:get_type())
end


---@type StateHolder
local st_state_holder






pal.states = {}
pal.states.init = function()
  st_state_holder = StateHolder.build()

  local states = pal.get_state_list()
  cs.debug(states)
  for _, id in pairs(states) do
    st_state_holder:add_state(id)
  end
  st_state_holder:init()

  for action_name, action in pairs(pal.actions.dict) do
    st_state_holder:add_action(action_name, action)
  end
end

pal.states.test = function()
  for name in pairs(pal.actions.dict) do
    cs_attack_action(name)
  end

  local init_state = pal.get_state_holder_config().cur_state
  st_state_holder:_down_button_event(1, 1)
  st_state_holder:_down_button_event(2, 1)
  st_state_holder:_down_button_event(3, 1)
  st_state_holder:_down_button_event(4, 1)
  st_state_holder:_down_button_event(init_state, 1)
end



-- PUBLIC
function cs_attack_action(name)
  st_state_holder:attack_action(name)
end

function cs_cast_heal(heal_cast)
  st_state_holder:heal_action(heal_cast)
end
