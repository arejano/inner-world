# Arquitetura

Referência viva do que está implementado (para a motivação/análise do
protótipo `rox-editor` que levou a estas decisões, ver
`../../love2d-template/project_idea.md`).

## Camadas

```
src/
  class.lua      -- OOP: metatable + heranca. ClassName(...) chama :init(...)
  core/          -- servicos sem saber o que e "editor" ou "jogo"
    event_bus.lua
    assets.lua
    input_map.lua
    logger.lua
  ui/            -- lib de UI retained-mode, sem saber o que e um Module
  ecs/           -- ECS generico, sem depender de LOVE2D
  app/           -- bootstrap + contrato de Module + troca de modulos
  editor/        -- EditorModule
  games/         -- GameModules (bomberman = exemplo minimo)
```

Regra geral: um modulo de app (`editor/`, `games/*`) nunca dá `require` em
outro modulo de app. Só fala com `core/`, `ui/`, `ecs/` e com o
`AppContext` injetado.

## AppContext

Pacote de serviços passado para `Module:init(ctx)`:

```lua
ctx.event_bus       -- src/core/event_bus.lua
ctx.assets          -- src/core/assets.lua
ctx.logger          -- src/core/logger.lua
ctx.ui_manager      -- src/ui/ui_manager.lua
ctx.module_registry -- src/app/module_registry.lua (setado em app.lua)
```

## Contrato de Module

```lua
---@class Module
---@field id string
---@field init fun(self, ctx: AppContext)
---@field update fun(self, dt: number)
---@field draw fun(self)
---@field shutdown fun(self)
```

`src/editor/editor_module.lua` e `src/games/bomberman/bomberman_module.lua`
implementam isso. `src/app/module_registry.lua` é quem chama cada hook —
nunca o contrário.

## EventBus

`ctx.event_bus:on(topic, handler) -> subscription`,
`:emit(topic, payload)`, `:off(subscription)`. Síncrono. Tópicos usados hoje:
`"game:switched"`, `"ui:panel.registered"`.

## Logger

`ctx.logger:info/warn/error(source, message)` grava em
`love.filesystem.getSaveDirectory() .. "/logs/app.log"` (chame
`ctx.logger:path()` para o caminho absoluto) e espelha no console. Dá para
acompanhar com `tail -f` enquanto o app roda. Erros fatais do Lua (qualquer
erro não tratado em `update`/`draw`/etc) também caem aqui, com stack trace,
via `love.errorhandler` em `main.lua`.

## UIManager

Seis regiões fixas: `top`, `left`, `main`, `right`, `status_bottom`, `float`.
Módulos registram painéis com:

```lua
ui_manager:register_panel(module.id, "left", { build = function(ctx) ... return element end }, ctx)
```

`unregister_owner(module.id)` remove tudo que aquele módulo registrou —
chamar em `Module:shutdown`.

Elemento base (`src/ui/element.lua`): retângulo + canvas próprio (pool por
granularidade, não realoca a cada resize) + `dirty` flag. `draw_content`
sempre desenha em coordenadas locais (0,0) — a árvore compõe na tela, não
dentro de canvas uns dos outros. Comportamentos (`src/ui/behaviors/`:
draggable, resizable, clickable, focusable) se anexam via
`element:add_behavior(...)`.

## ECS

`src/ecs/world.lua`: entidade = `{index, generation}`, sparse set por
componente, `World:query(...)` é interseção real (iterador), mudanças
estruturais (`destroy`/`add`/`remove` fora de um `_immediate`) passam pelo
`command_buffer` e só se aplicam em `World:flush()` (chamado no fim de
`World:run(stage, dt)`). Particionamento espacial (`src/ecs/spatial/grid.lua`)
é opt-in, interface genérica `insert/remove/update/query` por `id` + AABB.

## GameModule de exemplo (bomberman)

`src/games/bomberman/`: um jogador controlável + uma entidade parada,
3 sistemas (`input`, `logic`, `render` stages). Prova o acoplamento
Editor↔Game↔ECS↔EventBus sem a complexidade de bombas/paredes — ver
`project_idea.md` seção 6 para o roadmap de onde isso deveria crescer.

## Rodando / depurando

```powershell
love .                                    # roda o app
tail -f "$env:APPDATA\LOVE\inner-world-v2\logs\app.log"   # acompanha o log
```
