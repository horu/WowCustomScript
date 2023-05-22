local cs = cs_common
local dru = cs.dru



dru.form = {}

---@class dru.form.Base
dru.form.Base = cs.class()
function dru.form.Base:build()
  self.buff = cs.Buff:create(self.name)
end

function dru.form.Base:set()
  self.buff:rebuff()
end

function dru.form.Base:cancel()
  self.buff:cancel()
end

function dru.form.Base:check_exists()
  return self.buff:check_exists()
end



dru.travel = {}

---@class dru.travel.Form
dru.travel.Form = cs.class(dru.form.Base)
dru.travel.Form.name = "Travel Form"



dru.aquatic = {}

---@class dru.aquatic.Form
dru.aquatic.Form = cs.class(dru.form.Base)
dru.aquatic.Form.name = "Aquatic Form"