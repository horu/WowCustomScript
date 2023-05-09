

local cs = cs_common
local pal = cs.pal















local function unit_dump_scan(name)
  local units = pfUI.api.GetScanDb()
  local m = units["mobs"][name]
  local p = units["players"][name]
  local m_ut = cs.time_to_str(m and m.updatetime or 0)
  local p_ut = cs.time_to_str(p and p.updatetime or 0)
  cs.print("    M(" .. m_ut .. "):" .. ToString(m, 2, 10, 1))
  cs.print("    P(" .. p_ut .. "):" .. ToString(p, 2, 10, 1))
end








-- NAMEPLATES

PLAYER_UNIT_TYPE = "players"
NPC_UNIT_TYPE = "mobs"

local function GetReactionAndPlayerType(plate)
  local red, green, blue = plate.original.healthbar:GetStatusBarColor()

  if red > .9 and green < .2 and blue < .2 then
    return "ENEMY", nil
  elseif red > .9 and green > .9 and blue < .2 then
    return "NEUTRAL", "mobs"
  elseif red < .2 and green < .2 and blue > 0.9 then
    return "FRIENDLY", "players"
  elseif red < .2 and green > .9 and blue < .2 then
    return "FRIENDLY", "mobs"
  end
  return "ENEMY", nil
end

local function GetUnitType(reaction, player)
  if player == PLAYER_UNIT_TYPE then
    if reaction == "NEUTRAL" then
      return nil
    end
    return reaction .. "_PLAYER"
  else
    return reaction .. "_NPC"
  end
end

local function np_to_short(plate)
  local r, p = GetReactionAndPlayerType(plate)
  local cache_player = plate.cache and plate.cache.player
  return {
    CACHE = plate.cache,
    CACHE_P = cache_player,
  }
end

local function unit_dump_np(name)
  -- pfUI.api.GetNPList()

  local np_list = pfUI.api.GetNPList()
  local count = 0
  for frame in pairs(np_list) do
    local plate = frame.nameplate
    local np_name = plate.original.name:GetText()
    if np_name == name then
      cs.print("    NP: " .. ToString(np_to_short(plate), 3, 20, nil))
    end
    count = count + 1
  end
  cs.print("NP COUNT: " .. count)
end

local function unit_dump(name)
  cs.print("  " .. name .. ":")
  unit_dump_scan(name)
  unit_dump_np(name)
end

local dump_table = function(name, tbl)
  cs.print(name)
  for name, data in pairs(tbl) do
    cs.print(name..": "..cs.to_string_best_d(data))
  end
end

cs_debug_list = {}

local function all_dump()
  --dump_table("cs_map_data", cs_map_data)
  dump_table("cs_players_bless_dict", cs_players_bless_dict)

  local bless_list = pal.bn.get_available()
  for _, id in pairs(bless_list) do
    local buff = pal.bless.get_buff(id)
    dump_table(id, buff)
  end

  cs.debug(cs.get_party_hp_sum())
  cs.debug(cs.st_map_checker)
  cs.debug(GetMapInfo())
  cs.debug("---------------------------")
  for npcinfo, names in pairs(cs_debug_list) do
    local count = 0
    for _,_ in pairs(names) do count = count + 1 end
    cs.debug(string.format("%s: %d", npcinfo, count))
  end
end






-- PUBLIC

function cs_dump_unit()
  local ts = GetTime()
  local cur_time = cs.time_to_str(ts)
  cs.print("----- " .. cur_time.." "..ts)

  if cs.check_target(cs.t.exists) then
    local buffs = cs.get_buff_list(cs.u.target)
    local debuffs = cs.get_debuff_list(cs.u.target)
    local casts = cs.get_cast_info(cs.u.target)
    for t, list in pairs({ buffs = buffs, debuffs = debuffs, casts = casts }) do
      cs.print(t .. ":")
      for _, buff in pairs(list) do
        cs.debug(buff)
      end
    end

    --local name = UnitName("target")
    --unit_dump(name)
  else
    all_dump()
  end

end