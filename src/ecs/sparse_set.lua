local Class = require("src.class")

-- Armazenamento de um tipo de componente: sparse set com array denso de
-- dados (cache-friendly, iteracao sem buracos) e um mapa indice-de-entidade
-- -> posicao-no-array-denso (O(1) add/remove/get). Substitui o hash
-- aninhado entity->component_id->data do protótipo.

---@class SparseSet : Class
local SparseSet = Class.new()

function SparseSet:init()
	self.dense_indices = {} -- array: posicao -> entity_index
	self.dense_data = {} -- array paralelo: posicao -> dado do componente
	self.sparse = {} -- map: entity_index -> posicao (1-based) em dense_*
end

---@param entity_index number
---@param data any
function SparseSet:set(entity_index, data)
	local pos = self.sparse[entity_index]
	if pos then
		self.dense_data[pos] = data
		return
	end

	local n = #self.dense_indices + 1
	self.dense_indices[n] = entity_index
	self.dense_data[n] = data
	self.sparse[entity_index] = n
end

---Remove em O(1): troca o ultimo elemento denso pra posicao removida
---("swap-remove") em vez de deslocar o array inteiro.
---@param entity_index number
function SparseSet:remove(entity_index)
	local pos = self.sparse[entity_index]
	if not pos then
		return
	end

	local last = #self.dense_indices
	local last_index = self.dense_indices[last]

	self.dense_indices[pos] = last_index
	self.dense_data[pos] = self.dense_data[last]
	self.sparse[last_index] = pos

	self.dense_indices[last] = nil
	self.dense_data[last] = nil
	self.sparse[entity_index] = nil
end

---@param entity_index number
function SparseSet:get(entity_index)
	local pos = self.sparse[entity_index]
	return pos and self.dense_data[pos] or nil
end

---@param entity_index number
function SparseSet:has(entity_index)
	return self.sparse[entity_index] ~= nil
end

function SparseSet:count()
	return #self.dense_indices
end

return SparseSet
