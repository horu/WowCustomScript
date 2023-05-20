local cs = cs_common
local dru = cs.dru


dru.bear = {}

---@class dru.bear.Form
dru.bear.Form = cs.class()
dru.bear.Form.name = "Bear Form"
function dru.bear.Form:build()
  self.buff = cs.Buff:create(self.name)
end

function dru.bear.Form:set()
  self.buff:rebuff()
end

function dru.bear.Form:cancel()
  self.buff:cancel()
end

function dru.bear.Form:attack()
  cs.auto_attack()

  if not cs.check_target(cs.t.attackable) then
    return
  end

  if dru.sp.Enrage:cast() then return end

  dru.sp.Maul:cast()
end

function dru.bear.Form:splash()
  cs.auto_attack()

  if dru.sp.DemoralizingRoar:cast() then return end
  dru.sp.Swipe:cast()
end



dru.form = {}

dru.form.bear = "bear"
dru.form.cat = "cat"
dru.form.humanoid = "humanoid"

dru.form.Handler = cs.class()
function dru.form.Handler:build()
  self.forms = {}
  self.forms[dru.form.bear] = dru.bear.Form:create()
  self.forms[dru.form.cat] = dru.cat.Form:create()
end

function dru.form.Handler:set(form_name)
  if form_name == dru.form.humanoid then
    for _, it in pairs(self.forms) do
      it:cancel()
    end
    return
  end

  local form = self.forms[form_name]
  form:set()
  return form
end


function cs.party.Player:rebuff()
  if not self.data.dru_mark then
    self.data.dru_mark = dru.buff.create_mark()
  end

  if self.data.dru_mark:rebuff(self.unit) then
    dru.form.handler:set(dru.form.humanoid)
  end
end



dru.form.init = function()
  dru.form.handler = dru.form.Handler:create()
end




-- PUBLIC

cs_dru_form_action = function(form_name, action_name)
  local form = dru.form.handler:set(form_name)
  local action = form[action_name]

  return action(form)
end

cs_dru_cast = function(form_name, spell_name)
  if form_name ~= dru.form.humanoid then
    cs.auto_attack()
  end

  dru.form.handler:set(form_name)

  dru.sp[spell_name]:cast()
end

cs_dru_range_attack =function()
  cs.auto_attack()

  dru.form.handler:set(dru.form.humanoid)

  if cs.check_target(cs.t.attackable) then
    if dru.sp.FaerieFire:cast() then return end
    if dru.sp.InsectSwarm:cast() then return end
    if dru.sp.Wrath:cast() then return end
    if dru.sp.Moonfire:cast() then return end
  end

  dru.rebuff()

  cs.party.rebuff()
end

cs_dru_RJ = function()
  dru.form.handler:set(dru.form.humanoid)

  if cs.check_target(cs.t.friend) then
    local buff = cs.Buff:create(dru.sn.Rejuvenation)
    buff:rebuff(cs.u.target)
    return
  end

  dru.sp.RJ:rebuff()
end

cs_dru_helpful = function(name)
  dru.form.handler:set(dru.form.humanoid)
  dru.sp[name]:cast_helpful()
end
