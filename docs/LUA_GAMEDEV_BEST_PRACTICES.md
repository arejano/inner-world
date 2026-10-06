# Lua & LÖVE2D — Boas Práticas (Performance e Qualidade de Código)

## 0. A pegadinha mais importante: LuaJIT ≠ Lua "normal"

O LÖVE2D embute **LuaJIT**, que implementa a semântica do **Lua 5.1** (mais
algumas extensões: `goto`/labels do 5.2, a lib `bit.*`, FFI). O interpretador
`lua` instalado no sistema (via scoop, Lua 5.4/5.5) é útil pra rodar scripts
avulsos e testar snippets, **mas não é o que roda o seu jogo** — e tem
diferenças de sintaxe que quebram dentro do LÖVE:

| Recurso | Lua 5.3+ | LuaJIT (LÖVE) |
|---|---|---|
| Divisão inteira `a // b` | sintaxe válida | **erro de sintaxe** — use `math.floor(a / b)` |
| Bitwise `a & b`, `a \| b`, `~a` | sintaxe válida | **erro de sintaxe** — use `bit.band(a, b)`, `bit.bor`, `bit.bnot` |
| Inteiros nativos (subtype) | sim | não — todo número é double (igual Lua 5.1) |
| `goto`/labels | sim | sim (backport) |

Se você copiar um snippet de "Lua moderno" da internet e ele usar `//` ou
`&`/`\|` em número, ele **não vai rodar dentro do LÖVE** — só no `lua.exe` do
sistema. Fique atento à origem do exemplo.

---

## 1. Performance em Lua

### 1.1 `local` é mais rápido que global — sempre

Acesso a variável `local` é leitura de registrador/upvalue. Acesso a
variável global é uma busca em tabela (`_G["nome"]`). Em código que roda
todo frame (`love.update`, `love.draw`), isso soma.

```lua
-- ruim: math.sin é resolvido via _G -> table "math" -> campo "sin", toda chamada
function update_wave(t)
    return math.sin(t) * 10
end

-- bom: resolvido uma vez, reusado como upvalue
local sin = math.sin
local function update_wave(t)
    return sin(t) * 10
end
```

Vale o mesmo pra qualquer função de lib usada em loop quente: `math.floor`,
`table.insert`, `string.format`, etc. Cache no topo do módulo.

### 1.2 Não aloque no hot path

`love.update` e `love.draw` rodam ~60x/s. Toda tabela, closure ou string
nova criada ali é lixo que o GC vai ter que coletar — e picos de coleta
aparecem como stutter visível.

```lua
-- ruim: cria uma tabela nova TODO frame
function love.draw()
    local color = { 1, 0, 0 }
    love.graphics.setColor(color[1], color[2], color[3])
    ...
end

-- bom: a tabela existe uma vez só
local RED = { 1, 0, 0 }
function love.draw()
    love.graphics.setColor(RED[1], RED[2], RED[3])
    ...
end
```

O mesmo vale pra closures (`function() ... end` criada dentro de `update`),
`string.format` pra montar texto que não mudou, e `love.graphics.newFont`/
`newImage` chamados fora do `load()` (ver `src/assets.lua` no template —
cache tudo que for carregado de disco).

### 1.3 Concatenação de string em loop é O(n²)

Strings em Lua são imutáveis: `a .. b` sempre aloca uma string nova. Montar
uma string grande concatenando em loop realoca a cada iteração.

```lua
-- ruim: N alocações, cada uma maior que a anterior
local s = ""
for i = 1, 1000 do
    s = s .. tostring(i) .. ","
end

-- bom: table.concat aloca uma vez no final
local parts = {}
for i = 1, 1000 do
    parts[#parts + 1] = tostring(i)
end
local s = table.concat(parts, ",")
```

### 1.4 `for` numérico > `ipairs` > `pairs`, nessa ordem, em loop quente

- `for i = 1, #t do` — mais rápido, sem overhead de chamada de função por item.
- `ipairs(t)` — mais legível, overhead pequeno de iterador.
- `pairs(t)` — único jeito de iterar a parte *hash* de uma tabela, mas é o
  mais lento e **não garante ordem**. Não use em array se não precisar das
  chaves não-numéricas.

Pra listas puras (ex: lista de inimigos, partículas), prefira `for i = 1, #t`.

### 1.5 Evite `pcall`/`xpcall` em loop quente

`pcall` tem overhead de call frame protegida e historicamente atrapalha
otimização do JIT. Use pra erros *excepcionais* (carregar arquivo, parsear
save), nunca pra controle de fluxo normal de todo frame.

### 1.6 GC: ajuste se sentir stutter

O LÖVE 11.x usa o GC incremental padrão do Lua. Em jogos com muita alocação
transitória (partículas, efeitos), dois ajustes ajudam:

```lua
-- no love.load(), uma vez:
collectgarbage("incremental", 100, 1000, 10) -- pause, stepmul, stepsize (tunar empiricamente)

-- alternativa: modo generational, melhor quando a maioria dos objetos
-- morre jovem (muito comum em gamedev: partículas, projéteis)
collectgarbage("generational")
```

Mas o ajuste de GC é o **último** recurso — resolve sintoma. Primeiro ataque
a causa (1.2: pare de alocar no hot path).

### 1.7 Pool de objetos pra coisas de ciclo de vida curto

Balas, partículas, popups de dano: em vez de `table.remove` + criar
`{}` novo a cada spawn, mantenha um pool de tabelas inativas e reative.

```lua
local pool = {}

local function spawn_bullet(x, y)
    local b = table.remove(pool) or {}
    b.x, b.y, b.active = x, y, true
    return b
end

local function despawn_bullet(b)
    b.active = false
    pool[#pool + 1] = b
end
```

Só vale a complexidade quando o profiler mostrar que o GC de fato é gargalo
— não otimize isso prematuramente num jogo pequeno (ver seção 4.9 sobre
YAGNI).

---

## 2. Qualidade de código em Lua

### 2.1 Sempre declare `local`

Esquecer `local` cria uma global silenciosamente — sem erro, sem warning do
interpretador. É a fonte nº1 de bug bobo em Lua (typo em nome de variável
vira uma global nova em vez de erro).

```lua
function update_player(dt)
    speed = 300 -- esqueceu "local" -> vaza pra _G, outro arquivo pode colidir
    player.x = player.x + speed * dt
end
```

O `.luacheckrc` do template já pega isso (`luacheck .` acusa global
implícita). O `lua-language-server` também sinaliza no editor em tempo real.

### 2.2 Convenção de nomes

- `snake_case` — variáveis e funções: `player_speed`, `update_enemies()`
- `PascalCase` — módulos que funcionam como "tipo"/classe: `Player`, `Gamestate`
- `UPPER_SNAKE_CASE` — constantes: `MAX_HEALTH`, `TILE_SIZE`

Consistência importa mais que a convenção específica — escolha uma e não
troque no meio do projeto.

### 2.3 Um arquivo = um módulo = uma tabela retornada

```lua
-- src/enemy.lua
local Enemy = {}
-- ... define Enemy.new, Enemy.update, etc

return Enemy
```

Nunca dependa de ordem de `require` pra inicialização — cada módulo deve
funcionar standalone assim que é requerido. Efeitos colaterais (tocar som,
mexer em estado global) pertencem a `love.load()`, não ao topo do módulo.

### 2.4 OOP: escolha um padrão só e seja consistente

Lua não tem classe nativa — todo "sistema de classe" é açúcar sintático
sobre metatables (`__index`). O template traz um (`src/class.lua`, ~20
linhas, com herança via `parent`). Não é a única forma válida, mas escolher
**uma** e aplicar em todo o projeto evita 3 estilos de OOP coexistindo.

Se o projeto crescer e precisar de mais (mixins, interfaces), considere uma
lib madura como [`classic`](https://github.com/rxi/classic) ou
[`middleclass`](https://github.com/kikito/middleclass) em vez de reinventar.

### 2.5 `assert` para bug de programador, `pcall` para erro recuperável

```lua
-- assert: precondição que NUNCA deveria falhar em produção — se falhar, é bug
local function take_damage(entity, amount)
    assert(amount >= 0, "dano nao pode ser negativo")
    entity.hp = entity.hp - amount
end

-- pcall: situação externa que PODE falhar legitimamente (arquivo, rede, save corrompido)
local ok, data = pcall(love.filesystem.read, "save.json")
if not ok then
    -- trata ausência/corrupção do save sem derrubar o jogo
end
```

Nunca engula um erro silenciosamente (`pcall` descartando o retorno de
erro) — pelo menos logue.

### 2.6 Anotações EmmyLua pro language server

O `lua-language-server` entende comentários `---@param`/`---@return`/`---@class`
e usa isso pra autocomplete, hover docs e checagem de tipo leve — sem
precisar de um sistema de tipos real.

```lua
---Aplica dano a uma entidade, limitado a 0 de HP.
---@param entity table
---@param amount number
function take_damage(entity, amount)
    ...
end
```

Vale a pena em módulos "de API pública" (ex: `src/class.lua`, `src/assets.lua`)
e não vale muito em código bem local/óbvio — não anote tudo por anotar.

### 2.7 Lint e format automatizados (já configurados no template)

```powershell
stylua .      # formata (tabs, config em stylua.toml)
luacheck .    # lint: globals implícitas, var não usada, etc (config em .luacheckrc)
```

Rode os dois antes de commitar. Se o projeto ganhar CI, são os primeiros
dois steps a automatizar.

### 2.8 Sem números mágicos

```lua
-- ruim
if player.hp <= 0 then respawn(player, 3) end

-- bom
local RESPAWN_DELAY_SECONDS = 3
if player.hp <= 0 then respawn(player, RESPAWN_DELAY_SECONDS) end
```

---

## 3. Boas práticas de gamedev no LÖVE2D

### 3.1 `dt` sempre multiplicando movimento

`love.update(dt)` recebe o tempo do frame anterior em segundos. Qualquer
movimento/animação tem que ser `* dt` pra ser independente de framerate.

```lua
-- ruim: velocidade varia com o FPS da máquina
player.x = player.x + 5

-- bom: 300 pixels por segundo, sempre
player.x = player.x + 300 * dt
```

### 3.2 Timestep fixo quando precisar de determinismo

Pra física, replay ou netcode, `dt` variável causa resultados diferentes a
cada rodada. Padrão "accumulator": atualiza a lógica em passos fixos,
renderiza no `dt` real.

```lua
local FIXED_DT = 1 / 60
local accumulator = 0

function love.update(dt)
    accumulator = accumulator + dt
    while accumulator >= FIXED_DT do
        fixed_update(FIXED_DT)
        accumulator = accumulator - FIXED_DT
    end
end
```

Não adicione isso de cara — só quando o jogo realmente precisar de
simulação determinística (ex: física mais séria, replays). Pra maioria dos
jogos 2D simples, `dt` variável direto é suficiente e mais simples.

### 3.3 Pilha de estados em vez de `if/elseif` gigante

Já no template (`src/gamestate.lua`): cada tela (menu, jogo, pause) é um
módulo com seus próprios `update`/`draw`/`keypressed`. Empilhar (`push`) vs
trocar (`switch`) é a diferença entre "pausar por cima" e "sair da tela
anterior".

### 3.4 Input: ação, não tecla

Checar `love.keyboard.isDown("d")` espalhado pelo código == rebind
impossível depois. Centralize em uma tabela ação → teclas (`src/input.lua`
no template) e todo o resto do jogo pergunta `Input.down("move_right")`.

### 3.5 Carregue assets uma vez, reuse

`love.graphics.newImage`/`newFont`/`love.audio.newSource` leem do disco e
alocam GPU/memória. Chamar de novo a cada uso (ex: dentro de `draw`, ou a
cada spawn de inimigo) é desperdício e causa hitches. Centralize num cache
(`src/assets.lua` no template).

Pra save/load, use `love.filesystem` (não `io.open` com caminho absoluto) —
ele já resolve pro diretório correto por SO (`%appdata%` no Windows,
`~/.local/share` no Linux) e respeita a sandbox do LÖVE.

### 3.6 Renderização em lote

- Muitos sprites iguais (partículas, tiles) → `love.graphics.newSpriteBatch`
  ou `love.graphics.newMesh` em vez de um `draw` por sprite.
- Evite trocar shader/blend mode/canvas a cada objeto — agrupe desenhos que
  usam o mesmo estado.
- Prefira um atlas (spritesheet) com `Quad`s a várias texturas pequenas —
  cada bind de textura nova tem custo.

### 3.7 Áudio: preload + `:clone()`

```lua
-- Assets.sound já faz isso no template
local source = love.audio.newSource("sfx/hit.wav", "static")
-- cada :clone() é uma instância independente, pode tocar sobreposta
love.audio.play(source:clone())
```

Use `"static"` pra efeitos curtos (carrega tudo em memória) e `"stream"`
pra música/áudio longo (decodifica sob demanda).

### 3.8 Resolução e câmera

Jogo com resolução fixa de desenho (ex: 320×180) escalado pra janela real
evita reimplementar layout pra cada aspect ratio. Bibliotecas como
[`push`](https://github.com/Ulydev/push) resolvem isso com letterboxing.
Só adote quando o jogo precisar rodar em mais de uma resolução/janela
redimensionável de verdade.

### 3.9 Colisão: comece simples, só troque quando doer

AABB manual (`x1 < x2+w2 and x2 < x1+w1 and ...`) é suficiente pra
protótipos e jogos pequenos com poucas entidades. Se o número de objetos
crescer (checagem par-a-par vira O(n²)):

1. Primeiro, particionamento espacial simples (grid: só testa objetos na
   mesma célula/vizinhas).
2. Se precisar de física de verdade (resposta a colisão, corpos rígidos),
   use `love.physics` (Box2D) em vez de reinventar.
3. Pra 2D sem física completa mas com resolução de colisão decente,
   [`bump.lua`](https://github.com/kikito/bump.lua) é a lib padrão da
   comunidade.

### 3.10 Distribuição

Um `.love` é só um `.zip` com `conf.lua`/`main.lua` na raiz — o `build.ps1`
do template gera isso (`dist/game.love`). Pra um `.exe` standalone no
Windows (sem precisar o usuário ter o LÖVE instalado):

```powershell
copy /b love.exe+dist\game.love dist\MeuJogo.exe
```

(precisa copiar os `.dll` que vêm junto do `love.exe` pra perto do exe
gerado — eles são runtime, não ficam embutidos pelo `cat`).

### 3.11 YAGNI aplicado a gamedev

É muito fácil, no início de um projeto de jogo, começar construindo um
"engine genérico" (sistema de componentes, event bus, state machine
hiper-flexível) antes de ter um jogo de verdade rodando. Prefira:

1. Fazer a mecânica funcionar do jeito mais direto possível.
2. Generalizar **só** quando a segunda necessidade concreta aparecer (não
   na primeira, especulando sobre a terceira).
3. Adicionar lib externa (`bump`, `anim8`, `push`) quando a necessidade for
   real, não "pra garantir" — ver seção "Próximos passos comuns" no README.

---

## 4. Checklist rápido antes de commitar

- [ ] Nenhuma variável global implícita (`luacheck .` limpo)
- [ ] `stylua .` rodado
- [ ] Nada sendo alocado (tabela/closure/font/image) dentro de `update`/`draw` que poderia ser cacheado
- [ ] Todo movimento multiplicado por `dt`
- [ ] Assets carregados via `src/assets.lua`, não `love.graphics.new*` espalhado
- [ ] Teclas checadas via `Input`, não `love.keyboard.isDown` direto no código de gameplay
