-- Mapeia acoes pra teclas fisicas. Modulos checam a acao ("move_right"),
-- nunca a tecla crua -- rebind fica so nesta tabela.
--
-- Suporta "camadas" (layer) porque mais de um modulo pode querer bindings
-- proprios (ex: EditorModule usa uma camada "editor", um GameModule usa
-- "game") sem um layer pisar nos binds do outro.
local layers = {
	global = {
		toggle_editor = { "f1" },
		quit = { "escape" },
	},
	game = {
		move_right = { "right", "d" },
		move_left = { "left", "a" },
		move_down = { "down", "s" },
		move_up = { "up", "w" },
		confirm = { "return", "space" },
	},
}

local InputMap = {}

---@param layer string
---@param action string
function InputMap.down(layer, action)
	local bindings = layers[layer]
	local keys = bindings and bindings[action]
	if not keys then
		return false
	end
	return love.keyboard.isDown(unpack(keys))
end

---Usar dentro de love.keypressed(key): confere se `key` pertence a acao.
---@param layer string
---@param action string
---@param key string
function InputMap.is(layer, action, key)
	local bindings = layers[layer]
	local keys = bindings and bindings[action]
	if not keys then
		return false
	end
	for _, k in ipairs(keys) do
		if k == key then
			return true
		end
	end
	return false
end

return InputMap
