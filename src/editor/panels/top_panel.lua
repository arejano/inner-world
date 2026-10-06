local Row = require("src.ui.components.row")
local Text = require("src.ui.components.text")

---@param ctx table AppContext
local function build(ctx)
	local row = Row({ padding = 6, gap = 8 })
	row.style.bg = { 0.18, 0.18, 0.22, 1 }

	row:add_child(Text({ text = "Inner World v2 - Editor" }))

	return row
end

return { build = build }
