local Components = require("src.games.bomberman.components")

-- Unico sistema que toca love.graphics.* -- sistemas de input/logica nunca
-- desenham (ver input_system.lua/movement_system.lua). Le o resource
-- "viewport" (setado por BombermanModule:update a partir da regiao "main"
-- do UIManager) pra saber onde, na tela, a origem do mundo do jogo cai.
---@param world table
return function(world, _dt)
	local viewport = world:get_resource("viewport") or { x = 0, y = 0 }

	for _entity, position, sprite in world:query(Components.Position, Components.Sprite) do
		local size = sprite.size or 24
		love.graphics.setColor(unpack(sprite.color))
		love.graphics.rectangle(
			"fill",
			viewport.x + position.x - size / 2,
			viewport.y + position.y - size / 2,
			size,
			size
		)
	end

	love.graphics.setColor(1, 1, 1, 1)
end
