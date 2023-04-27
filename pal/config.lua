
local cs = cs_common
local pal = cs.pal
local an = pal.an
local bn = pal.bn
local spn = pal.spn


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
  default_aura = an.Sanctity,
  default_bless = bn.Might,
  aura_list = { an.Sanctity, an.Devotion, an.Retribution },
  bless_list = bn.list_all,

  use_slot = cs.one_hand_shield,
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

cs_states_dynamic_config = default_states_dynamic_config

pal.reset_dynamic_config = function()
  cs_states_dynamic_config = default_states_dynamic_config
end

pal.get_state_holder_config = function()
  return cs_states_dynamic_config.state_holder
end

local default_states_config

---@return state_config
pal.get_state_config = function(id, dynamic)
  if dynamic then
    return cs_states_dynamic_config.states[id]
  end
  return default_states_config.states[id]
end

pal.get_state_list =function()
  return cs.dict_keys_to_list(default_states_config.states, "string")
end

pal.config = {}
pal.config.init = function()
  local bless_avail_list = bn.get_available()

  ---@class states_config
  default_states_config = {
    states = {
      ---@type state_config
      RUSH = {
        name = pal.stn.RUSH,
        hotkey = 1,
        color = cs.color.red_1,

        use_slot = cs.slot.two_hand,

        aura = {
          default = an.Sanctity,
          list = { an.Sanctity, an.Devotion, an.Retribution },
        },
        bless = {
          default = bn.Might,
          list = bless_avail_list,
        },
      },
      DEF = {
        name = pal.stn.DEF,
        hotkey = 2,
        color = cs.color.white,

        use_slot = cs.slot.one_hand_shield,

        aura = {
          default = an.Devotion,
          list = an.list_att,
        },
        bless = {
          default = bn.Wisdom,
          no_combat = bn.Wisdom,
          list = bless_avail_list,
        },
      },
      NORM = {
        name = pal.stn.NORM,
        hotkey = 3,
        color = cs.color.green,
        use_slot = cs.slot.two_hand,
        aura = {
          default = an.Retribution,
          list = an.list_att,
        },
        bless = {
          default = bn.Might,
          no_combat = bn.Wisdom,
          list = bless_avail_list,
        },
      },
      BASE = {
        name = pal.stn.BASE,
        hotkey = 4,
        color = cs.color.blue,

        aura = {
          default = an.Retribution,
          list = an.list_att,
        },
        bless = {
          default = bn.Wisdom,
          no_combat = bn.Wisdom,
          list = bless_avail_list,
        },
      },
      HEAL = {
        name = pal.stn.HEAL,
        hotkey = 12 * 5 + 2,
        color = cs.color.yellow,

        aura = {
          default = an.Concentration,
          list = { an.Concentration },
        },
        bless = {
          default = bn.Light,
          list = bless_avail_list,
        },
      },
    }
  }


end

