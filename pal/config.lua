
local cs = cs_common
local pal = cs.pal
local aura = pal.aura
local bless = pal.bless
local spn = pal.spn


local slot = {}
slot.TwoHand = 13
slot.OneHand = 14
slot.OffHand = 15

-- STateName
pal.stn = {}
pal.stn.RUSH = "RUSH"
pal.stn.NORM = "NORM"
pal.stn.DEF = "DEF"
pal.stn.BASE = "BASE"
pal.stn.HEAL = "HEAL"

---@class state_config
local state_config = {
  name = "",
  hotkey = 1,
  color = cs.color.red_1,
  default_aura = aura.Sanctity,
  default_bless = bless.Might,
  aura_list = { aura.Sanctity, aura.Devotion, aura.Retribution },
  bless_list = bless.list_all,

  use_slots = { slot.TwoHand },
}

---@class states_config
local default_states_config = {
  states = {
    ---@type state_config
    RUSH = {
      name = pal.stn.RUSH,
      hotkey = 1,
      color = cs.color.red_1,

      use_slots = { slot.TwoHand },

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
      name = pal.stn.DEF,
      hotkey = 2,
      color = cs.color.white,

      use_slots = { slot.OneHand, slot.OffHand },

      aura = {
        default = aura.Devotion,
        list = aura.list_att,
      },
      bless = {
        default = bless.Kings,
        list = bless.list_all,
      },
    },
    NORM = {
      name = pal.stn.NORM,
      hotkey = 3,
      color = cs.color.green,
      use_slots = { slot.TwoHand },
      aura = {
        default = aura.Retribution,
        list = aura.list_att,
      },
      bless = {
        default = bless.Kings,
        list = bless.list_all,
      },
    },
    BASE = {
      name = pal.stn.BASE,
      hotkey = 4,
      color = cs.color.blue,

      aura = {
        default = aura.Retribution,
        list = aura.list_att,
      },
      bless = {
        default = bless.Kings,
        list = bless.list_all,
      },
    },
    HEAL = {
      name = pal.stn.HEAL,
      hotkey = 12 * 5 + 2,
      color = cs.color.yellow,

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

pal.reset_dynamic_config = function()
  cs_states_dynamic_config = default_states_dynamic_config
end

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




