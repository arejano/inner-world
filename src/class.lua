---@class Class
---@field new fun(...) -- construtor, sobrescreva em cada classe
local Class = {}
Class.__index = Class

---Cria uma nova classe, opcionalmente herdando de `parent`.
---@param parent table|nil
---@return table
function Class.new(parent)
	local cls = setmetatable({}, { __index = parent })
	cls.__index = cls
	cls.super = parent

	setmetatable(cls, {
		__index = parent,
		__call = function(self, ...)
			local instance = setmetatable({}, self)
			if instance.init then
				instance:init(...)
			end
			return instance
		end,
	})

	return cls
end

return Class
