local Element = require("src.ui.element")

-- Viewport do jogo ativo: nao desenha nada por si so (totalmente
-- transparente a hit-test) -- o GameModule ativo desenha direto na tela,
-- usando `ctx.ui_manager.regions.main` como retangulo de destino (ver
-- BombermanModule:update). Isso evita ter que compor o frame do jogo
-- dentro de um canvas de UI por frame.
---@param ctx table AppContext
local function build(ctx)
	local element = Element()
	element.style.bg = nil
	element.hit_transparent = true
	return element
end

return { build = build }
