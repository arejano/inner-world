-- Comportamento anexavel via element:add_behavior(draggable(opts)). Por
-- padrao arrasta o proprio elemento; passe opts.on_drag(dx, dy) quando
-- quem deve se mover e outra coisa (ex: a title bar arrasta a Window
-- inteira, nao a si mesma).
---@param opts { on_drag: (fun(dx: number, dy: number))|nil }|nil
local function draggable(opts)
	opts = opts or {}
	local dragging = false

	return {
		on_mouse_pressed = function(_element, _x, _y, button)
			if button ~= 1 then
				return false
			end
			dragging = true
			return true
		end,

		on_mouse_released = function(_element, _x, _y, button)
			if button ~= 1 or not dragging then
				return false
			end
			dragging = false
			return true
		end,

		on_mouse_moved = function(element, _x, _y, dx, dy)
			if not dragging then
				return false
			end
			if opts.on_drag then
				opts.on_drag(dx, dy)
			else
				element.x = element.x + dx
				element.y = element.y + dy
				element:mark_dirty()
			end
			return true
		end,
	}
end

return draggable
