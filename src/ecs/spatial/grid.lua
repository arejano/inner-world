local Class = require("src.class")

-- Particionamento espacial como plugin OPCIONAL do ECS -- nao faz parte do
-- World, nao sabe o que e uma "entidade" (so trabalha com `id` generico +
-- AABB), e um GameModule so usa se precisar. No protótipo (rox-editor), o
-- octree era amarrado por convencao de nome de campo (`entity.position.x`)
-- e lido via `ecs.resources["octree"][1]` -- aqui a interface e so
-- insert/query/remove/update por id, sem acoplamento nenhum.
--
-- Grid uniforme (spatial hash): simples e suficiente ate o jogo doer de
-- performance (ver "comece simples" no doc de boas praticas). Trocar por
-- quadtree/octree depois e so trocar esta implementacao -- a interface
-- publica (insert/remove/update/query) fica igual.

---@alias AABB { x: number, y: number, w: number, h: number }

---@class SpatialGrid : Class
local SpatialGrid = Class.new()

function SpatialGrid:init(cell_size)
	self.cell_size = cell_size or 64
	self.cells = {} -- cell_key -> set<id>
	self.aabbs = {} -- id -> AABB (pra remocao/update sem precisar recalcular)
end

function SpatialGrid:_cell_key(cx, cy)
	return cx .. ":" .. cy
end

function SpatialGrid:_cells_for(aabb)
	local floor = math.floor
	local size = self.cell_size
	local min_cx, min_cy = floor(aabb.x / size), floor(aabb.y / size)
	local max_cx, max_cy = floor((aabb.x + aabb.w) / size), floor((aabb.y + aabb.h) / size)

	local keys = {}
	for cx = min_cx, max_cx do
		for cy = min_cy, max_cy do
			keys[#keys + 1] = self:_cell_key(cx, cy)
		end
	end
	return keys
end

---@param id any
---@param aabb AABB
function SpatialGrid:insert(id, aabb)
	self.aabbs[id] = aabb
	for _, key in ipairs(self:_cells_for(aabb)) do
		local cell = self.cells[key]
		if not cell then
			cell = {}
			self.cells[key] = cell
		end
		cell[id] = true
	end
end

---@param id any
function SpatialGrid:remove(id)
	local aabb = self.aabbs[id]
	if not aabb then
		return
	end

	for _, key in ipairs(self:_cells_for(aabb)) do
		local cell = self.cells[key]
		if cell then
			cell[id] = nil
		end
	end
	self.aabbs[id] = nil
end

---@param id any
---@param aabb AABB
function SpatialGrid:update(id, aabb)
	self:remove(id)
	self:insert(id, aabb)
end

---Retorna o conjunto (table id -> true) de ids cujas celulas tocam `aabb`.
---Pode incluir falsos positivos (objetos na mesma celula mas sem overlap
---real) -- quem consome decide se precisa de um segundo teste AABB fino.
---@param aabb AABB
function SpatialGrid:query(aabb)
	local results = {}
	for _, key in ipairs(self:_cells_for(aabb)) do
		local cell = self.cells[key]
		if cell then
			for id in pairs(cell) do
				results[id] = true
			end
		end
	end
	return results
end

return SpatialGrid
