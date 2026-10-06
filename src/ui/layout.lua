-- Layout minimo tipo flex: funcoes puras que recalculam x/y/width/height
-- dos filhos de um elemento com base no retangulo (ja definido) do proprio
-- elemento. Chamado explicitamente (ex: depois de add_child ou num
-- resize) -- nao ha um "layout pass" automatico todo frame, porque nenhum
-- caso de uso real pediu isso ainda (YAGNI). Substitui a matematica de
-- offset escrita a mao no protótipo (ex: `- 12 - 16 - 16 - 16`).
local Layout = {}

---@param element Element
---@param opts { padding: number|nil, gap: number|nil }|nil
function Layout.row(element, opts)
	opts = opts or {}
	local padding = opts.padding or 0
	local gap = opts.gap or 0
	local children = element.children
	local n = #children
	if n == 0 then
		return
	end

	local inner_w = element.width - padding * 2 - gap * (n - 1)
	local child_w = inner_w / n
	local x = element.x + padding

	for _, child in ipairs(children) do
		child.x = x
		child.y = element.y + padding
		child.width = child_w
		child.height = element.height - padding * 2
		child:mark_dirty()
		x = x + child_w + gap
	end
end

---@param element Element
---@param opts { padding: number|nil, gap: number|nil }|nil
function Layout.column(element, opts)
	opts = opts or {}
	local padding = opts.padding or 0
	local gap = opts.gap or 0
	local children = element.children
	local n = #children
	if n == 0 then
		return
	end

	local inner_h = element.height - padding * 2 - gap * (n - 1)
	local child_h = inner_h / n
	local y = element.y + padding

	for _, child in ipairs(children) do
		child.x = element.x + padding
		child.y = y
		child.width = element.width - padding * 2
		child.height = child_h
		child:mark_dirty()
		y = y + child_h + gap
	end
end

---Preenche o elemento pai por completo (menos padding), pra todos os
---filhos sobrepostos -- util pra um unico filho de conteudo.
---
---Se o filho e ele mesmo um container de layout (Row/Column -- ver
---src/ui/components/row.lua e column.lua), chama `child:relayout()` depois
---de redimensionar: um Row/Column so sabe o proprio tamanho real quando o
---PAI (aqui) o posiciona -- se ninguem chamar relayout() de novo depois
---disso, os NETOS (ex: os Text de dentro de um painel Column) ficam presos
---no tamanho (as vezes negativo/zero) calculado em add_child, quando o
---container ainda tinha width/height = 0.
---@param element Element
---@param opts { padding: number|nil }|nil
function Layout.fill(element, opts)
	opts = opts or {}
	local padding = opts.padding or 0
	for _, child in ipairs(element.children) do
		child.x = element.x + padding
		child.y = element.y + padding
		child.width = element.width - padding * 2
		child.height = element.height - padding * 2
		child:mark_dirty()
		if child.relayout then
			child:relayout()
		end
	end
end

return Layout
