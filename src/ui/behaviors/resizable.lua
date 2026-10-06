-- Comportamento anexavel via element:add_behavior(resizable(opts)). Por
-- padrao redimensiona o proprio elemento; passe opts.on_resize(dw, dh)
-- quando o alvo e outro elemento (ex: um resizer no canto de uma Window
-- redimensiona a Window, nao a si mesmo).
---@param opts { on_resize: (fun(dw: number, dh: number))|nil }|nil
local function resizable(opts)
	opts = opts or {}
	local resizing = false

	return {
		on_mouse_pressed = function(_element, _x, _y, button)
			if button ~= 1 then
				return false
			end
			resizing = true
			return true
		end,

		on_mouse_released = function(_element, _x, _y, button)
			if button ~= 1 or not resizing then
				return false
			end
			resizing = false
			return true
		end,

		on_mouse_moved = function(element, _x, _y, dx, dy)
			if not resizing then
				return false
			end
			if opts.on_resize then
				opts.on_resize(dx, dy)
			else
				element.width = math.max(1, element.width + dx)
				element.height = math.max(1, element.height + dy)
				element:mark_dirty()
			end
			return true
		end,
	}
end

return resizable
