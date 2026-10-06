local Components = require("src.games.bomberman.components")

-- Aplica Velocity em Position, escalado por dt e pela velocidade propria da
-- entidade, com colisao contra paredes (entidades Solid, ver
-- bomberman_module.lua). `World:query` aqui e interseccao de verdade
-- (Position E Velocity) -- paredes nao tem Velocity, entao nem aparecem
-- nesta query; so quem se move e testado contra elas.
--
-- Resolucao por eixo separado (tenta mover em x, reverte se colidir;
-- repete em y): simples e evita que a entidade "grude" na parede ao
-- encostar na diagonal. O resource "spatial" (src/ecs/spatial/grid.lua) e
-- opcional -- se o jogo nao setar um, ninguem colide com nada.

---@param aabb { x: number, y: number, w: number, h: number }
---@param other { x: number, y: number, w: number, h: number }
local function overlaps(aabb, other)
	return aabb.x < other.x + other.w
		and aabb.x + aabb.w > other.x
		and aabb.y < other.y + other.h
		and aabb.y + aabb.h > other.y
end

---@param spatial table  -- SpatialGrid, ver src/ecs/spatial/grid.lua
---@param self_id any  -- excluido do teste -- uma entidade nao colide consigo mesma
---@param x number
---@param y number
---@param size number
local function blocked_at(spatial, self_id, x, y, size)
	if not spatial then
		return false
	end

	local aabb = { x = x - size / 2, y = y - size / 2, w = size, h = size }
	for id in pairs(spatial:query(aabb)) do
		if id ~= self_id then
			local other_aabb = spatial.aabbs[id]
			if other_aabb and overlaps(aabb, other_aabb) then
				return true
			end
		end
	end
	return false
end

---@param world table
return function(world, dt)
	local spatial = world:get_resource("spatial")

	for entity, position, velocity in world:query(Components.Position, Components.Velocity) do
		local speed = position.speed or 0
		local size = position.size or 28

		local new_x = position.x + velocity.dx * speed * dt
		if not blocked_at(spatial, entity.index, new_x, position.y, size) then
			position.x = new_x
		end

		local new_y = position.y + velocity.dy * speed * dt
		if not blocked_at(spatial, entity.index, position.x, new_y, size) then
			position.y = new_y
		end
	end
end
