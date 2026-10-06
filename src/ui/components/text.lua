local Element = require("src.ui.element")

---@param opts { x: number|nil, y: number|nil, width: number|nil, height: number|nil, text: string|nil, font: table|nil, fg: table|nil, bg: table|nil }|nil
local function Text(opts)
	opts = opts or {}
	local element = Element({ x = opts.x, y = opts.y, width = opts.width or 100, height = opts.height or 20 })
	element.text = opts.text or ""
	element.font = opts.font or love.graphics.getFont()
	element.style.bg = opts.bg
	element.style.fg = opts.fg or { 1, 1, 1, 1 }

	function element:set_text(text)
		self.text = text
		self:mark_dirty()
	end

	function element:draw_content()
		if self.style.bg then
			love.graphics.setColor(unpack(self.style.bg))
			love.graphics.rectangle("fill", 0, 0, self.width, self.height)
		end
		love.graphics.setFont(self.font)
		love.graphics.setColor(unpack(self.style.fg))
		love.graphics.print(self.text, 0, 0)
		love.graphics.setColor(1, 1, 1, 1)
	end

	return element
end

return Text
