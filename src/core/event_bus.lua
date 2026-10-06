local Class = require("src.class")

-- Canal unico de comunicacao entre modulos (EditorModule <-> GameModules).
-- Nenhum modulo deve dar `require` em outro modulo de app -- tudo passa por
-- aqui. Topicos sao strings namespaced por convencao ("editor:save",
-- "game.bomberman:bomb_placed", "ui:panel.resize").

---@class EventBus : Class
---@field subscribers table<string, table<number, fun(payload: any)>>
---@field next_id number
local EventBus = Class.new()

function EventBus:init()
	self.subscribers = {}
	self.next_id = 1
end

---@param topic string
---@param handler fun(payload: any)
---@return table subscription  -- passe de volta pra EventBus:off()
function EventBus:on(topic, handler)
	local list = self.subscribers[topic]
	if not list then
		list = {}
		self.subscribers[topic] = list
	end

	local id = self.next_id
	self.next_id = id + 1
	list[id] = handler

	return { topic = topic, id = id }
end

---@param subscription table
function EventBus:off(subscription)
	local list = self.subscribers[subscription.topic]
	if list then
		list[subscription.id] = nil
	end
end

---Emissao sincrona: todo handler inscrito roda imediatamente, na ordem de
---inscricao nao garantida. Se algum modulo precisar de fila/ordem entre
---frames, isso vira um EventBus:queue() no futuro -- nao existe ainda
---porque nenhum caso de uso real pediu (YAGNI).
---@param topic string
---@param payload any
function EventBus:emit(topic, payload)
	local list = self.subscribers[topic]
	if not list then
		return
	end

	for _, handler in pairs(list) do
		handler(payload)
	end
end

return EventBus
