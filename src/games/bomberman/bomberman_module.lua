local World = require("src.ecs.world")
local SpatialGrid = require("src.ecs.spatial.grid")
local Components = require("src.games.bomberman.components")
local input_system = require("src.games.bomberman.systems.input_system")
local movement_system = require("src.games.bomberman.systems.movement_system")
local render_system = require("src.games.bomberman.systems.render_system")

-- GameModule minimo: uma arena em grade (paredes de borda + pilares
-- internos classicos de bomberman) com um jogador que colide contra elas
-- -- sem bombas ainda, suficiente pra provar o acoplamento
-- Editor<->Game<->ECS<->EventBus (ver docs/ARCHITECTURE.md) e o uso do
-- plugin de particionamento espacial opcional (src/ecs/spatial/grid.lua).
-- Implementa o mesmo contrato Module que o EditorModule; o ModuleRegistry
-- nao sabe (nem precisa saber) que isso e "bomberman" especificamente --
-- so chama init/update/draw/shutdown.
local BombermanModule = {
	id = "bomberman",
}

local TILE_SIZE = 40
local GRID_W, GRID_H = 18, 14 -- em tiles

---@param gx number
---@param gy number
local function tile_center(gx, gy)
	return gx * TILE_SIZE + TILE_SIZE / 2, gy * TILE_SIZE + TILE_SIZE / 2
end

---Borda da arena + pilares internos (padrao classico: solido onde ambas as
---coordenadas de tile sao pares) -- cria uma entidade Solid por parede e
---registra o AABB dela no spatial grid, usado por movement_system pra
---colisao.
function BombermanModule:_build_arena()
	local wall_count = 0

	for gx = 0, GRID_W - 1 do
		for gy = 0, GRID_H - 1 do
			local is_border = gx == 0 or gy == 0 or gx == GRID_W - 1 or gy == GRID_H - 1
			local is_pillar = gx % 2 == 0 and gy % 2 == 0

			if is_border or is_pillar then
				local x, y = tile_center(gx, gy)
				local entity = self.world:create({
					[Components.Position] = { x = x, y = y, size = TILE_SIZE },
					[Components.Sprite] = { color = { 0.35, 0.35, 0.42, 1 }, size = TILE_SIZE - 2 },
					[Components.Solid] = true,
				})

				self.spatial:insert(entity.index, {
					x = x - TILE_SIZE / 2,
					y = y - TILE_SIZE / 2,
					w = TILE_SIZE,
					h = TILE_SIZE,
				})

				wall_count = wall_count + 1
			end
		end
	end

	return wall_count
end

function BombermanModule:init(ctx)
	self.ctx = ctx
	self.world = World()
	self.spatial = SpatialGrid(TILE_SIZE)
	self.world:set_resource("spatial", self.spatial)

	self.world:add_system("input", "player_input", input_system)
	self.world:add_system("logic", "movement", movement_system)
	self.world:add_system("render", "render", render_system)

	local wall_count = self:_build_arena()

	local player_x, player_y = tile_center(1, 1) -- tile (1,1): nunca e pilar (ambos impares)
	self.world:create({
		[Components.Position] = { x = player_x, y = player_y, speed = 220, size = 28 },
		[Components.Velocity] = { dx = 0, dy = 0 },
		[Components.Sprite] = { color = { 0.9, 0.3, 0.3, 1 }, size = 28 },
		[Components.Controllable] = true,
	})

	local enemy_x, enemy_y = tile_center(GRID_W - 2, 1)
	self.world:create({
		[Components.Position] = { x = enemy_x, y = enemy_y, speed = 0, size = 28 },
		[Components.Sprite] = { color = { 0.3, 0.5, 0.9, 1 }, size = 28 },
	})

	ctx.logger:info(
		"game.bomberman",
		string.format("arena %dx%d construida: %d paredes + player + inimigo parado", GRID_W, GRID_H, wall_count)
	)
end

function BombermanModule:update(dt)
	local main_region = self.ctx.ui_manager.regions.main
	self.world:set_resource("viewport", { x = main_region.x, y = main_region.y })

	local controllable_count = 0
	for _entity in self.world:query(Components.Controllable) do
		controllable_count = controllable_count + 1
	end
	self.world:set_resource("stats", { entidades_controlaveis = controllable_count })

	self.world:run("input", dt)
	self.world:run("logic", dt)
end

function BombermanModule:draw()
	self.world:run("render", 0)
end

function BombermanModule:shutdown()
	self.ctx.logger:info("game.bomberman", "world descartado")
	self.world = nil
	self.spatial = nil
end

return BombermanModule
