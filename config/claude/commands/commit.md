---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git diff:*), Bash(git reset:*), Bash(git apply:*), Bash(git branch:*), Bash(git log:*)
description: Criar um ou mais commits git seguindo Conventional Commits
---

## Contexto

- Status atual do git: !`git status`
- Diff atual (staged e unstaged): !`git diff HEAD`
- Branch atual: !`git branch --show-current`
- Commits recentes: !`git log --oneline -10`

## Sua tarefa

Analise as alterações acima e decida se elas representam **uma ou várias**
unidades lógicas de mudança. Em seguida crie **um ou mais** commits git seguindo
a especificação **Conventional Commits 1.0.0**
(https://www.conventionalcommits.org/pt-br/v1.0.0/).

## Divisão em commits

- Agrupe o diff por **unidade lógica coesa** (mesmo concern/escopo).
- Se tudo pertencer à mesma unidade → crie **um único commit**.
- Se houver concerns distintos (ex: uma feature + um ajuste de docs não
  relacionado) → **proponha múltiplos commits**, um por unidade lógica.
- **Sempre proponha o plano antes de executar**: para cada commit, liste os
  arquivos/hunks incluídos e a mensagem proposta, e **peça confirmação** ao
  usuário. Só crie os commits, na ordem proposta, após o "ok".

## Staging por hunk

- Quando um arquivo pertence inteiro a um único commit → `git add <arquivo>`
  (caminho preferido).
- Quando um mesmo arquivo tem mudanças de commits diferentes → separe por hunk:
  - Parta de tudo unstaged (`git reset` se algo já estiver staged).
  - Para cada grupo, monte um patch só com os hunks desejados (grave o `.patch`
    em `tmp/` com o Write tool) e aplique com `git apply --cached <patch>` —
    equivalente não-interativo ao `git add -p`.
  - Faça `git commit` do grupo e repita para o próximo.
- Só recorra ao patch por hunk quando houver mistura real de concerns no mesmo
  arquivo; caso contrário, prefira staging por arquivo.

## Branch

- **Sempre faça os commits na branch atual** (a exibida em "Branch atual").
- **Nunca crie, troque ou renomeie branches** — proibido `git checkout -b`,
  `git switch -c`, `git switch <outra>`, `git branch <nova>`.

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

Aplicam-se a **cada** commit criado:

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
