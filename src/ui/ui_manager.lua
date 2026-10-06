local Class = require("src.class")
local Element = require("src.ui.element")
local InputRouter = require("src.ui.input_router")
local Layout = require("src.ui.layout")

-- Dono das regioes de docking (top/left/main/right/status_bottom) + da
-- camada "float" (janelas soltas). Modulos registram paineis
-- declarativamente via PanelSpec -- nenhuma tabela global tipo
-- `_G.main_rects` (como no protótipo) e usada pra um painel descobrir o
-- retangulo de outro; quem resolve o retangulo e sempre a regiao.

---@class PanelSpec
---@field build fun(ctx: table): table  -- table = AppContext; retorna um Element

local TOP_HEIGHT = 32
local STATUS_HEIGHT = 24
local SIDE_WIDTH = 240

---@class UIManager : Class
local UIManager = Class.new()

function UIManager:init(event_bus)
	self.event_bus = event_bus
	self.root = Element({ x = 0, y = 0, width = love.graphics.getWidth(), height = love.graphics.getHeight() })
	self.root.style.bg = nil
	self.root.hit_transparent = true

	self.regions = {}
	self.panel_owners = {} -- region_name -> array<Element>
	self.floats = {} -- array<Element>, fora do grid de regioes

	for _, name in ipairs({ "top", "left", "main", "right", "status_bottom" }) do
		local region = Element()
		region.name = name
		region.hit_transparent = true
		-- regiao e so um container de docking, nao um elemento visual -- sem
		-- isso o bg opaco padrao (Element:init) cobriria o jogo desenhado por
		-- baixo na regiao "main" (o GameModule desenha direto na tela, ANTES
		-- do ui_manager:draw() -- ver ModuleRegistry:draw em module_registry.lua).
		-- Paineis que quiserem fundo visivel (top/left/right/status) ja
		-- pintam o proprio bg.
		region.style.bg = nil
		self.regions[name] = region
		self.root:add_child(region)
	end

	self.input_router = InputRouter(self.root)
	self:_layout_regions()
end

function UIManager:_layout_regions()
	local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	local top, status = self.regions.top, self.regions.status_bottom
	local left, right, main = self.regions.left, self.regions.right, self.regions.main

	top.x, top.y, top.width, top.height = 0, 0, w, TOP_HEIGHT
	status.x, status.y, status.width, status.height = 0, h - STATUS_HEIGHT, w, STATUS_HEIGHT

	local middle_y = TOP_HEIGHT
	local middle_h = h - TOP_HEIGHT - STATUS_HEIGHT

	left.x, left.y, left.width, left.height = 0, middle_y, SIDE_WIDTH, middle_h
	right.x, right.y, right.width, right.height = w - SIDE_WIDTH, middle_y, SIDE_WIDTH, middle_h
	main.x, main.y, main.width, main.height = SIDE_WIDTH, middle_y, w - SIDE_WIDTH * 2, middle_h

	for _, region in pairs(self.regions) do
		region:mark_dirty()
		Layout.fill(region, { padding = 4 })
	end
end

---Registra um painel de um modulo numa regiao de docking (ou em "float",
---que nao participa do grid). `ctx` e o AppContext repassado pro builder.
---@param owner_id string
---@param region_name "top"|"left"|"main"|"right"|"status_bottom"|"float"
---@param panel_spec PanelSpec
---@param ctx table
---@return table element
function UIManager:register_panel(owner_id, region_name, panel_spec, ctx)
	local element = panel_spec.build(ctx)
	element.owner_id = owner_id

	if region_name == "float" then
		self.floats[#self.floats + 1] = element
		self.root:add_child(element)
		self.event_bus:emit("ui:panel.registered", { owner_id = owner_id, region = region_name })
		return element
	end

	local region = self.regions[region_name]
	assert(region, "regiao de docking invalida: " .. tostring(region_name))

	region:add_child(element)

	local owners = self.panel_owners[region_name]
	if not owners then
		owners = {}
		self.panel_owners[region_name] = owners
	end
	owners[#owners + 1] = element

	self:_layout_regions()
	self.event_bus:emit("ui:panel.registered", { owner_id = owner_id, region = region_name })

	return element
end

---Remove todos os paineis/floats registrados por um modulo -- chamar no
---Module:shutdown(). O protótipo nunca tinha um caminho de remocao.
---@param owner_id string
function UIManager:unregister_owner(owner_id)
	for _, owners in pairs(self.panel_owners) do
		for i = #owners, 1, -1 do
			if owners[i].owner_id == owner_id then
				owners[i]:destroy()
				table.remove(owners, i)
			end
		end
	end

	for i = #self.floats, 1, -1 do
		if self.floats[i].owner_id == owner_id then
			self.floats[i]:destroy()
			table.remove(self.floats, i)
		end
	end
end

function UIManager:resize(w, h)
	self.root.width, self.root.height = w, h
	self:_layout_regions()
end

---Reservado pra animacoes/transicoes de UI -- nenhuma ainda (YAGNI), mas o
---metodo existe porque App.update ja chama ui_manager:update(dt) todo
---frame junto do resto do ciclo de vida.
function UIManager:update(_dt) end

function UIManager:draw()
	self.root:render()
end

function UIManager:mousepressed(x, y, button)
	self.input_router:mousepressed(x, y, button)
end

function UIManager:mousereleased(x, y, button)
	self.input_router:mousereleased(x, y, button)
end

function UIManager:mousemoved(x, y, dx, dy)
	self.input_router:mousemoved(x, y, dx, dy)
end

function UIManager:wheelmoved(dx, dy)
	self.input_router:wheelmoved(dx, dy)
end

function UIManager:keypressed(key)
	self.input_router:keypressed(key)
end

function UIManager:keyreleased(key)
	self.input_router:keyreleased(key)
end

return UIManager
