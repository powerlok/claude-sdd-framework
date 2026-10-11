---
name: bug-diagnosis
description: Método de diagnóstico de defeitos em 5 fases (reproduzir, isolar, hipótese com evidência, correção mínima com teste de regressão, verificar e prevenir). Usar ao investigar falha de teste, defeito reportado, comportamento inesperado ou validação reprovada, em qualquer linguagem. O agente tests usa a fase de reprodução; backend e frontend aplicam todas as fases.
---

# Bug Diagnosis

Regra central: **nenhuma correção sem causa raiz demonstrada por evidência.**
Tentar correções ao acaso esconde o defeito e cria novos.

## Papéis

| Agente | Responsabilidade |
|---|---|
| tests | Fase 1: reprodução determinística, evidência (comando, saída real), relatório do defeito. Não corrige produção. |
| backend / frontend | Fases 2 a 5 na própria área: isolar, diagnosticar, corrigir, teste de regressão. |
| techlead | Recebe escalonamento, registra bloqueio, decide o próximo passo. |

## Fase 1: Reproduzir de forma determinística

- Obter passos exatos, entrada, ambiente, versão e saída esperada vs real.
- Transformar a reprodução em comando ou teste automatizado que falha.
- Controlar fontes de não determinismo: tempo, aleatoriedade (fixar seed),
  ordem de execução, concorrência, rede, estado compartilhado, dados externos.
- Rodar várias vezes: a falha deve ocorrer sempre.
- Falha intermitente: registrar a taxa observada e o que muda entre execuções;
  não tratar como resolvida até ser reproduzível.

Saída: comando de reprodução e saída real (evidência).

## Fase 2: Isolar e minimizar

- Reduzir o caso ao menor input/cenário que ainda falha.
- Delimitar a camada: entrada, regra, persistência, integração, UI.
- Comparar com um caso que funciona e listar as diferenças.
- Verificar mudanças recentes (histórico, dependências, configuração).
- Usar bisseção (no código, nos dados ou no histórico) quando o espaço for grande.

Saída: caso mínimo e local suspeito (`arquivo:linha`).

## Fase 3: Hipótese com evidência

- Formular uma hipótese por vez: "falha porque X, e o sinal é Y".
- Definir antes qual observação confirma ou refuta a hipótese.
- Coletar evidência: logs, asserts, depurador, instrumentação temporária.
- Hipótese refutada: descartar e registrar; não acumular mudanças.
- Seguir o dado até a origem: corrigir onde o valor errado nasce,
  não onde ele explode.

Saída: causa raiz demonstrada (não apenas plausível).

## Fase 4: Correção mínima com teste de regressão

1. Escrever o teste de regressão que reproduz o defeito.
2. Executar: o teste **deve falhar antes** da correção (registrar a saída).
3. Aplicar a menor correção que trata a causa raiz.
4. Executar: o teste **deve passar depois** (registrar a saída).
5. Remover instrumentação temporária.

Não incluir refatorações ou melhorias fora do escopo do defeito;
registrar como observação.

## Fase 5: Verificar e prevenir recorrência

- Rodar a suíte relevante e o build; nenhuma regressão nova.
- Procurar o mesmo padrão de erro em outros pontos e registrar
  (corrigir só se estiver no escopo).
- Avaliar defesa adicional: validação de entrada, invariante, tipo mais estrito,
  mensagem de erro mais clara.
- Registrar evidências: causa raiz, arquivos alterados, comandos, resultados.

## Parada e escalonamento

- Contar as tentativas de correção para a mesma falha.
- **3 tentativas sem progresso significativo**: parar.
- Escalar ao techlead com:
  - reprodução (comando e saída);
  - hipóteses testadas e resultado de cada uma;
  - o que se sabe e o que falta saber;
  - sugestão de próximo passo (revisão de design, outro agente, decisão do usuário).
- Três correções falhas seguidas costumam indicar problema de design,
  não de implementação.

## Sinais de alerta

- "Deve ser isso" sem evidência.
- Corrigir antes de reproduzir.
- Várias mudanças simultâneas para "ver se resolve".
- Desativar, pular ou afrouxar teste para passar.
- Aumentar timeouts/retries sem entender a causa.

Nunca mascarar falhas: reportar comando executado, resultado real e evidência.

---

Texto próprio; inspirado em obra/superpowers@8ca22db (skill `systematic-debugging`) (MIT)
e mattpocock/skills@49dd158 (skill `diagnosing-bugs`) (MIT).
