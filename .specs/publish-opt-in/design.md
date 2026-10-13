# Design: publish-opt-in

1. **Arquivos**: `templates/project-settings.publicacao.json` = `{ "permissions": { "deny": [<grupo publicação>] } }`.
   Os dois modelos de settings perdem esses itens. `ask` do modelo (git push/commit/...) não muda.
2. **Por que `settings.local.json`**: `deny` vence `allow`/`ask` em qualquer escopo; para a escolha ser por usuário, o
   grupo não pode estar no `settings.json` versionado. O arquivo local já é não rastreado/excluído pelo onboarding
   (regra `/.claude/settings.local.json` em `info/exclude`).
3. **Estados** (lido de `permissions.deny`/`permissions.ask` do `settings.local.json`, JSON como dado):
   `bloqueada` (grupo todo em deny), `confirmar` (grupo todo em ask), `sem decisão` (em nenhum), `inconsistente`
   (parcial ou nas duas chaves → tratar como `bloqueada`, avisar em 1 linha, corrigir no plano com confirmação).
4. **Fluxo do TechLead**: ler o estado só ao receber pedido de publicação (não a cada sessão). `confirmar` → fluxo de
   REQ-004. Demais → não publica; entrega texto do PR; oferece decisão.
5. **Comando `/sdd:publish`**: `disable-model-invocation: true`, `allowed-tools: Read, Edit`; valida o argumento
   (`bloqueada|confirmar`), recusa se `settings.local.json` rastreado (`git ls-files` não é permitido à skill: orientar
   o TechLead), edita só as chaves `deny`/`ask`; nunca toca `allow`.
6. **Migração (0.9.1 → 0.9.2)**: projeto com o `settings.json` antigo (publicação no deny) continua bloqueado; para
   escolher, o usuário remove o grupo do deny versionado (o TechLead propõe no plano) e roda o onboarding da pergunta.
