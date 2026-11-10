local mod = game.mod_runtime[game.current_mod]

local MILITIA = {
  "nc_rebel_rifleman",
  "nc_rebel_smg",
  "nc_rebel_shotgunner",
  "nc_rebel_heavy",
}

local SANITIZERS = {
  "nc_sanitizer",
  "nc_sanitizer_heavy",
  "nc_sanitizer_marksman",
}

local FACTION_IDS = {
  nc_rebels = true,
  nc_biker_gang = true,
  nc_cyborgs = true,
  nc_mutated_scientists = true,
  nc_sanitizers = true,
  nc_flesh_cult = true,
  nc_tunnel_rats = true,
}

local FACTION_MONSTERS = {
  mon_mech_recon = true,
}

local CLEAN_RADIUS_OMT = 1
local SPARE_MAGAZINES = 3

local SPAWN_RATES = {
  military = 90,
  microlab = 85,
  augmentation_clinic = 80,
  mine = 70,
  hospital = 60,
  subway_station = 25,
}

local SNIPER_TOWERS = {
  { id = "mil_base_1b1", x = 7, y = 9 },
  { id = "mil_base_4b1", x = 3, y = 3 },
  { id = "mil_base_8b1", x = 16, y = 8 },
  { id = "mil_base_8g1", x = 16, y = 16 },
  { id = "mil_base_1k1", x = 7, y = 20 },
  { id = "mil_base_4k1", x = 20, y = 20 },
  { id = "mil_base_8k1", x = 16, y = 16 },
}

local MILITIA_ZONES = {
  { id = "mil_base_2d", count = 2 },
  { id = "mil_base_3d", count = 2 },
  { id = "mil_base_2e", count = 2 },
  { id = "mil_base_3e", count = 2 },
  { id = "mil_base_5c", count = 2 },
  { id = "mil_base_6c", count = 2 },
  { id = "mil_base_7c", count = 2 },
  { id = "mil_base_2f", count = 2 },
  { id = "mil_base_3f", count = 2 },
  { id = "mil_base_2g", count = 2 },
  { id = "mil_base_3g", count = 2 },
  { id = "mil_base_3h", count = 2 },
  { id = "mil_base_5e", count = 2 },
  { id = "mil_base_6e", count = 2 },
  { id = "mil_base_7e", count = 2 },
  { id = "mil_base_8e", count = 1 },
  { id = "mil_base_7f", count = 1 },
  { id = "mil_base_5h", count = 1 },
  { id = "mil_base_5i", count = 1 },
  { id = "mil_base_6i", count = 1 },
  { id = "mil_base_8i", count = 1 },
  { id = "mil_base_7i", count = 1 },
  { id = "mil_base_5a", count = 1 },
  { id = "mil_base_6a", count = 1 },
  { id = "mil_base_7a", count = 1 },
}

local function is_military_base(omt)
  return overmapbuffer.check_ot("mil_base", OtMatchType.PREFIX, omt)
    and not overmapbuffer.check_ot("mil_base_minefield", OtMatchType.CONTAINS, omt)
end

local function matches(id, omt)
  return overmapbuffer.check_ot(id, OtMatchType.CONTAINS, omt)
end

local function abs_to_bub(omt, p)
  local abs_pos = omt:project_combine(p)
  return gapi.get_map():abs_to_bub(abs_pos)
end

local function creature_omt(creature)
  local map = gapi.get_map()
  if not map or not creature then return nil end
  return map:bub_to_abs(creature:get_pos_ms()):to_omt()
end

local function omt_key(omt)
  return string.format("%d,%d,%d", omt.x, omt.y, omt.z)
end

local function pending_cleanups()
  local storage = game.mod_storage[game.current_mod]
  storage.pending_faction_cleanups = storage.pending_faction_cleanups or {}
  return storage.pending_faction_cleanups
end

local function completed_cleanups()
  local storage = game.mod_storage[game.current_mod]
  storage.completed_faction_cleanups = storage.completed_faction_cleanups or {}
  return storage.completed_faction_cleanups
end

local function queue_cleanup(omt)
  local key = omt_key(omt)
  if completed_cleanups()[key] then return end
  pending_cleanups()[key] = { x = omt.x, y = omt.y, z = omt.z }
end

local function is_pending_cleanup_area(omt)
  for _, center in pairs(pending_cleanups()) do
    local distance = math.max(math.abs(omt.x - center.x), math.abs(omt.y - center.y))
    if omt.z == center.z and distance <= CLEAN_RADIUS_OMT then return true end
  end
  return false
end

local function is_faction_npc(npc)
  return npc and not npc:is_dead() and FACTION_IDS[npc:get_faction_id():str()] == true
end

local function has_faction_npc_near(omt)
  local npcs = gapi.get_npcs_near_omt({
    center = omt,
    radius = CLEAN_RADIUS_OMT,
    ignore_z = false,
  }) or {}
  for _, npc in ipairs(npcs) do
    if is_faction_npc(npc) then return true end
  end
  return false
end

local function clean_monsters_near(omt)
  local monsters = gapi.get_monsters_near_omt({
    center = omt,
    radius = CLEAN_RADIUS_OMT,
    ignore_z = false,
  }) or {}
  for _, monster in ipairs(monsters) do
    if not monster:is_dead() and not FACTION_MONSTERS[monster:get_type():str()] then
      monster:erase()
    end
  end
end

local function queue_if_faction_present(omt)
  if has_faction_npc_near(omt) then queue_cleanup(omt) end
end

local function clear_monsters(map, omt)
  local map_size = map:get_map_size()
  for x = 0, map_size - 1 do
    for y = 0, map_size - 1 do
      local creature = gapi.get_creature_at(abs_to_bub(omt, PointOmtMs.new(x, y)), true)
      if creature and creature:is_monster() then creature:erase() end
    end
  end
end

local function is_free_tile(map, omt, p)
  local ter_id = map:get_ter_at(p)
  if ter_id:obj():get_movecost() <= 0 then return false end
  return gapi.get_creature_at(abs_to_bub(omt, p), true) == nil
end

local function find_free_tile(map, omt, cx, cy, radius)
  for r = 0, radius do
    for dx = -r, r do
      for dy = -r, r do
        if math.max(math.abs(dx), math.abs(dy)) == r then
          local x, y = cx + dx, cy + dy
          if x >= 0 and x < 24 and y >= 0 and y < 24 then
            local p = PointOmtMs.new(x, y)
            if is_free_tile(map, omt, p) then return p end
          end
        end
      end
    end
  end
  return nil
end

local function spawn_npc(map, omt, cx, cy, template, radius)
  local p = find_free_tile(map, omt, cx, cy, radius or 5)
  if p then return map:place_npc(p, template) end
  return nil
end

local function spawn_random_militia(map, omt, cx, cy)
  return spawn_npc(map, omt, cx, cy, MILITIA[gapi.rng(1, #MILITIA)])
end

local function spawn_many(map, omt, template, count)
  local positions = {
    { 4, 4 }, { 12, 4 }, { 20, 4 },
    { 4, 12 }, { 12, 12 }, { 20, 12 },
    { 4, 20 }, { 12, 20 }, { 20, 20 },
    { 8, 8 }, { 16, 8 }, { 16, 16 },
  }
  for i = 1, count do
    local p = positions[i]
    spawn_npc(map, omt, p[1], p[2], template, 7)
  end
end

local function spawn_sanitizer_group(map, omt, count)
  local positions = { { 8, 8 }, { 16, 8 }, { 8, 16 }, { 16, 16 } }
  for i = 1, count do
    local p = positions[i]
    spawn_npc(map, omt, p[1], p[2], SANITIZERS[gapi.rng(1, #SANITIZERS)], 7)
  end
end

local function is_hospital(omt)
  return omt.z == 0 and overmapbuffer.check_ot("hospital", OtMatchType.PREFIX, omt)
end

local function is_mine(omt)
  return omt.z < 0 and overmapbuffer.check_ot("mine", OtMatchType.PREFIX, omt)
end

local function is_gas_station(omt)
  return omt.z == 0 and overmapbuffer.check_ot("s_gas", OtMatchType.PREFIX, omt)
end

local function is_augmentation_clinic(omt)
  return overmapbuffer.check_ot("afs_augmentation_clinic", OtMatchType.PREFIX, omt)
end

local function is_microlab(omt)
  return omt.z < 0 and overmapbuffer.check_ot("microlab", OtMatchType.PREFIX, omt)
end

local function is_subway_station(omt)
  return (omt.z == 0 and overmapbuffer.check_ot("sub_station", OtMatchType.PREFIX, omt))
    or overmapbuffer.check_ot("sewer_sub_station", OtMatchType.PREFIX, omt)
    or overmapbuffer.check_ot("underground_sub_station", OtMatchType.PREFIX, omt)
end

mod.on_mapgen_postprocess = function(params)
  local map = params.map
  local omt = params.omt
  if not map or not omt then return end

  if is_gas_station(omt) then
    queue_if_faction_present(omt)
    return
  end

  if is_augmentation_clinic(omt) then
    if omt.z > 2 then return end
    if gapi.rng(1, 100) > SPAWN_RATES.augmentation_clinic then return end
    clear_monsters(map, omt)
    local count = 4
    if omt.z == 2 then
      count = 2
    end
    spawn_many(map, omt, "nc_cyborg", count)
    queue_cleanup(omt)
    return
  end

  if is_microlab(omt) then
    if gapi.rng(1, 100) <= SPAWN_RATES.microlab then
      clear_monsters(map, omt)
      spawn_many(map, omt, "nc_mutated_doc", 4)
      queue_if_faction_present(omt)
    end
    return
  end

  if is_hospital(omt) then
    if gapi.rng(1, 100) <= SPAWN_RATES.hospital then
      clear_monsters(map, omt)
      spawn_sanitizer_group(map, omt, gapi.rng(2, 4))
      queue_if_faction_present(omt)
    end
    return
  end

  if is_mine(omt) then
    if gapi.rng(1, 100) <= SPAWN_RATES.mine then
      clear_monsters(map, omt)
      spawn_many(map, omt, "nc_cultist", gapi.rng(1, 3))
      queue_if_faction_present(omt)
    end
    return
  end

  if is_subway_station(omt) then
    if gapi.rng(1, 100) <= SPAWN_RATES.subway_station then
      clear_monsters(map, omt)
      spawn_many(map, omt, "nc_tunnel_rat", gapi.rng(3, 12))
      queue_if_faction_present(omt)
    end
    return
  end

  if not is_military_base(omt) then return end
  if gapi.rng(1, 100) > SPAWN_RATES.military then return end

  clear_monsters(map, omt)

  if omt.z == 0 then
    if matches("mil_base_5g", omt) then
      spawn_npc(map, omt, 12, 12, "nc_rebel_boss", 6)
      spawn_random_militia(map, omt, 8, 8)
      spawn_random_militia(map, omt, 16, 16)
    elseif matches("mil_base_6f", omt) then
      local p = find_free_tile(map, omt, 12, 12, 8)
      if p then
        local mech = gapi.place_monster_at(
          MonsterTypeId.new("mon_mech_recon"),
          abs_to_bub(omt, p)
        )
        if mech then mech:set_attitude(Attitude.Hostile) end
      end
      spawn_npc(map, omt, 8, 8, "nc_rebel_heavy", 5)
    else
      local count = 1
      for _, zone in ipairs(MILITIA_ZONES) do
        if matches(zone.id, omt) then
          count = zone.count
          break
        end
      end
      local positions = { { 8, 8 }, { 16, 8 }, { 8, 16 }, { 16, 16 } }
      for i = 1, count do
        local p = positions[i]
        spawn_random_militia(map, omt, p[1], p[2])
      end
    end
  elseif omt.z == 1 then
    for _, tower in ipairs(SNIPER_TOWERS) do
      if matches(tower.id, omt) then
        spawn_npc(map, omt, tower.x, tower.y, "nc_rebel_sniper", 2)
        break
      end
    end
  end

  queue_if_faction_present(omt)
end

local function ensure_gun_magazines(npc)
  for _, weapon in ipairs(npc:wielded_items() or {}) do
    if weapon:is_gun() then
      local current = weapon:current_magazine()
      if current then
        local magazine_type = current:get_type()
        local magazine_data = magazine_type:obj().slot_magazine
        if magazine_data and magazine_data.default_ammo:str() ~= "null" then
          local ammo_type = magazine_data.default_ammo
          current:ammo_set(ammo_type, current:ammo_capacity())

          local existing = npc:get_items_if({ type = magazine_type }) or {}
          for _, magazine in ipairs(existing) do
            magazine:ammo_set(ammo_type, magazine:ammo_capacity())
          end
          for _ = #existing + 1, SPARE_MAGAZINES do
            local magazine = gapi.create_item(magazine_type, -1)
            magazine:ammo_set(ammo_type, magazine:ammo_capacity())
            npc:add_item(magazine)
          end
        end
      else
        local ammo_type = weapon:ammo_current()
        if ammo_type and ammo_type:str() ~= "null" then
          local capacity = weapon:ammo_capacity()
          weapon:ammo_set(ammo_type, capacity)
          if capacity > 0 then npc:create_item(ammo_type, capacity * SPARE_MAGAZINES) end
        end
      end
      return
    end
  end
end

local function prepare_faction_npc(npc)
  if not is_faction_npc(npc) then return end
  ensure_gun_magazines(npc)
  local omt = creature_omt(npc)
  if omt then queue_cleanup(omt) end
end

mod.on_npc_spawn = function(params)
  prepare_faction_npc(params.npc)
end

mod.on_npc_loaded = function(params)
  prepare_faction_npc(params.npc)
end

mod.on_monster_loaded = function(params)
  local monster = params.monster
  if not monster or monster:is_dead() then return end
  if FACTION_MONSTERS[monster:get_type():str()] then return end

  local omt = creature_omt(monster)
  if omt and is_pending_cleanup_area(omt) then monster:erase() end
end

mod.process_pending_cleanups = function()
  local pending = pending_cleanups()
  local completed = completed_cleanups()
  for key, center in pairs(pending) do
    local omt = TripointAbsOmt.new(center.x, center.y, center.z)
    clean_monsters_near(omt)
    pending[key] = nil
    completed[key] = true
  end
  return true
end
