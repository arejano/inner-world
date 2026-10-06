local Context = require("src.app.context")
local ModuleRegistry = require("src.app.module_registry")
local EditorModule = require("src.editor.editor_module")
local BombermanModule = require("src.games.bomberman.bomberman_module")

-- Bootstrap: unico ponto que fala com love.* diretamente. Monta o
-- AppContext (servicos compartilhados), registra os Modulos e repassa
-- cada callback do LOVE pro ModuleRegistry. O protótipo (rox-editor) tinha
-- DOIS entry points (main.lua e base_main.lua) que nao se falavam -- aqui
-- so existe este.
local App = {}

function App.load()
	App.ctx = Context.new()
	App.registry = ModuleRegistry(App.ctx)
	App.ctx.module_registry = App.registry -- paineis do editor inspecionam o jogo ativo por aqui

	App.registry:set_editor(EditorModule)
	App.registry:register_game(BombermanModule)
	App.registry:activate_game(BombermanModule.id)
end

function App.update(dt)
	App.registry:update(dt)
	App.ctx.ui_manager:update(dt)
end

function App.draw()
	App.registry:draw()
	App.ctx.ui_manager:draw()
end

function App.keypressed(key)
	App.ctx.ui_manager:keypressed(key)
end

function App.keyreleased(key)
	App.ctx.ui_manager:keyreleased(key)
end

function App.mousepressed(x, y, button)
	App.ctx.ui_manager:mousepressed(x, y, button)
end

function App.mousereleased(x, y, button)
	App.ctx.ui_manager:mousereleased(x, y, button)
end

function App.mousemoved(x, y, dx, dy)
	App.ctx.ui_manager:mousemoved(x, y, dx, dy)
end

function App.wheelmoved(dx, dy)
	App.ctx.ui_manager:wheelmoved(dx, dy)
end

function App.resize(w, h)
	App.ctx.ui_manager:resize(w, h)
end

function App.quit()
	if App.ctx then
		App.ctx.logger:stop()
	end
end

return App
