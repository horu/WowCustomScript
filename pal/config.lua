
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
pal.stn.BACK = "BACK"
pal.stn.MANA = "MANA"
pal.stn.HEAL = "HEAL"

-- STateType
pal.stt = {}
pal.stt.damage = "damage"
pal.stt.def = "def"


local default_states_config = {
  states = {
    RUSH = {
      name = pal.stn.RUSH,
      type = pal.stt.damage,
      hotkey = 1,
      color = cs.color.red_1,

      use_slot = cs.slot.two_hand,

      aura = {
        current = an.Retribution,
        list = an.list_att,
      },
      bless = {
        current = bn.Might,
        no_combat = bn.Wisdom,
        list = bn.list_all,
      },
    },
    DEF = {
      name = pal.stn.DEF,
      type = pal.stt.def,
      hotkey = 2,
      color = cs.color.white,

      use_slot = cs.slot.one_hand_shield,

      aura = {
        current = an.Devotion,
        list = an.list_att,
      },
      bless = {
        current = bn.Sanctuary,
        no_combat = bn.Wisdom,
        list = bn.list_all,
      },
    },
    BACK = {
      name = "BACK",
      type = pal.stt.def,
      hotkey = 3,
      color = cs.color.purple,
      use_slot = cs.slot.one_hand_shield,

      aura = {
        current = an.Retribution,
        list = an.list_att,
      },
      bless = {
        current = bn.Sanctuary,
        no_combat = bn.Wisdom,
        list = bn.list_all,
      },
    },
    MANA = {
      name = "MANA",
      type = pal.stt.def,
      hotkey = 4,
      color = cs.color.blue,
      -- use_slot = cs.slot.one_hand_shield,

      aura = {
        current = an.Retribution,
        list = an.list_att,
      },
      bless = {
        current = bn.Wisdom,
        no_combat = bn.Wisdom,
        list = bn.list_all,
      },
    },
    NORM = {
      name = "NORM",
      type = pal.stt.damage,
      hotkey = 5,
      color = cs.color.green,
      use_slot = cs.slot.one_hand_shield,
      aura = {
        current = an.Retribution,
        list = an.list_att,
      },
      bless = {
        current = bn.Might,
        no_combat = bn.Wisdom,
        list = bn.list_all,
      },
    },
    HEAL = {
      name = pal.stn.HEAL,
      type = pal.stt.def,
      hotkey = 12 * 5 + 2,
      color = cs.color.yellow,

      aura = {
        current = an.Concentration,
        list = { an.Concentration },
      },
      bless = {
        current = bn.Light,
        list = bn.list_all,
      },
    },
  },

  state_holder = {
    cur_state = 1,
  }
}

cs_states_dynamic_config = default_states_config

pal.reset_dynamic_config = function()
  cs_states_dynamic_config = default_states_config
end

pal.get_state_holder_config = function()
  return cs_states_dynamic_config.state_holder
end

pal.get_state_config = function(id)
  return cs_states_dynamic_config.states[id]
end

pal.get_state_list = function()
  return cs.dict_keys_to_list(cs_states_dynamic_config.states, "string")
end

pal.config = {}

pal.config.init = function()
  -- test
  pal.reset_dynamic_config()
end

