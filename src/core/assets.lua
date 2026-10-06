-- Cache central de assets: cada imagem/fonte/som e carregado do disco uma
-- unica vez e reusado. Chamar love.graphics.newImage repetido (ex: dentro
-- de draw ou a cada spawn de entidade) recarrega do disco e gera lixo pro GC.
--
-- Diferente do template base, aqui e uma instancia (Assets.new()) em vez de
-- modulo-tabela-global: cada modulo recebe a instancia via AppContext, sem
-- depender de um global compartilhado.
local Class = require("src.class")

---@class Assets : Class
local Assets = Class.new()

function Assets:init()
	self.images = {}
	self.fonts = {}
	self.sounds = {}
end

function Assets:image(path)
	if not self.images[path] then
		self.images[path] = love.graphics.newImage(path)
	end
	return self.images[path]
end

function Assets:font(path, size)
	local key = path .. ":" .. size
	if not self.fonts[key] then
		self.fonts[key] = love.graphics.newFont(path, size)
	end
	return self.fonts[key]
end

---Som: cada chamada devolve uma *instancia* nova via :clone(), assim dois
---efeitos iguais podem tocar sobrepostos sem cortar um ao outro.
function Assets:sound(path, kind)
	if not self.sounds[path] then
		self.sounds[path] = love.audio.newSource(path, kind or "static")
	end
	return self.sounds[path]:clone()
end

return Assets
