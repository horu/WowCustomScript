
local cs = cs_common
local pal = cs.pal
local aura = pal.aura
local bless = pal.bless
local cast = pal.cast



local slot_TwoHand = 13
local slot_OneHand = 14
local slot_OffHand = 15

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
  default_aura = aura.Sanctity,
  default_bless = bless.Might,
  aura_list = { aura.Sanctity, aura.Devotion, aura.Retribution },
  bless_list = bless.list_all,

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
        default = aura.Sanctity,
        list = { aura.Sanctity, aura.Devotion, aura.Retribution },
      },
      bless = {
        default = bless.Might,
        list = bless.list_all,
      },
    },
    DEF = {
      name = state_DEF,
      hotkey = 2,
      color = cs.color_white,

      use_slots = { slot_OneHand, slot_OffHand },

      aura = {
        default = aura.Devotion,
        list = aura.list_att,
      },
      bless = {
        default = bless.Wisdom,
        list = bless.list_all,
      },
    },
    NORM = {
      name = state_NORM,
      hotkey = 3,
      color = cs.color_green,
      aura = {
        default = aura.Retribution,
        list = aura.list_att,
      },
      bless = {
        default = bless.Might,
        list = bless.list_all,
      },
    },
    BASE = {
      name = state_BASE,
      hotkey = 4,
      color = cs.color_blue,

      aura = {
        default = aura.Retribution,
        list = aura.list_att,
      },
      bless = {
        default = bless.Wisdom,
        list = bless.list_all,
      },
    },
    HEAL = {
      name = state_HEAL,
      hotkey = 12 * 5 + 2,
      color = cs.color_yellow,

      aura = {
        default = aura.Concentration,
        list = { aura.Concentration },
      },
      bless = {
        default = bless.Light,
        list = bless.list_all,
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

pal.get_state_holder_config = function()
  return cs_states_dynamic_config.state_holder
end

---@return state_config
pal.get_state_config = function(id, dynamic)
  if dynamic then
    return cs_states_dynamic_config.states[id]
  end
  return cs_states_config.states[id]
end





pal.actions = {}


local function build_cast_list(cast_list)
  cast_list = cs.to_table(cast_list)

  local target = UnitCreatureType("target")
  if target == "Demon" or target == "Undead" then
    table.insert(cast_list, 1, cast.Exorcism)
  end
  return cast_list
end

  -- ATTACKS
pal.actions.rush = function(state)
  if not cs.check_target(cs.t_close_30) then return end

  cs.cast(cast.HolyStrike)

  if state.id ~= state_RUSH then
    if pal.Seal.seal_Light:judgement_it() or pal.Seal.seal_Wisdom:judgement_it() then
      return
    end
  end

  pal.Seal.seal_Righteousness:reseal_and_cast(build_cast_list({ cast.Judgement, cast.CrusaderStrike }))
end

pal.actions.fast = function(state)
  if not cs.check_target(cs.t_close) then return end

  if pal.Seal.seal_Light:judgement_it() or pal.Seal.seal_Righteousness:judgement_it() or pal.Seal.seal_Wisdom:judgement_it() then
    return
  end

  pal.Seal.seal_Crusader:reseal_and_cast(cast.HolyStrike, cast.CrusaderStrike)
end

local def_mana_action = function(state, first_seal, second_seal)
  if not cs.check_target(cs.t_close) then return end

  if not first_seal:is_available() then
    cs.cast(cast.HolyStrike, cast.CrusaderStrike)
    return
  end

  if pal.Seal.seal_Righteousness:judgement_it() or second_seal:judgement_it() then
    return
  end

  if first_seal:is_judgement_available() and second_seal:is_judgement_available() then
    first_seal:reseal_and_cast(cast.Judgement)
    return
  end

  if state.id == state_RUSH then
    cs.cast(cast.CrusaderStrike)
    return
  end

  first_seal:reseal_and_cast(cast.HolyStrike, cast.CrusaderStrike)
end

pal.actions.def = function(state)
  def_mana_action(state, pal.Seal.seal_Light, pal.Seal.seal_Wisdom)
end

pal.actions.mana = function(state)
  def_mana_action(state, pal.Seal.seal_Wisdom, pal.Seal.seal_Light)
end

-- TODO: add SoJ




