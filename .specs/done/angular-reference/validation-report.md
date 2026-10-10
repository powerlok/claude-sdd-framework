# Relatório de validação: angular-reference (T-004, GH#1)

| Verificação | Evidência | Status |
|---|---|---|
| REQ-001 seções | react.md -> angular.md: Estrutura -> Estrutura; Componentes e hooks -> Componentes + Templates; Estado -> Estado e reatividade (+ Serviços/DI); Dados remotos -> HTTP; Performance -> Performance; Testes -> Testes; Build e validação -> "Build, lint e validação". Extras: versão, roteamento, formulários, SSR, segurança, a11y, armadilhas | VALIDADO |
| REQ-001 sem URLs no corpo | `grep https?://` só nas linhas 236-238 (rodapé "Fontes e atribuição") | VALIDADO |
| REQ-001 tamanho (<= ~220) | 242 linhas (observação: ~10% acima do alvo aproximado) | VALIDADO (ressalva) |
| REQ-002 | SKILL.md:20 linha "Angular \| references/angular.md"; grep "não disponível\|ainda não" em plugins/sdd: única ocorrência é agents/tecleader.md:43 (não relacionada a Angular) | VALIDADO |
| REQ-003 | `plugin validate` em plugins/sdd e na raiz: "Validation passed" (ambos) | VALIDADO |
| REQ-004 Read | stream-json: 1 tool_use (Read), a 1a chamada, em `.../plugins/sdd/skills/frontend-engineering/references/angular.md` (caminho do plugin, não cache) | VALIDADO |
| REQ-004 conteúdo | "não escrevo `standalone: true`"; "zoneless é o padrão"; "Declaro OnPush explicitamente, porque ser o padrão só vale a partir da v22"; "`@for` usa `track task.id`"; Vitest/`ng test`; "Não uso `@Service()`, `httpResource` nem Signal Forms (v22)"; caminho exato citado | VALIDADO |
| Higiene | run.jsonl e err.txt removidos de P | VALIDADO |

Observações: aviso de conectores MCP não autorizados na saída (irrelevante). REQ-005 (security) fora do escopo desta validação.
