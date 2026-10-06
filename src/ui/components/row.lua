local Element = require("src.ui.element")
local Layout = require("src.ui.layout")

-- Container que distribui os filhos em linha, largura igual (ver
-- src/ui/layout.lua). Relayout roda de novo a cada add_child -- suficiente
-- pro numero pequeno de filhos que um painel de editor costuma ter.
---@param opts { x: number|nil, y: number|nil, width: number|nil, height: number|nil, gap: number|nil, padding: number|nil }|nil
local function Row(opts)
	opts = opts or {}
	local element = Element({ x = opts.x, y = opts.y, width = opts.width, height = opts.height })
	element.style.bg = opts.bg
	element.gap = opts.gap or 0
	element.padding = opts.padding or 0

	function element:relayout()
		Layout.row(self, { gap = self.gap, padding = self.padding })
	end

	local base_add_child = element.add_child
	function element:add_child(child)
		base_add_child(self, child)
		self:relayout()
	end

	return element
end

return Row
