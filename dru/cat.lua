local cs = cs_common
local dru = cs.dru

dru.cat = {}


---@class dru.cat.Rip
dru.cat.Rip = cs.class()
function dru.cat.Rip:build()
  ---@type cs.Spell
  self.spell = dru.sp.Rip

  self.dam_by_combo = {}
  for _, line in self.spell:get_tooltip().text do
    cs.print(line)
  end
end


---@class dru.cat.Form
dru.cat.Form = cs.class()
dru.cat.Form.name = "Cat Form"
function dru.cat.Form:build()
  self.buff = cs.Buff:create(self.name)

  self.rip = dru.cat.Rip:create()
end

function dru.cat.Form:set()
  self.buff:rebuff()
end

function dru.cat.Form:cancel()
  self.buff:cancel()
end

function dru.cat.Form:attack()

end