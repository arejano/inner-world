local Element = require("src.ui.element")
local clickable = require("src.ui.behaviors.clickable")

---@param opts { x: number|nil, y: number|nil, width: number|nil, height: number|nil, label: string|nil, on_click: (fun(element: table))|nil }|nil
local function Button(opts)
	opts = opts or {}
	local element = Element({ x = opts.x, y = opts.y, width = opts.width or 120, height = opts.height or 32 })
	element.label = opts.label or ""
	element.font = opts.font or love.graphics.getFont()
	element.style.bg = opts.bg or { 0.25, 0.25, 0.32, 1 }
	element.style.fg = opts.fg or { 1, 1, 1, 1 }

	element:add_behavior(clickable(function()
		if opts.on_click then
			opts.on_click(element)
		end
	end))

	function element:draw_content()
		local bg = self._pressed and { 0.15, 0.15, 0.2, 1 } or self.style.bg
		love.graphics.setColor(unpack(bg))
		love.graphics.rectangle("fill", 0, 0, self.width, self.height)
		love.graphics.setFont(self.font)
		love.graphics.setColor(unpack(self.style.fg))
		love.graphics.printf(self.label, 0, self.height / 2 - self.font:getHeight() / 2, self.width, "center")
		love.graphics.setColor(1, 1, 1, 1)
	end

	return element
end

return Button
