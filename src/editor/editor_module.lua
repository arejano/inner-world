local TopPanel = require("src.editor.panels.top_panel")
local LeftPanel = require("src.editor.panels.left_panel")
local MainPanel = require("src.editor.panels.main_panel")
local RightPanel = require("src.editor.panels.right_panel")
local StatusBar = require("src.editor.panels.status_bar")
local FloatTestWindow = require("src.editor.panels.float_test_window")

-- EditorModule: a interface visual de edicao. So fala com o jogo ativo via
-- `ctx.module_registry:active_game()` (nunca `require` de um GameModule
-- especifico) e so fala com a UI via `ctx.ui_manager` -- segue o mesmo
-- contrato Module que qualquer GameModule (ver docs/ARCHITECTURE.md).
local EditorModule = {
	id = "editor",
}

function EditorModule:init(ctx)
	self.ctx = ctx
	local ui_manager = ctx.ui_manager

	ui_manager:register_panel(self.id, "top", TopPanel, ctx)
	self.left_panel = ui_manager:register_panel(self.id, "left", LeftPanel, ctx)
	ui_manager:register_panel(self.id, "main", MainPanel, ctx)
	self.right_panel = ui_manager:register_panel(self.id, "right", RightPanel, ctx)
	self.status_panel = ui_manager:register_panel(self.id, "status_bottom", StatusBar, ctx)
	ui_manager:register_panel(self.id, "float", FloatTestWindow, ctx)

	ctx.logger:info("editor", "paineis registrados: top/left/main/right/status_bottom/float(teste)")
end

---Paineis de inspecao (left/right/status) mostram dado vivo do jogo ativo
----- precisam ser marcados sujos todo frame pra refletir isso. O resto da
---UI (botoes, chrome de janela) so fica sujo quando o estado dele muda de
---verdade, via mark_dirty() nos proprios pontos de interacao.
function EditorModule:update(dt)
	if self.left_panel.refresh then
		self.left_panel:refresh()
		self.left_panel:mark_dirty()
	end

	if self.right_panel.refresh then
		self.right_panel:refresh()
		self.right_panel:mark_dirty()
	end

	self.status_panel:mark_dirty()
end

function EditorModule:draw() end

function EditorModule:shutdown()
	self.ctx.ui_manager:unregister_owner(self.id)
	self.ctx.logger:info("editor", "paineis removidos")
end

return EditorModule
