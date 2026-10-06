local Class = require("src.class")
local SparseSet = require("src.ecs.sparse_set")
local CommandBuffer = require("src.ecs.command_buffer")

-- ECS generico, sem nenhuma dependencia de LOVE2D ou de um GameModule
-- especifico. Correcoes em relacao ao protótipo (core/ecs/ecs.lua do
-- rox-editor):
--   * entidade = {index, generation} com freelist de indices reciclados,
--     em vez de UUID string nunca liberada -- handle obsoleto e detectavel
--     em O(1) via World:alive().
--   * armazenamento em sparse set por componente (ver sparse_set.lua) em
--     vez de hash aninhado entity->component_id->data.
--   * World:query(...) e intersecao de verdade (itera o menor conjunto
--     envolvido e testa pertencimento nos demais) -- o protótipo fazia
--     uniao, o que exigia cada sistema compensar com checagem manual.
--   * destruicao/add/remove de componente passam por CommandBuffer e so
--     sao aplicados em World:flush() -- sistema nunca muta a entidade
--     enquanto itera sobre ela.
--   * resources e um valor por chave (nao array-de-um-elemento-so).

---@alias Entity { index: number, generation: number }

---@class World : Class
local World = Class.new()

function World:init()
	self.generations = {} -- entity_index -> geracao atual
	self.free_indices = {}
	self.next_index = 0

	self.stores = {} -- component_type -> SparseSet
	self.resources = {} -- name -> value
	self.systems = {} -- stage -> array de { name = string, fn = function }

	self.command_buffer = CommandBuffer(self)
end

---@param component_type table
---@return SparseSet
function World:store_for(component_type)
	local store = self.stores[component_type]
	if not store then
		store = SparseSet()
		self.stores[component_type] = store
	end
	return store
end

---Cria uma entidade. `components` e opcional: table<component_type, data>.
---@param components table|nil
---@return Entity
function World:create(components)
	local index
	if #self.free_indices > 0 then
		index = table.remove(self.free_indices)
	else
		self.next_index = self.next_index + 1
		index = self.next_index
	end

	self.generations[index] = self.generations[index] or 0
	local entity = { index = index, generation = self.generations[index] }

	if components then
		for component_type, data in pairs(components) do
			self:_add_immediate(entity, component_type, data)
		end
	end

	return entity
end

---@param entity Entity
function World:alive(entity)
	return self.generations[entity.index] == entity.generation
end

function World:_add_immediate(entity, component_type, data)
	assert(self:alive(entity), "tentativa de add_component em entidade morta")
	self:store_for(component_type):set(entity.index, data)
end

function World:_remove_immediate(entity, component_type)
	local store = self.stores[component_type]
	if store then
		store:remove(entity.index)
	end
end

function World:_destroy_immediate(entity)
	if not self:alive(entity) then
		return
	end

	for _, store in pairs(self.stores) do
		store:remove(entity.index)
	end

	self.generations[entity.index] = entity.generation + 1
	self.free_indices[#self.free_indices + 1] = entity.index
end

---Adiciona um componente imediatamente (seguro fora de um sistema em
---iteracao). Dentro de um `process` de sistema, prefira enfileirar via
---`world.command_buffer:add_component`.
---@param entity Entity
---@param component_type table
---@param data any
function World:add(entity, component_type, data)
	self:_add_immediate(entity, component_type, data)
end

---@param entity Entity
---@param component_type table
function World:remove(entity, component_type)
	self:_remove_immediate(entity, component_type)
end

---@param entity Entity
---@param component_type table
function World:get(entity, component_type)
	local store = self.stores[component_type]
	return store and store:get(entity.index) or nil
end

---@param entity Entity
---@param component_type table
function World:has(entity, component_type)
	local store = self.stores[component_type]
	return store ~= nil and store:has(entity.index)
end

---Destroi de forma segura: enfileira no command buffer, aplicado no
---proximo World:flush() (fim do estagio atual).
---@param entity Entity
function World:destroy(entity)
	self.command_buffer:destroy(entity)
end

function World:flush()
	self.command_buffer:flush()
end

---Interseccao real dos tipos pedidos. Itera o menor conjunto envolvido e
---testa pertencimento nos demais -- O(tamanho do menor conjunto), nao
---O(todas as entidades). Retorna um iterador: entity, data1, data2, ...
---@param ... table component types
function World:query(...)
	local types = { ... }
	assert(#types > 0, "World:query precisa de ao menos um component type")

	local stores = {}
	for i, component_type in ipairs(types) do
		stores[i] = self:store_for(component_type)
	end

	local smallest = stores[1]
	for i = 2, #stores do
		if stores[i]:count() < smallest:count() then
			smallest = stores[i]
		end
	end

	local entity_indices = smallest.dense_indices
	local i = 0
	local n = #entity_indices

	return function()
		i = i + 1
		while i <= n do
			local entity_index = entity_indices[i]
			local matches = true
			for _, store in ipairs(stores) do
				if not store:has(entity_index) then
					matches = false
					break
				end
			end

			if matches then
				local entity = { index = entity_index, generation = self.generations[entity_index] }
				local results = { entity }
				for j, store in ipairs(stores) do
					results[j + 1] = store:get(entity_index)
				end
				return unpack(results)
			end

			i = i + 1
		end
		return nil
	end
end

---@param name string
---@param value any
function World:set_resource(name, value)
	self.resources[name] = value
end

---@param name string
function World:get_resource(name)
	return self.resources[name]
end

---Registra um sistema num estagio (ex: "input", "logic", "render"). A
---ordem de execucao e a ordem de registro (array, nao `pairs()` sobre uma
---tabela -- em Lua a ordem de `pairs` nao e garantida).
---@param stage string
---@param name string
---@param fn fun(world: World, dt: number)
function World:add_system(stage, name, fn)
	local systems = self.systems[stage]
	if not systems then
		systems = {}
		self.systems[stage] = systems
	end
	systems[#systems + 1] = { name = name, fn = fn }
end

---Roda todos os sistemas de um estagio, na ordem de registro, e em seguida
---aplica o command buffer -- qualquer destroy/add/remove enfileirado
---durante o estagio so afeta o PROXIMO estagio, nunca o atual.
---@param stage string
---@param dt number
function World:run(stage, dt)
	local systems = self.systems[stage]
	if systems then
		for _, system in ipairs(systems) do
			system.fn(self, dt)
		end
	end
	self:flush()
end

return World
