
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






-- ATTACKS

local judgement_any = function(...)
  for _, seal in ipairs(arg) do
    if seal:judgement_it() then
      return true
    end
  end
end

local build_cast_list = function(...)
  local cast_list = arg

  local target = UnitCreatureType("target")
  if target == "Demon" or target == "Undead" then
    table.insert(cast_list, 1, cast.Exorcism)
  end
  return unpack(cast_list)
end

---@param seal_list pal.Seal[]
local seal_action = function(state, seal_list)
  if not cs.check_target(cs.t_close_10) then
    -- the target is far away
    return
  end

  if not seal_list[1]:is_reseal_available() then
    -- seal can not be casted with current situation, just cast other spells
    cs.cast(cast.HolyStrike, cast.CrusaderStrike)
    return
  end

  if judgement_any(pal.Seal.seal_Righteousness, seal_list[2], seal_list[3]) then
    -- wait another seal to judgement on the target
    return
  end

  for _, seal in pairs(seal_list) do
    if not seal:is_judgement_available() then
      -- it means the target already has other seal debuff. Reseal and cast other spells only
      if state.id == state_RUSH then
        cs.cast(cast.CrusaderStrike)
        return
      end

      seal_list[1]:reseal_and_cast(cast.HolyStrike, cast.CrusaderStrike)
      return
    end
  end

  -- the target has no other seal debuff. Lets reseal and judgement it.
  seal_list[1]:reseal_and_cast(cast.Judgement)
end


pal.actions = {}
pal.actions.right = function(state)
  if not cs.check_target(cs.t_close_30) then return end

  cs.cast(cast.HolyStrike)

  if state.id ~= state_RUSH then
    if judgement_any(pal.Seal.seal_Light, pal.Seal.seal_Wisdom, pal.Seal.seal_Justice) then
      return
    end
  end

  pal.Seal.seal_Righteousness:reseal_and_cast(build_cast_list(cast.Judgement, cast.CrusaderStrike ))
end

pal.actions.crusader = function(state)
  if not cs.check_target(cs.t_close_10) then return end

  if judgement_any(pal.Seal.seal_Light, pal.Seal.seal_Wisdom, pal.Seal.seal_Justice, pal.Seal.seal_Righteousness) then
    return
  end

  pal.Seal.seal_Crusader:reseal_and_cast(cast.HolyStrike, cast.CrusaderStrike)
end

pal.actions.wisdom = function(state)
  seal_action(state, {pal.Seal.seal_Wisdom, pal.Seal.seal_Light, pal.Seal.seal_Justice})
end

pal.actions.light = function(state)
  seal_action(state, {pal.Seal.seal_Light, pal.Seal.seal_Wisdom, pal.Seal.seal_Justice})
end

pal.actions.justice = function(state)
  seal_action(state, {pal.Seal.seal_Justice, pal.Seal.seal_Light, pal.Seal.seal_Wisdom})
end




