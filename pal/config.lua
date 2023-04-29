
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


cs_states_dynamic_config = {}

pal.reset_dynamic_config = function()
  cs_states_dynamic_config = {}
end

pal.get_state_holder_config = function()
  cs_states_dynamic_config.state_holder = cs_states_dynamic_config.state_holder or {}
  cs_states_dynamic_config.state_holder.cur_state = cs_states_dynamic_config.state_holder.cur_state or 1

  return cs_states_dynamic_config.state_holder
end

local states_config

--TODO: fix config
pal.get_state_config = function(id, dynamic)
  if dynamic then
    cs_states_dynamic_config.states = cs_states_dynamic_config.states or {}
    cs_states_dynamic_config.states[id] = cs_states_dynamic_config.states[id] or { aura = {}, bless = {} }
    return cs_states_dynamic_config.states[id]
  end
  return states_config.states[id]
end

pal.get_state_list =function()
  return cs.dict_keys_to_list(states_config.states, "string")
end

pal.config = {}

pal.config.init = function()
  local bless_avail_list = bn.get_available()

  local states_config_1 = {
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

  local states_config_2 = {
    states = {
      ---@type state_config
      RUSH = {
        name = pal.stn.RUSH,
        hotkey = 1,
        color = cs.color.red_1,

        use_slot = cs.slot.two_hand,

        aura = {
          default = an.Retribution,
          list = an.list_att,
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
          default = bn.Sanctuary,
          no_combat = bn.Wisdom,
          list = bless_avail_list,
        },
      },
      BACK = {
        name = "BACK",
        hotkey = 3,
        color = cs.color.purple,
        use_slot = cs.slot.one_hand_shield,

        aura = {
          default = an.Retribution,
          list = an.list_att,
        },
        bless = {
          default = bn.Sanctuary,
          no_combat = bn.Wisdom,
          list = bless_avail_list,
        },
      },
      NORM = {
        name = "NORM",
        hotkey = 4,
        color = cs.color.green,
        use_slot = cs.slot.one_hand_shield,
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
      MANA = {
        name = "MANA",
        hotkey = 5,
        color = cs.color.blue,
        -- use_slot = cs.slot.one_hand_shield,

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

  states_config = states_config_2

end

