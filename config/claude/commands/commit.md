---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*)
description: Criar um commit git seguindo Conventional Commits
---

## Contexto

- Status atual do git: !`git status`
- Diff atual (staged e unstaged): !`git diff HEAD`
- Branch atual: !`git branch --show-current`
- Commits recentes: !`git log --oneline -10`

## Sua tarefa

Com base nas alterações acima, crie um único commit git seguindo a especificação
**Conventional Commits 1.0.0** (https://www.conventionalcommits.org/pt-br/v1.0.0/).

## Formato da mensagem

```
<tipo>[escopo opcional]: <descrição>

[corpo opcional]

[rodapé(s) opcional(is)]
```

## Tipos permitidos

- **feat**: nova funcionalidade (correlaciona com MINOR no SemVer)
- **fix**: correção de bug (correlaciona com PATCH no SemVer)
- **docs**: apenas documentação
- **style**: formatação, ponto e vírgula, espaços em branco — sem mudança de lógica
- **refactor**: refatoração sem corrigir bug nem adicionar funcionalidade
- **perf**: melhoria de performance
- **test**: adição ou ajuste de testes
- **build**: mudanças no sistema de build ou dependências externas
- **ci**: mudanças em arquivos de configuração de CI
- **chore**: outras tarefas que não modificam código de produção
- **update**: atualização de versões de bibliotecas e/ou ferramentas utilizadas
- **revert**: reverte um commit anterior

## Diretrizes

- Escreva em **Português Brasileiro** (a menos que seja explicitamente solicitado outro idioma)
- A **descrição** (primeira linha) deve:
  - Estar em letras minúsculas
  - Usar verbo no imperativo ("adiciona", "corrige", "remove" — não "adicionado"/"adicionando")
  - Ter no máximo 50 caracteres (incluindo `tipo(escopo):`)
  - Não terminar com ponto final
- Use **escopo** entre parênteses quando útil para indicar a área afetada (ex: `feat(nvim):`, `fix(git):`, `chore(claude):`)
- Para **breaking changes**, adicione `!` após o tipo/escopo (ex: `feat(api)!:`) e/ou inclua o rodapé `BREAKING CHANGE: <descrição>`
- Deixe uma **linha em branco** antes do corpo
- No **corpo** (opcional), use bullet points (máx. 8–10 linhas) explicando *o que* mudou e *por quê* — não *quem* fez
- **Não inclua** atribuição, co-autoria ou menção a Claude/IA
