local Column = require("src.ui.components.column")
local Text = require("src.ui.components.text")

-- Lista os tipos de componente registrados no world do jogo ativo e
-- quantas entidades tem cada um -- generico (le `component_type.name`),
-- nao sabe nada especifico de bomberman.
---@param ctx table AppContext
local function build(ctx)
	local column = Column({ padding = 8, gap = 6 })
	column.style.bg = { 0.14, 0.14, 0.17, 1 }

	column:add_child(Text({ text = "Componentes" }))
	local info = Text({ text = "" })
	column:add_child(info)
	column.info = info

	function column:refresh()
		local game = ctx.module_registry:active_game()
		if not game or not game.world then
			self.info:set_text("")
			return
		end

		local lines = {}
		for component_type, store in pairs(game.world.stores) do
			local name = component_type.name or tostring(component_type)
			lines[#lines + 1] = name .. ": " .. store:count()
		end

		self.info:set_text(table.concat(lines, "\n"))
	end

	return column
end

return { build = build }
