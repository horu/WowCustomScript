
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
  default_state = {
    aura = {
      list = an.list_att,
    },
    bless = {
      list = bn.list_all,
    },
  },
  states = {
    RUSH = {
      name = pal.stn.RUSH,
      type = pal.stt.damage,
      hotkey = 1,
      color = cs.color.red_1,

      use_slot = cs.slot.two_hand,

      aura = {
        current = an.Retribution,
      },
      bless = {
        current = bn.Might,
        no_combat = bn.Wisdom,
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
      },
      bless = {
        current = bn.Sanctuary,
        no_combat = bn.Wisdom,
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
      },
      bless = {
        current = bn.Sanctuary,
        no_combat = bn.Wisdom,
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
      },
      bless = {
        current = bn.Wisdom,
        no_combat = bn.Wisdom,
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
      },
      bless = {
        current = bn.Might,
        no_combat = bn.Wisdom,
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
      },
    },
  },

  state_holder = {
    cur_state = 1,
  }
}

cs_states_dynamic_config = default_states_config

pal.config = {}

pal.config.get = function()
  return cs_states_dynamic_config
end

pal.config.reset = function()
  cs_states_dynamic_config = default_states_config
end

pal.config.get_state_holder = function()
  return pal.config.get().state_holder
end

pal.config.get_state = function(id)
  return pal.config.get().states[id]
end

pal.config.get_state_list = function()
  return cs.dict_keys_to_list(pal.config.get().states, "string")
end


pal.config.init = function()
  -- test
  pal.config.reset()
end

