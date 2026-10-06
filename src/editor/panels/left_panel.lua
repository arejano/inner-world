local Column = require("src.ui.components.column")
local Text = require("src.ui.components.text")

-- Inspector de estado do jogo ativo. Le `game.world:get_resource("stats")`
-- -- nunca `require` o GameModule especifico -- qualquer jogo que exponha
-- esse resource aparece aqui, sem o EditorModule saber o que e
-- "bomberman".
---@param ctx table AppContext
local function build(ctx)
	local column = Column({ padding = 8, gap = 6 })
	column.style.bg = { 0.14, 0.14, 0.17, 1 }

	column:add_child(Text({ text = "Entidades" }))
	local info = Text({ text = "" })
	column:add_child(info)
	column.info = info

	function column:refresh()
		local game = ctx.module_registry:active_game()
		if not game or not game.world then
			self.info:set_text("(nenhum jogo ativo)")
			return
		end

		local lines = { "jogo: " .. game.id }
		local stats = game.world:get_resource("stats") or {}
		for key, value in pairs(stats) do
			lines[#lines + 1] = tostring(key) .. " = " .. tostring(value)
		end

		self.info:set_text(table.concat(lines, "\n"))
	end

	return column
end

return { build = build }
