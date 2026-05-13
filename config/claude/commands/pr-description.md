---
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*), Bash(git ls-files:*), Bash(mkdir:*), Read, Write
argument-hint: "[branch-base] [-- notas extras]"
description: Gerar arquivo .md com descrição de Pull Request em tmp/
---

## Contexto

- Argumentos recebidos: `$ARGUMENTS`
- Branch atual: !`git branch --show-current`
- Status: !`git status`
- Diff das mudanças ainda não commitadas (staged + unstaged, tracked): !`git diff HEAD`
- Arquivos untracked: !`git ls-files --others --exclude-standard`

## Sua tarefa

1. **Interprete os argumentos recebidos** acima:
   - Se contiver `--`, tudo antes de `--` (com trim de espaços) é a **branch base**; tudo depois são **notas adicionais do usuário**.
   - Se NÃO contiver `--`, todo o conteúdo é a branch base e não há notas.
   - Se a branch base resultar vazia, use `main` como default.

2. **Capture os diffs em relação à branch base** executando via Bash:
   - `git diff <base>...HEAD` — mudanças que a branch adicionou (commits)
   - `git log <base>..HEAD --oneline` — lista de commits

3. **Leia arquivos untracked relevantes** com a tool Read para incluir o conteúdo na descrição.

4. **Escreva o PR** em `tmp/pr-<branch-atual>.md` considerando **todas** as modificações: commits feitos na branch, alterações ainda não commitadas (staged e unstaged) e arquivos untracked. Se houver notas adicionais do usuário, trate como direcionamento prioritário e incorpore na descrição.

## Regras

- Nome do arquivo: `tmp/pr-<nome-da-branch>.md` (use a branch atual capturada acima). Exemplo: `tmp/pr-feat-recurrency-bills.md`.
- Não fazer limitação de tamanho de linha — não quebrar linhas para caber em uma largura específica.
- Escrever em português brasileiro, seguindo o estilo dos PRs anteriores em `tmp/` quando existirem (seções típicas: Contexto, Mudanças, Como testar localmente, Notas para o reviewer).
- **NÃO** fazer commit. **NÃO** abrir PR. **NÃO** dar push. O usuário fará isso manualmente depois.
- Se a pasta `tmp/` não existir, criar antes de escrever o arquivo.
