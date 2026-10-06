local Class = require("src.class")

-- Hit-test por z-order (filho desenhado por cima vence) + despacho de
-- mouse/teclado pros "behaviors" anexados a cada elemento. Duas correcoes
-- em relacao ao protótipo (core/ui/handler.lua do rox-editor):
--   * foco de teclado de verdade (elementOnKeyboardFocus) -- o protótipo
--     nao tinha nenhum, por isso o componente de texto nunca saiu do papel.
--   * "captura" de mouse: enquanto um behavior consome o mousepressed
--     (ex: draggable), os eventos seguintes vao direto pro elemento
--     capturado, mesmo que o mouse saia da area dele -- sem isso, soltar
--     o drag fora dos limites do elemento perderia o evento.

---@class InputRouter : Class
local InputRouter = Class.new()

function InputRouter:init(root)
	self.root = root
	self.hovered = nil
	self.captured = nil
	self.keyboard_focus = nil
end

---@param root Element
function InputRouter:set_root(root)
	self.root = root
end

---@param x number
---@param y number
---@return Element|nil
function InputRouter:hit_test(x, y)
	local function test(element)
		if not element or not element.visible then
			return nil
		end

		-- filhos sao desenhados por cima do pai -- testa eles primeiro,
		-- do ultimo (topo) pro primeiro.
		for i = #element.children, 1, -1 do
			local hit = test(element.children[i])
			if hit then
				return hit
			end
		end

		if element.hit_transparent then
			return nil
		end

		if x >= element.x and x <= element.x + element.width and y >= element.y and y <= element.y + element.height then
			return element
		end

		return nil
	end

	return test(self.root)
end

function InputRouter:_dispatch(element, hook_name, ...)
	if not element then
		return false
	end
	for _, behavior in ipairs(element.behaviors) do
		local hook = behavior[hook_name]
		if hook and hook(element, ...) then
			return true
		end
	end
	return false
end

---@param element Element|nil
function InputRouter:set_keyboard_focus(element)
	if self.keyboard_focus == element then
		return
	end
	if self.keyboard_focus then
		self:_dispatch(self.keyboard_focus, "on_blur")
	end
	self.keyboard_focus = element
	if element then
		self:_dispatch(element, "on_focus")
	end
end

function InputRouter:mousepressed(x, y, button)
	local target = self:hit_test(x, y)

	if target and target.focusable then
		self:set_keyboard_focus(target)
	elseif not target then
		self:set_keyboard_focus(nil)
	end

	if self:_dispatch(target, "on_mouse_pressed", x, y, button) then
		self.captured = target
	end
end

function InputRouter:mousereleased(x, y, button)
	local target = self.captured or self.hovered
	self:_dispatch(target, "on_mouse_released", x, y, button)
	self.captured = nil
end

function InputRouter:mousemoved(x, y, dx, dy)
	if self.captured then
		self:_dispatch(self.captured, "on_mouse_moved", x, y, dx, dy)
		return
	end

	local target = self:hit_test(x, y)
	if target ~= self.hovered then
		self:_dispatch(self.hovered, "on_mouse_leave")
		self:_dispatch(target, "on_mouse_enter")
		self.hovered = target
	end

	self:_dispatch(target, "on_mouse_moved", x, y, dx, dy)
end

function InputRouter:wheelmoved(dx, dy)
	self:_dispatch(self.hovered, "on_wheel_moved", dx, dy)
end

function InputRouter:keypressed(key)
	self:_dispatch(self.keyboard_focus, "on_key_pressed", key)
end

function InputRouter:keyreleased(key)
	self:_dispatch(self.keyboard_focus, "on_key_released", key)
end

return InputRouter
