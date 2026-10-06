local EventBus = require("src.core.event_bus")
local Assets = require("src.core.assets")
local Logger = require("src.core.logger")
local UIManager = require("src.ui.ui_manager")

-- Pacote de servicos injetado em Module:init(ctx). Nenhum modulo deve
-- tocar EventBus/Assets/UIManager/Logger como global -- tudo chega por
-- aqui.
---@class AppContext
---@field event_bus EventBus
---@field assets Assets
---@field logger Logger
---@field ui_manager UIManager
local Context = {}

---@return AppContext
function Context.new()
	local event_bus = EventBus()
	local assets = Assets()
	local logger = Logger()
	local ui_manager = UIManager(event_bus)

	logger:start()

	return {
		event_bus = event_bus,
		assets = assets,
		logger = logger,
		ui_manager = ui_manager,
	}
end

return Context
