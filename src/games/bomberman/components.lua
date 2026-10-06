-- Tipos de componente do bomberman. Cada um e so uma tabela-marcador (usada
-- como chave no World) com um `name` legivel pra inspecao no editor (ver
-- src/editor/panels/right_panel.lua, que le `component_type.name`).
return {
	Position = { name = "Position" }, -- { x, y, speed }
	Velocity = { name = "Velocity" }, -- { dx, dy } normalizado, -1..1
	Sprite = { name = "Sprite" }, -- { color = {r,g,b,a}, size }
	Controllable = { name = "Controllable" }, -- sem payload; so marca a entidade do jogador
	Solid = { name = "Solid" }, -- sem payload; bloqueia movimento (ver movement_system.lua)
}
