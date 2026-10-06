local Window = require("src.ui.components.window")
local Text = require("src.ui.components.text")
local Button = require("src.ui.components.button")

-- Janela flutuante so pra exercitar manualmente draggable/resizable da
-- Window (ver src/ui/components/window.lua) -- arrasta pela title bar,
-- redimensiona pelo quadrado cinza no canto inferior direito, clica no
-- botao e confere que o contador atualiza. Remover quando a inspecao real
-- de entidade/propriedades existir (ver roadmap em project_idea.md).
--
-- Nota: filhos de `window.content` usam coordenadas ABSOLUTAS (mesma
-- convencao do resto da lib -- ver nota de design em src/ui/element.lua),
-- entao sao posicionados em relacao a `content.x/content.y` no momento da
-- construcao, nao em (0,0).
---@param ctx table AppContext
local function build(ctx)
	local window = Window({ x = 480, y = 160, width = 260, height = 170, title = "Janela de teste" })
	local content = window.content
	local padding = 8

	local hint = Text({
		x = content.x + padding,
		y = content.y + padding,
		width = content.width - padding * 2,
		height = 40,
		text = "Arraste pelo titulo.\nRedimensione pelo canto.",
	})
	content:add_child(hint)

	local clicks = 0
	local counter_label = Text({
		x = content.x + padding,
		y = content.y + padding + 48,
		width = content.width - padding * 2,
		height = 20,
		text = "Cliques: 0",
	})
	content:add_child(counter_label)

	local button
	button = Button({
		x = content.x + padding,
		y = content.y + padding + 72,
		width = 100,
		height = 28,
		label = "Clique",
		on_click = function()
			clicks = clicks + 1
			counter_label:set_text("Cliques: " .. clicks)
		end,
	})
	content:add_child(button)

	return window
end

return { build = build }
