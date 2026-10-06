local Class = require("src.class")

-- Elemento base da UI retained-mode. Cada elemento desenha SO O PROPRIO
-- CONTEUDO (draw_content) dentro do seu canvas, em coordenadas locais
-- (0,0) -- nunca o conteudo dos filhos. A arvore e composta na tela: cada
-- elemento desenha seu canvas na posicao absoluta (x,y) e depois manda os
-- filhos se desenharem por cima. Isso corrige dois problemas do protótipo
-- (core/ui/element.lua do rox-editor):
--   * la, o componente de texto desenhava em self.rect.x/y DENTRO do
--     proprio canvas, que ja e deslocado pra (x,y) na tela -- duplo
--     deslocamento. Aqui draw_content sempre usa (0,0) como origem.
--   * la, mark_dirty() propagava pra baixo (todos os filhos) mas so as
--     vezes pra cima, de forma inconsistente. Aqui nao precisa propagar:
--     como cada elemento e independente na composicao final, sujar um
--     elemento nunca exige redesenhar pai nem filhos.
--
-- Canvas tem "pool" simples: o tamanho real da textura e arredondado pra
-- cima num grid (CANVAS_GRANULARITY) e so realoca quando o novo tamanho
-- excede a capacidade atual -- evita o release()+newCanvas() a cada frame
-- de resize que o protótipo fazia.

local CANVAS_GRANULARITY = 32

---@class Element : Class
local Element = Class.new()

---@param rect { x: number, y: number, width: number, height: number }|nil
function Element:init(rect)
	rect = rect or {}
	self.x = rect.x or 0
	self.y = rect.y or 0
	self.width = rect.width or 0
	self.height = rect.height or 0

	self.visible = true
	self.alpha = 1
	self.dirty = true
	self.focusable = false
	self.hit_transparent = false -- true = nunca recebe hit-test (so os filhos)

	self.style = { bg = { 0.15, 0.15, 0.18, 1 } }

	self.children = {}
	self.behaviors = {}
	self.parent = nil

	self.canvas = nil
	self.canvas_w = 0
	self.canvas_h = 0
end

function Element:mark_dirty()
	self.dirty = true
end

---@param child Element
function Element:add_child(child)
	child.parent = self
	self.children[#self.children + 1] = child
end

---@param child Element
function Element:remove_child(child)
	for i, existing in ipairs(self.children) do
		if existing == child then
			table.remove(self.children, i)
			child.parent = nil
			return
		end
	end
end

---Move o elemento e toda a subarvore pelo mesmo delta. Como posicao de
---filho e absoluta (nao relativa ao pai -- ver nota de design no topo do
---arquivo), arrastar um container (ex: a Window) sem isso faria o
---conteudo dele "descolar" na tela, parado na posicao antiga.
---@param dx number
---@param dy number
function Element:translate(dx, dy)
	self.x = self.x + dx
	self.y = self.y + dy
	for _, child in ipairs(self.children) do
		child:translate(dx, dy)
	end
end

---@param behavior table  -- ver src/ui/behaviors/*.lua
function Element:add_behavior(behavior)
	self.behaviors[#self.behaviors + 1] = behavior
	if behavior.on_focus or behavior.on_blur then
		self.focusable = true
	end
	return behavior
end

---Desenha o conteudo do elemento em coordenadas locais (0,0 = canto
---superior esquerdo do proprio canvas). Ponto de extensao -- componentes
---sobrescrevem isso, nunca `render`.
function Element:draw_content()
	if self.style.bg then
		love.graphics.setColor(unpack(self.style.bg))
		love.graphics.rectangle("fill", 0, 0, self.width, self.height)
		love.graphics.setColor(1, 1, 1, 1)
	end
end

function Element:_ensure_canvas()
	local w = math.max(1, math.ceil(self.width / CANVAS_GRANULARITY) * CANVAS_GRANULARITY)
	local h = math.max(1, math.ceil(self.height / CANVAS_GRANULARITY) * CANVAS_GRANULARITY)

	if not self.canvas or w > self.canvas_w or h > self.canvas_h then
		if self.canvas then
			self.canvas:release()
		end
		self.canvas = love.graphics.newCanvas(w, h)
		self.canvas_w, self.canvas_h = w, h
		self.dirty = true
	end
end

---Chamado pelo UIManager (ou por um pai) uma vez por frame. Redesenha o
---canvas so se `dirty`, depois desenha o canvas na posicao absoluta e
---recursivamente renderiza os filhos por cima.
function Element:render()
	if not self.visible then
		return
	end

	self:_ensure_canvas()

	if self.dirty then
		love.graphics.push("all")
		love.graphics.setCanvas(self.canvas)
		love.graphics.clear(0, 0, 0, 0)
		self:draw_content()
		love.graphics.setCanvas()
		love.graphics.pop()
		self.dirty = false
	end

	love.graphics.setColor(1, 1, 1, self.alpha)
	love.graphics.draw(self.canvas, self.x, self.y)
	love.graphics.setColor(1, 1, 1, 1)

	for _, child in ipairs(self.children) do
		child:render()
	end
end

---Remove da arvore, libera canvas e destroi os filhos. O protótipo nunca
---tinha esse caminho -- elementos so cresciam.
function Element:destroy()
	for i = #self.children, 1, -1 do
		self.children[i]:destroy()
	end

	if self.canvas then
		self.canvas:release()
		self.canvas = nil
	end

	if self.parent then
		self.parent:remove_child(self)
	end
end

return Element
