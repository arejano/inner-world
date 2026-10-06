local App = require("src.app.app")

function love.load()
	App.load()
end

function love.update(dt)
	App.update(dt)
end

function love.draw()
	App.draw()
end

function love.keypressed(key)
	App.keypressed(key)
end

function love.keyreleased(key)
	App.keyreleased(key)
end

function love.mousepressed(x, y, button)
	App.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
	App.mousereleased(x, y, button)
end

function love.mousemoved(x, y, dx, dy)
	App.mousemoved(x, y, dx, dy)
end

function love.wheelmoved(dx, dy)
	App.wheelmoved(dx, dy)
end

function love.resize(w, h)
	App.resize(w, h)
end

function love.quit()
	App.quit()
end

---Tela de erro customizada: mantem o app abrindo uma janela legivel em vez
---do crash silencioso/traceback cru do terminal. So dispara em erro fatal
---nao tratado (bugs em pcall normal nao passam por aqui). Alem da tela,
---grava mensagem + stack trace no mesmo log de arquivo do editor/jogo
---(src/core/logger.lua) -- assim um erro fatal fica no `tail -f` igual
---qualquer outro evento, nao so na tela que fecha quando o processo cai.
function love.errorhandler(msg)
	msg = tostring(msg)
	local trace = debug.traceback("", 2)

	if App.ctx and App.ctx.logger then
		App.ctx.logger:error("fatal", msg .. "\n" .. trace)
	end

	love.graphics.reset()
	love.graphics.setBackgroundColor(0.15, 0.05, 0.05)
	local font = love.graphics.newFont(14)
	love.graphics.setFont(font)

	return function()
		if love.event then
			love.event.pump()
			for e, a in love.event.poll() do
				if e == "quit" then
					return 1
				end
				if e == "keypressed" and a == "escape" then
					return 1
				end
			end
		end

		love.graphics.clear(love.graphics.getBackgroundColor())
		love.graphics.setColor(1, 1, 1)
		love.graphics.printf("Erro:\n\n" .. msg, 40, 40, love.graphics.getWidth() - 80)
		love.graphics.present()
	end
end
