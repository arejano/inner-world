local InputMap = require("src.core.input_map")
local Components = require("src.games.bomberman.components")

-- Traduz teclas (camada "game" de src/core/input_map.lua) em Velocity pra
-- toda entidade marcada Controllable. Nao mexe em love.graphics -- sistemas
-- de logica nao desenham.
---@param world table
return function(world, dt)
	for _entity, velocity in world:query(Components.Velocity, Components.Controllable) do
		local dx, dy = 0, 0

		if InputMap.down("game", "move_right") then
			dx = dx + 1
		end
		if InputMap.down("game", "move_left") then
			dx = dx - 1
		end
		if InputMap.down("game", "move_down") then
			dy = dy + 1
		end
		if InputMap.down("game", "move_up") then
			dy = dy - 1
		end

		if dx ~= 0 and dy ~= 0 then
			local inv_len = 0.7071067811865476 -- 1/sqrt(2): normaliza a diagonal
			dx, dy = dx * inv_len, dy * inv_len
		end

		velocity.dx, velocity.dy = dx, dy
	end
end
