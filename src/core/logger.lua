local Class = require("src.class")

-- Logger de arquivo: grava eventos do EditorModule/GameModules (e erros
-- fatais do Lua, via love.errorhandler em main.lua) num arquivo real em
-- disco -- da pra acompanhar com `tail -f` enquanto o app roda, sem
-- precisar anexar um debugger.
--
-- Usa love.filesystem em vez de io.open direto porque o cwd de `love .`
-- nao e garantido ser a pasta do projeto -- o caminho real em disco
-- (Logger:path()) e sempre determinado pela sandbox de saves do LOVE
-- (t.identity em conf.lua), nao pelo cwd de quem rodou o comando.

---@class Logger : Class
local Logger = Class.new()

local LOG_FILENAME = "logs/app.log"

function Logger:init()
	self.file = nil
	self.filename = LOG_FILENAME
end

---Abre (ou cria) o arquivo de log em modo append. Chamar uma vez, em
---love.load, depois que love.filesystem ja esta disponivel.
function Logger:start()
	love.filesystem.createDirectory("logs")

	self.file = love.filesystem.newFile(self.filename)
	local ok, err = self.file:open("a")
	if not ok then
		print("Logger: falha ao abrir arquivo de log: " .. tostring(err))
		self.file = nil
		return
	end

	print("Logger: gravando em " .. self:path())
	self:write("info", "app", "== sessao iniciada ==")
end

function Logger:_timestamp()
	return os.date("%Y-%m-%d %H:%M:%S")
end

---@param level "info"|"warn"|"error"
---@param source string  -- "editor", "game.bomberman", "ecs", "fatal", etc
---@param message string
function Logger:write(level, source, message)
	local line = string.format("[%s] [%s] [%s] %s\n", self:_timestamp(), level:upper(), source, tostring(message))

	if self.file then
		self.file:write(line)
		self.file:flush() -- sem isso, `tail -f` so veria o conteudo depois do :close()
	end

	io.write(line) -- espelha no console (t.console = true em conf.lua)
end

---@param source string
---@param message string
function Logger:info(source, message)
	self:write("info", source, message)
end

---@param source string
---@param message string
function Logger:warn(source, message)
	self:write("warn", source, message)
end

---@param source string
---@param message string
function Logger:error(source, message)
	self:write("error", source, message)
end

---Caminho absoluto real do arquivo de log -- use com `tail -f "<path>"`.
function Logger:path()
	return love.filesystem.getSaveDirectory() .. "/" .. self.filename
end

---Chamar em love.quit() pra garantir que o arquivo fecha de forma limpa.
function Logger:stop()
	if self.file then
		self:write("info", "app", "== sessao encerrada ==")
		self.file:close()
		self.file = nil
	end
end

return Logger
