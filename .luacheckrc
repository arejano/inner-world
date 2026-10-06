std = "luajit"
globals = { "love" }
max_line_length = 120

-- src/states/*.lua implementam callbacks (enter, leave, update, draw...)
-- que o Gamestate chama via self[name](self, ...); parametros nao usados
-- em alguns deles (ex: dt em telas estaticas) sao esperados, nao bug.
unused_args = false

exclude_files = {
	"assets/*",
}
