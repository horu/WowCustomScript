local cs = cs_common
cs.hunt = {}
local hunt = cs.hunt

-- SPellName
hunt.spn = {}

hunt.spn.Growl = "Growl"

-- SPell
hunt.sp = {}

-- BuffSPell
hunt.bsp = {}


function hunt.check_melee()
  return cs.check_target(cs.t.close_9)
end

hunt.common = {}

hunt.common.init = function()
  -- Shot
  hunt.sp.AutoShot = cs.Spell:create("Auto Shot")
  hunt.sp.ArcaneShot = cs.Spell:create("Arcane Shot")
  hunt.sp.ConcussiveShot = cs.Spell:create("Concussive Shot")
  hunt.sp.Mark = cs.Spell:create("Hunter's Mark", function(spell)
    return not cs.has_debuffs(cs.u.target, "Ability_Hunter_SniperShot") and
            not cs.compare_unit_hp_rate(0.25, cs.u.target)
  end)
  hunt.sp.SerpentSting = cs.Spell:create("Serpent Sting", function(spell)
    return not cs.has_debuffs(cs.u.target, "Ability_Hunter_Quickshot") and
            (not cs.compare_unit_hp_rate(0.25, cs.u.target) or cs.check_target(cs.t.player))
  end)
  hunt.sp.ViperSting = cs.Spell:create("Viper Sting", function(spell)
    return not cs.has_debuffs(cs.u.target, "Ability_Hunter_AimedShot")
  end)
  hunt.sp.AimedShot = cs.Spell:create("Aimed Shot", function(spell)
    return not cs.services.speed_checker:is_moving() and not cs.check_combat()
  end)
  hunt.sp.TrueShot = cs.Spell:create("Trueshot")

  -- Melee
  hunt.sp.RaptorStrike = cs.Spell:create("Raptor Strike", function()
    return hunt.check_melee()
  end)
  hunt.sp.WingClip = cs.Spell:create("Wing Clip", function()
    return hunt.check_melee()
  end)

  -- Buff
  hunt.sp.RapidFire = cs.Spell:create("Rapid Fire", function(spell)
    return cs.check_combat(cs.c.affect) and not cs.compare_unit_hp_rate(0.9, cs.u.target)
  end)

  -- Aspect
  hunt.bsp.HawkAspect = cs.Buff:create("Aspect of the Hawk")
  hunt.bsp.MonkeyAspect = cs.Buff:create("Aspect of the Monkey")
  hunt.bsp.CheetahAspect = cs.Buff:create("Aspect of the Cheetah")
  hunt.bsp.WolfAspect = cs.Buff:create("Aspect of the Wolf")

  -- For pet
  hunt.sp.CallPet = cs.Spell:create("Call Pet")
  hunt.sp.MendPet = cs.Spell:create("Mend Pet")
  hunt.sp.RevivePet = cs.Spell:create("Revive Pet")
  hunt.sp.Intimidation = cs.Spell:create("Intimidation", function(spell)
    return not cs.compare_unit_hp_rate(0.9, cs.u.target) or
            cs.check_unit(cs.t.self, cs.u.targettarget) or
            cs.check_target(cs.t.player)
  end)

  -- Pet
  hunt.sp.FuriousHowl = cs.Spell:create("Furious Howl", function()
    return cs.check_unit(cs.t.close_10, cs.u.pet)
  end)
  hunt.sp.Growl = cs.Spell:create("Growl")
  hunt.sp.Charge = cs.Spell:create("Charge", function()
    return not cs.compare_unit_hp_rate(0.8, cs.u.target)
  end)
  hunt.sp.Dash = cs.Spell:create("Dash", function()
    return cs.check_target(cs.t.attackable) and not cs.check_combat(cs.c.affect)
  end)
end

function hunt.auto_shot()
  -- TODO
  if not cs.prepare_attack() then
    return
  end

  --if not cs.check_combat(cs.c.normal) then
  --  AttackTarget()
  --end
  return true
end

function hunt.main_attack()
  cs.prof.finder:buff()

  if not cs.check_unit(cs.t.exists, cs.u.pet) then
    hunt.sp.CallPet:cast()
  end

  hunt.auto_shot()
  PetAttack()
  hunt.sp.Charge:cast()
  hunt.sp.FuriousHowl:cast()
  -- hunt.sp.Dash:cast()
  if not cs.is_in_party() then
    hunt.sp.Growl:cast()
  end
  hunt.sp.Mark:cast()
  hunt.sp.Intimidation:cast()

  if hunt.check_melee() then
    cs.auto_attack()
    if hunt.sp.RaptorStrike:cast() then return end
  else
    hunt.sp.RapidFire:cast()
  end

  hunt.sp.AimedShot:cast()

  if cs.check_target(cs.t.player) and UnitMana(cs.u.target) > 200 then
    hunt.sp.ViperSting:cast()
  else
    hunt.sp.SerpentSting:cast()
  end

  hunt.sp.ArcaneShot:cast()
  hunt.sp.TrueShot:cast()
--  if hunt.sp.ConcussiveShot:cast() then return end
end

cs_hunt_light = function()
  hunt.bsp.CheetahAspect:rebuff()

  hunt.main_attack()
end

cs_hunt_heavy = function()
  if hunt.check_melee() then
    hunt.bsp.WolfAspect:rebuff()
  else
    hunt.bsp.HawkAspect:rebuff()
  end

  hunt.main_attack()
end

cs_hunt_daze = function()
  if hunt.sp.WingClip:cast() then return end
  if hunt.sp.ConcussiveShot:cast() then return end
end

cs_hunt_heal_pet = function()
  if cs.check_unit(cs.t.dead, cs.u.pet) then
    hunt.sp.RevivePet:cast()
  else
    hunt.sp.MendPet:cast()
  end
end