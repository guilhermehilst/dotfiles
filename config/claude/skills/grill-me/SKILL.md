---
name: grill-me
description: Entrevista incremental e implacável sobre um plano, funcionalidade ou ideia — uma pergunta por vez, com recomendação, explorando o codebase quando possível. Use quando o usuário pedir para "estressar um plano", "sabatinar uma ideia", "questionar uma proposta", ou digitar frases como "grill me sobre X", "me sabatine sobre Y", "estressa esse plano", "questiona essa funcionalidade". Também aciona via /grill-me. Útil antes de começar a implementar uma feature, para elucidar requisitos, dependências de design e edge cases.
user-invocable: true
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash(git:*)
  - Bash(rg:*)
  - Bash(ls:*)
  - Bash(find:*)
  - Agent
---

# /grill-me — Entrevista de estresse de plano

Entreviste o usuário de forma incremental e implacável sobre o tema fornecido até atingirem um entendimento compartilhado. Caminhe por cada ramo da árvore de design, resolvendo dependências entre decisões uma por uma.

## Entrada

O tema vem em uma de duas formas:

- **Referência a arquivo** (`@caminho/doc.md` na mensagem): o conteúdo já está no contexto da conversa. Leia-o cuidadosamente antes da primeira pergunta.
- **Descrição inline**: o usuário descreveu o tema diretamente na mensagem que disparou a skill.

Comece com **uma frase curta** resumindo o que entendeu do tema e qual ramo da árvore você vai atacar primeiro. Depois faça a primeira pergunta.

## Regras de condução

1. **Uma pergunta por vez.** Nunca dispare uma rajada de perguntas. Espere a resposta antes da próxima.

2. **Para cada pergunta, ofereça sua resposta recomendada** com uma justificativa curta (1–2 frases). O usuário pode aceitar, refinar ou rejeitar — mas começa de uma posição concreta, não de um vazio.

3. **Explore o codebase antes de perguntar** sempre que a resposta puder estar nele. Use Read/Grep/Glob/Agent para descobrir convenções, padrões existentes, nomes de arquivos, estruturas de dados, dependências em uso. Só pergunte o que o código não responde. Se durante a entrevista uma pergunta surgir e for respondível por exploração, explore — não pergunte.

4. **Resolva dependências em ordem.** Antes de discutir uma decisão filha ("qual nome da coluna?"), confirme a decisão pai ("vai existir uma nova tabela?"). Não pule níveis da árvore.

5. **Cubra os ramos relevantes** do tema. Adapte ao caso, mas considere: requisitos funcionais, modelagem de dados, contratos de API/interface, fluxos de erro e edge cases, testes, migrações, performance, observabilidade, segurança, UX/copy quando aplicável. Não precisa percorrer todos em ordem fixa.

6. **Mini-recaps periódicos.** A cada 4–6 perguntas, faça um resumo curto (2–3 linhas) das decisões fechadas até ali, antes de avançar. Ajuda o usuário a ver o progresso e detectar inconsistências cedo.

7. **Português brasileiro**, tom direto, sem rodeios. Nada de "ótima pergunta!" ou bajulação. Pergunte como um colega sênior cético que quer entender de verdade.

## Encerramento

A entrevista termina quando o usuário sinalizar ("pronto", "chega", "acho que cobrimos", "ok já tenho o que preciso", etc.).

Ao encerrar, faça um **resumo final curto** (5–10 bullets) das decisões mais importantes fechadas durante a conversa. **Não pergunte** se ele quer um arquivo de saída — apenas entregue o resumo no chat e pergunte quais os próximos passos.
