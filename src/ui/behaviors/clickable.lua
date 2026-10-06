-- Comportamento anexavel via element:add_behavior(clickable(on_click)).
-- `on_click(element)` roda no mouse-release, so se o press tambem foi
-- neste elemento (botao mantem estado `_pressed` enquanto o botao do
-- mouse esta preso).
---@param on_click fun(element: Element)|nil
local function clickable(on_click)
	return {
		on_mouse_pressed = function(element, _x, _y, button)
			if button ~= 1 then
				return false
			end
			element._pressed = true
			element:mark_dirty()
			return true
		end,

		on_mouse_released = function(element, _x, _y, button)
			if button ~= 1 or not element._pressed then
				return false
			end
			element._pressed = false
			element:mark_dirty()
			if on_click then
				on_click(element)
			end
			return true
		end,
	}
end

return clickable
