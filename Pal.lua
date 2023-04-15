

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
  if cs.in_combat() then return end

  local size = GetNumPartyMembers()
  for i=1, size do
    local unit = "party"..i
    rebuff_party_member(unit)
    local pet = "partypet"..i
    rebuff_party_member(pet)
  end
end








--main


local aura_saver = cs.create_buff_saver(aura_list_all)
local bless_saver = cs.create_buff_saver(bless_list_all)
local function standard_rebuff_attack(aura_list)
  -- cs.rebuff last bless/aura
  cs.rebuff(aura_saver:get_buff(aura_list))
  cs.rebuff(bless_saver:get_buff())
  if cs.is_in_party() then
    cs.rebuff(buff_Righteous)
    buff_party()
  end
end

local function rebuff_heal()
  if cs.in_aggro() or cs.in_combat() then
    cs.rebuff(aura_Concentration)
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



-- CAST

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





local function create_state(name, aura_list, bless_list)
  local state = { aura_list = aura_list, bless_list = bless_list }

  state.name = name
  state.aura = aura_list[1]
  state.bless = bless_list[1]
  state.is_init = nil
  state.standard_rebuff_attack = function(self)
    self:rebuff_aura()
    self:rebuff_bless()
    if cs.is_in_party() then
      cs.rebuff(buff_Righteous)
      buff_party()
    end
  end
  state.rebuff_aura = function(self)
    if cs.rebuff(self.aura) then
      self.is_init = nil
    end
  end
  state.rebuff_bless = function(self)
    if cs.rebuff(self.bless) then
      self.is_init = nil
    end
  end
  state.on_buff_changed = function(self)
    if not self.is_init then
      -- state is not initializated yet. Ignore new buffs.
      self.is_init = cs.find_buff(self.aura) and cs.find_buff(self.bless)
      if self.is_init then
        print("INIT STATE: "..self.name.." |         A: "..self.aura.." |          B:"..(self.bless or ""))
      end
      return
    end

    local _, aura = cs.find_buff(aura_list)
    if aura and self.aura ~= aura then
      self.aura = aura
      print("CHANGE STATE: "..self.name.." |         A: "..self.aura.." |          B:"..(self.bless or ""))
    end

    local _, bless = cs.find_buff(bless_list)
    if bless and self.bless ~= bless then
      self.bless = bless
      print("CHANGE STATE: "..self.name.." |         A: "..self.aura.." |          B:"..(self.bless or ""))
    end

  end

  state.actions = {}

  state.do_action = function(self, name)
    local action = self.actions[name]
    action(self)
  end

  return state
end



local function create_state_holder()
  local f = cs.create_simple_frame("CS_create_current_state")

  f:RegisterEvent("UNIT_AURA")
  f:SetScript("OnEvent", function()
    if this.cs_state then
      this.cs_state:on_buff_changed()
    end
  end)

  f.cs_state = nil

  f.change_state = function(self, state_name)
    self.cs_state = self.states[state_name]
  end

  f.attack_action = function(self, action_name)
    cs.error_disabler:off()
    cs.auto_attack()
    local state_name = nil
    for state_name_it, state_it in pairs(self.states) do
      if state_it.actions[action_name] then
        state_name = state_name_it
        break
      end
    end

    self:change_state(state_name)
    self.cs_state:do_action(action_name)
    cs.error_disabler:on()
  end

  f.states = {}

  f.add_state = function(self, state_name, a1, a2, a3)
    self.states[state_name] = create_state(state_name, a1, a2, a3)
  end

  f.add_action = function(self, state_name, action_name, action)
    self.states[state_name].actions[action_name] = action
  end

  return f
end

local state_holder = create_state_holder()
function attack_action(name)
  state_holder:attack_action(name)
end

-- ATTACKS
state_holder:add_state("rush", { aura_Sanctity }, { bless_Might })
state_holder:add_action("rush", "rush", function(state)

  -- cast exorcism and holy strike on one click before change state
  cast(cast_HolyStrike)
  if not cs.find_buff(aura_Sanctity) then
    local exorcism = build_cast_list({})[1]
    if exorcism then
      cast(exorcism)
    end
  end

  state:rebuff_aura()
  if not cs.find_buff(aura_Sanctity) then
    return
  end

  state:rebuff_bless()

  -- seal_and_cast(seal_Righteousness, cast_HolyStrike)
  seal_and_cast(seal_Righteousness, build_cast_list({ cast_Judgement, cast_CrusaderStrike }))
end)

state_holder:add_state("normal", aura_list_def, bless_list_all)
state_holder:add_action("normal", "mid", function(state)
  state:standard_rebuff_attack()

  if cs.find_buff(seal_Light) and not target_has_debuff_seal_Light() then
    cast(cast_Judgement)
    return
  end

  seal_and_cast(seal_Righteousness, build_cast_list({ cast_CrusaderStrike }))
end)

state_holder:add_action("normal", "fast", function(state)
  state:standard_rebuff_attack()
  if not cs.check_target(cs.t_close) then
    return
  end

  if cs.find_buff(seal_Light) and not target_has_debuff_seal_Light() then
    cast(cast_Judgement)
    return
  end

  seal_and_cast(seal_Crusader, cast_CrusaderStrike, {seal_Crusader, seal_Righteousness})
end)

state_holder:add_action("normal", "def", function(state)
  state:standard_rebuff_attack()
  if not cs.check_target(cs.t_close) then
    return
  end

  if cs.find_buff(seal_Righteousness) then
    cast(cast_Judgement)
    return
  end

  if not target_has_debuff_seal_Light() then
    seal_and_cast(seal_Light, cast_Judgement)
    return
  end

  buff_seal(seal_Light)
  -- seal_and_cast(seal_Light, cast_HolyStrike)
  -- seal_and_cast(seal_Light, build_cast_list({ }))
end)

state_holder:add_action("normal", "null", function(state)
  state:standard_rebuff_attack()
end)

state_holder:add_state("heal", { aura_Concentration }, {})

function cast_heal(heal_cast)
  state_holder:change_state("heal")
  rebuff_heal()
  cast(heal_cast)
end




























