local cs = cs_common
cs.hunt = {}
local hunt = cs.hunt

-- SPell
hunt.sp = {}

-- BuffSPell
hunt.bsp = {}

hunt.common = {}

hunt.common.init = function()
  hunt.sp.AutoShot = cs.Spell:create("Auto Shot")

  hunt.sp.ArcaneShot = cs.Spell:create("Arcane Shot")
  hunt.sp.Mark = cs.Spell:create("Hunter's Mark", function(spell)
    return not cs.has_debuffs(cs.u.target, "Ability_Hunter_SniperShot") and
            not cs.compare_unit_hp_rate(0.25, cs.u.target)
  end)
  hunt.sp.SerpentSting = cs.Spell:create("Serpent Sting", function(spell)
    return not cs.has_debuffs(cs.u.target, "Ability_Hunter_Quickshot") and
            not cs.compare_unit_hp_rate(0.25, cs.u.target)
  end)

  hunt.bsp.HawkAspect = cs.Buff:create("Aspect of the Hawk")

  -- Pet
  hunt.sp.Growl = cs.Spell:create("Growl")
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

cs_hunt_shot = function()
  hunt.bsp.HawkAspect:rebuff()

  hunt.auto_shot()
  PetAttack()
  hunt.sp.Growl:cast()
  if hunt.sp.Mark:cast() then return end
  if hunt.sp.SerpentSting:cast() then return end
  if hunt.sp.ArcaneShot:cast() then return end
end