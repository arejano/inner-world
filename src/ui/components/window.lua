local Element = require("src.ui.element")
local draggable = require("src.ui.behaviors.draggable")
local resizable = require("src.ui.behaviors.resizable")

-- Janela flutuante: title bar arrastavel + area de conteudo + resizer no
-- canto inferior direito. Ao contrario do protótipo (core/ui/components/
-- window.lua do rox-editor), nao carrega semantica de produto (botao de
-- "enroll") -- so chrome generico de janela. Minimize/maximize ficam de
-- fora ate um caso de uso real pedir (YAGNI).
local TITLE_HEIGHT = 24
local RESIZER_SIZE = 14

---@param opts { x: number|nil, y: number|nil, width: number|nil, height: number|nil, title: string|nil }|nil
local function Window(opts)
	opts = opts or {}
	local window = Element({ x = opts.x or 0, y = opts.y or 0, width = opts.width or 320, height = opts.height or 240 })
	window.style.bg = nil
	window.hit_transparent = true -- so os filhos (title bar/conteudo/resizer) recebem hit-test

	local title_bar = Element({ width = window.width, height = TITLE_HEIGHT })
	title_bar.style.bg = opts.title_bg or { 0.2, 0.2, 0.26, 1 }
	title_bar.title = opts.title or ""
	title_bar.font = opts.title_font or love.graphics.getFont()

	function title_bar:draw_content()
		love.graphics.setColor(unpack(self.style.bg))
		love.graphics.rectangle("fill", 0, 0, self.width, self.height)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.setFont(self.font)
		love.graphics.print(self.title, 6, 4)
	end

	local content = Element({ width = window.width, height = window.height - TITLE_HEIGHT })
	content.style.bg = opts.content_bg or { 0.12, 0.12, 0.15, 1 }

	local resizer = Element({ width = RESIZER_SIZE, height = RESIZER_SIZE })
	resizer.style.bg = { 0.4, 0.4, 0.46, 1 }

	window:add_child(title_bar)
	window:add_child(content)
	window:add_child(resizer)
	window.content = content
	window.title_bar = title_bar

	function window:_reflow()
		self.title_bar.x, self.title_bar.y = self.x, self.y
		self.title_bar.width = self.width
		self.title_bar:mark_dirty()

		self.content.x, self.content.y = self.x, self.y + TITLE_HEIGHT
		self.content.width, self.content.height = self.width, self.height - TITLE_HEIGHT
		self.content:mark_dirty()

		resizer.x = self.x + self.width - RESIZER_SIZE
		resizer.y = self.y + self.height - RESIZER_SIZE
		resizer:mark_dirty()
	end

	title_bar:add_behavior(draggable({
		-- translate (nao _reflow): move title_bar/content/resizer E qualquer
		-- conteudo que o consumidor tenha adicionado dentro de `content`,
		-- tudo pelo mesmo delta -- ver Element:translate em element.lua.
		on_drag = function(dx, dy)
			window:translate(dx, dy)
		end,
	}))

	resizer:add_behavior(resizable({
		on_resize = function(dw, dh)
			window.width = math.max(RESIZER_SIZE * 4, window.width + dw)
			window.height = math.max(TITLE_HEIGHT + RESIZER_SIZE * 2, window.height + dh)
			window:_reflow()
		end,
	}))

	window:_reflow()

	return window
end

return Window
