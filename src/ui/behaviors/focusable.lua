-- Comportamento anexavel via element:add_behavior(focusable()). So marca
-- element.focused / redesenha -- o InputRouter ja decide QUANDO chamar
-- on_focus/on_blur (um unico foco de teclado por vez, ver input_router.lua).
local function focusable()
	return {
		on_focus = function(element)
			element.focused = true
			element:mark_dirty()
		end,

		on_blur = function(element)
			element.focused = false
			element:mark_dirty()
		end,
	}
end

return focusable
