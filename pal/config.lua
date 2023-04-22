
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




