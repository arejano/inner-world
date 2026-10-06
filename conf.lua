function love.conf(t)
	t.identity = "inner-world-v2" -- pasta em %appdata%\LOVE para saves (love.filesystem)
	t.version = "11.5"
	t.console = true -- mostra print() no terminal quando roda via `love .` (Windows)

	t.window.title = "Inner World v2"
	t.window.width = 1280
	t.window.height = 720
	t.window.resizable = true
	t.window.vsync = 1

	-- Desliga modulos que o app nao usa = menos overhead de inicializacao.
	t.modules.joystick = false
	t.modules.physics = false
end
