local Class = require("src.class")

-- Dono do ciclo de vida dos Modulos (ver docs/ARCHITECTURE.md pro
-- contrato). Um EditorModule fixo + N GameModules registrados, dos quais
-- no maximo um fica ativo por vez. Trocar de jogo e troca a quente:
-- chama shutdown no antigo, init no novo, emite "game:switched" -- sem
-- reiniciar o app. O protótipo (rox-editor) nao tinha nada disso: Editor e
-- Game eram dois globais amarrados a mao dentro de love.load/update/draw.

---@class ModuleRegistry : Class
local ModuleRegistry = Class.new()

function ModuleRegistry:init(ctx)
	self.ctx = ctx
	self.editor = nil
	self.games = {}
	self.active_game_id = nil
end

---@param editor_module table  -- implementa o contrato Module
function ModuleRegistry:set_editor(editor_module)
	self.editor = editor_module
	editor_module:init(self.ctx)
	self.ctx.logger:info("editor", "modulo inicializado")
end

---@param game_module table  -- implementa o contrato Module, com campo `id`
function ModuleRegistry:register_game(game_module)
	assert(game_module.id, "game module precisa de um campo `id`")
	self.games[game_module.id] = game_module
	self.ctx.logger:info("app", "game module registrado: " .. game_module.id)
end

---@param id string
function ModuleRegistry:activate_game(id)
	local next_game = self.games[id]
	assert(next_game, "game module nao registrado: " .. tostring(id))

	local current = self:active_game()
	if current then
		current:shutdown()
		self.ctx.ui_manager:unregister_owner(current.id)
		self.ctx.logger:info("game." .. current.id, "modulo desligado")
	end

	self.active_game_id = id
	next_game:init(self.ctx)
	self.ctx.logger:info("game." .. id, "modulo ativado")
	self.ctx.event_bus:emit("game:switched", { id = id })
end

function ModuleRegistry:active_game()
	return self.active_game_id and self.games[self.active_game_id] or nil
end

function ModuleRegistry:update(dt)
	local game = self:active_game()
	if game then
		game:update(dt)
	end
	if self.editor then
		self.editor:update(dt)
	end
end

function ModuleRegistry:draw()
	local game = self:active_game()
	if game then
		game:draw()
	end
	if self.editor then
		self.editor:draw()
	end
end

return ModuleRegistry
