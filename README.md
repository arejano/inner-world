# Inner World v2

App em LÖVE2D (Lua/LuaJIT) que é, ao mesmo tempo, **Editor + GameEngine +
GameRun** — carrega Módulos (`EditorModule` + `GameModule`s trocáveis em
tempo de execução) que só se comunicam via um `EventBus` central.

Nasceu a partir do [`love2d-template`](../love2d-template) e de uma análise
de arquitetura do protótipo `rox-editor` (ver
[`../love2d-template/project_idea.md`](../love2d-template/project_idea.md)
para o histórico de decisões) — detalhes de implementação ficam em
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Rodando

```powershell
love .
```

## Depurando

Todo evento de lifecycle do editor/jogo (e qualquer erro fatal de Lua) vai
pro mesmo arquivo de log, que dá pra acompanhar em tempo real:

```powershell
tail -f "$env:APPDATA\LOVE\inner-world-v2\logs\app.log"
```

## Estrutura

```
conf.lua / main.lua     -- janela do LOVE + bootstrap
src/
  class.lua             -- OOP minimo (heranca via metatable)
  core/                 -- event_bus, assets, input_map, logger
  ui/                   -- lib de UI retained-mode (dockable panels)
  ecs/                  -- ECS generico (sparse set, command buffer, query real)
  app/                  -- contrato de Module + troca de modulos (ModuleRegistry)
  editor/                -- EditorModule (paineis top/left/main/right/status)
  games/bomberman/        -- GameModule de exemplo minimo
docs/
  ARCHITECTURE.md
  LUA_GAMEDEV_BEST_PRACTICES.md
```

## Tooling

Mesmo setup do template base — `stylua .` (format), `luacheck .` (lint),
`.\build.ps1` (empacota `dist/game.love`).

## Próximos passos

Ver seção 6 de `project_idea.md` no template: comportamentos de UI
adicionais, bombas/paredes no bomberman de exemplo, inspeção de entidades
mais rica no painel direito.
