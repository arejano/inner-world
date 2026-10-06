local Element = require("src.ui.element")
local Layout = require("src.ui.layout")

-- Container que empilha os filhos verticalmente, altura igual (ver
-- src/ui/layout.lua).
---@param opts { x: number|nil, y: number|nil, width: number|nil, height: number|nil, gap: number|nil, padding: number|nil }|nil
local function Column(opts)
	opts = opts or {}
	local element = Element({ x = opts.x, y = opts.y, width = opts.width, height = opts.height })
	element.style.bg = opts.bg
	element.gap = opts.gap or 0
	element.padding = opts.padding or 0

	function element:relayout()
		Layout.column(self, { gap = self.gap, padding = self.padding })
	end

	local base_add_child = element.add_child
	function element:add_child(child)
		base_add_child(self, child)
		self:relayout()
	end

	return element
end

return Column
