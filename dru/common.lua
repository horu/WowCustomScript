local cs = cs_common
cs.dru = {}
local dru = cs.dru

dru.common = {}

dru.sn = {}

dru.sn.Rejuvenation = "Rejuvenation"
dru.sn.HealingTouch = "Healing Touch"

dru.buff = {}
dru.buff.create_mark = function()
  return cs.Buff:create("Mark of the Wild", 28 * 60)
end

-- SPell
dru.sp = {}

-- BuffSPell
dru.bsp = {}


local check_target_hp = function(rate)
  return not cs.check_target_hp(rate * cs.get_party_hp_sum()) or not cs.compare_unit_hp_rate(0.95, cs.u.target)
end


dru.common.init = function()
  -- Human
  dru.sp.HT = cs.Spell:create(dru.sn.HealingTouch)
  dru.sp.Regrowth = cs.Spell:create("Regrowth")
  dru.sp.RemoveCurse = cs.Spell:create("Remove Curse")

  dru.sp.Wrath = cs.Spell:create("Wrath", function(spell)
    return not cs.services.speed_checker:is_moving() and cs.has_debuffs(cs.u.target, "Spell_Nature_StarFall")
  end)
  dru.sp.Hibernate = cs.Spell:create("Hibernate")
  dru.sp.EntanglingRoots = cs.Spell:create("Entangling Roots")
  dru.sp.Moonfire = cs.Spell:create("Moonfire", function(spell)
    --return not cs.has_debuffs(cs.u.target, "Spell_Nature_StarFall")
    return true
  end)
  dru.sp.FaerieFire = cs.Spell:create("Faerie Fire", function(spell)
    return not cs.has_debuffs(cs.u.target, "Spell_Nature_FaerieFire") and check_target_hp(0.3)
  end)
  dru.sp.InsectSwarm = cs.Spell:create("Insect Swarm", function(spell)
    return not cs.has_debuffs(cs.u.target, "Spell_Nature_InsectSwarm") and check_target_hp(0.3)
  end)

  dru.sp.RJ = cs.Buff:create(dru.sn.Rejuvenation)
  dru.sp.MarkWild = dru.buff.create_mark()
  dru.sp.Thorns = cs.Buff:create("Thorns", 9 * 60)

  -- Bear
  dru.sp.Maul = cs.Spell:create("Maul")
  dru.sp.Growl = cs.Spell:create("Growl")
  dru.sp.Enrage = cs.Spell:create("Enrage", function()
    return not cs.compare_unit_hp_rate(0.8) and check_target_hp(0.3)
  end)
  dru.sp.DemoralizingRoar = cs.Spell:create("Demoralizing Roar", function()
    return not cs.has_debuffs(cs.u.target, "Ability_Druid_DemoralizingRoar")
  end)
  dru.sp.Swipe = cs.Spell:create("Swipe")
  dru.sp.Bash = cs.Spell:create("Bash")

  -- Cat
  dru.sp.Claw = cs.Spell:create("Claw")
  dru.sp.Shred = cs.Spell:create("Shred")
  dru.sp.Rip = cs.Spell:create("Rip", function(spell)
    return not cs.has_debuffs(cs.u.target, "Ability_GhoulFrenzy")
  end)
  dru.sp.Rake = cs.Spell:create("Rake", function(spell)
    return not cs.has_debuffs(cs.u.target, "TODO") and check_target_hp(0.3)
  end)
  dru.sp.Prowl = cs.Buff:create("Prowl")
  dru.sp.TigerFury = cs.Buff:create("Tiger's Fury", nil, function()
    return cs.check_target(cs.t.close_10)
  end)
end

