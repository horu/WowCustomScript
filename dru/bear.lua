local cs = cs_common
local dru = cs.dru



dru.bear = {}

---@class dru.bear.Form
dru.bear.Form = cs.class(dru.form.Base)
dru.bear.Form.name = "Bear Form"

function dru.bear.Form:attack()
  cs.auto_attack()

  if not cs.check_target(cs.t.attackable) then
    return
  end

  if dru.sp.Enrage:cast() then return end

  dru.sp.Maul:cast()
end

function dru.bear.Form:splash()
  if not cs.auto_attack() then return end

  if dru.sp.FaerieFire_Feral:cast() then return end
  if dru.sp.DemoralizingRoar:cast() then return end
  dru.sp.Swipe:cast()
end