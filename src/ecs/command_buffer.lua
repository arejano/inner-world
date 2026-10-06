local Class = require("src.class")

-- Mudancas estruturais (destruir entidade, add/remove componente) nunca
-- acontecem durante a iteracao de um sistema -- entram numa fila e so sao
-- aplicadas quando World:flush() roda (fim do estagio atual). Isso elimina
-- o risco de "iterar enquanto muta" e e o que falta no ECS do protótipo
-- pra permitir destruir entidade com seguranca.

---@class CommandBuffer : Class
local CommandBuffer = Class.new()

function CommandBuffer:init(world)
	self.world = world
	self.destroys = {}
	self.adds = {}
	self.removes = {}
end

---@param entity Entity
function CommandBuffer:destroy(entity)
	self.destroys[#self.destroys + 1] = entity
end

---@param entity Entity
---@param component_type table
---@param data any
function CommandBuffer:add_component(entity, component_type, data)
	self.adds[#self.adds + 1] = { entity = entity, component_type = component_type, data = data }
end

---@param entity Entity
---@param component_type table
function CommandBuffer:remove_component(entity, component_type)
	self.removes[#self.removes + 1] = { entity = entity, component_type = component_type }
end

function CommandBuffer:flush()
	if #self.adds == 0 and #self.removes == 0 and #self.destroys == 0 then
		return
	end

	for _, item in ipairs(self.adds) do
		self.world:_add_immediate(item.entity, item.component_type, item.data)
	end

	for _, item in ipairs(self.removes) do
		self.world:_remove_immediate(item.entity, item.component_type)
	end

	for _, entity in ipairs(self.destroys) do
		self.world:_destroy_immediate(entity)
	end

	self.adds = {}
	self.removes = {}
	self.destroys = {}
end

return CommandBuffer
