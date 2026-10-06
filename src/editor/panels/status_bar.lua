-- Barra de status inferior: FPS por enquanto. EditorModule marca este
-- elemento sujo todo frame (ver editor_module.lua) porque o conteudo muda
-- a cada frame por natureza.
---@param ctx table AppContext
local function build(ctx)
	local Element = require("src.ui.element")
	local element = Element()
	element.style.bg = { 0.18, 0.18, 0.22, 1 }

	function element:draw_content()
		love.graphics.setColor(unpack(self.style.bg))
		love.graphics.rectangle("fill", 0, 0, self.width, self.height)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.print(string.format("FPS: %d", love.timer.getFPS()), 6, 2)
	end

	return element
end

return { build = build }
