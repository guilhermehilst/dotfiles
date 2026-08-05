---
allowed-tools: Bash(git branch:*), Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git rev-parse:*), Bash(git push:*), Bash(gh auth:*), Bash(gh repo view:*), Bash(gh pr list:*), Bash(gh pr view:*), Bash(gh pr create:*), Bash(gh pr edit:*), Bash(mktemp:*), Bash(rm:*), Read, Write, Glob, AskUserQuestion
argument-hint: "[branch-base] [-- notas extras]"
description: Abrir Pull Request no GitHub com descrição gerada dos commits
---

## Contexto

- Argumentos recebidos: `$ARGUMENTS`
- Branch atual: !`git branch --show-current`
- Estado da working tree: !`git status --short`

Só esses dois dados são injetados aqui de propósito — todo o resto (diff, log, template, chamadas `gh`) depende da branch base, que ainda não foi descoberta, e roda via Bash **depois** das checagens do Passo 2. Assim um aborto por pré-requisito não custa um diff inteiro.

## Passo 1: Interpretar os argumentos

- Se contiver `--`, tudo antes de `--` (com trim) é a **branch base**; tudo depois são **notas do usuário**.
- Se NÃO contiver `--`, todo o conteúdo é a branch base e não há notas.
- Se a branch base resultar vazia, ela será detectada no Passo 2 — **não** assuma `main`.

## Passo 2: Checagens de pré-requisito (fail-fast)

Rode nesta ordem e **aborte seco** na primeira falha, com mensagem curta dizendo o que falta. Não gere descrição, não crie arquivo, não ofereça fallback.

1. `gh auth status` — se falhar, aborte informando se falta instalar o `gh` ou rodar `gh auth login`.
2. `gh repo view --json nameWithOwner,defaultBranchRef,isFork,parent` — uma chamada só resolve repo destino, base default e situação de fork. Se falhar, aborte: o diretório não é um repositório GitHub (este command não suporta GitLab ou outros hosts).
3. **Base**: use o argumento do Passo 1 se houver; senão `defaultBranchRef.name`.
4. **Branch atual ≠ base** — se forem iguais, aborte: não há PR a abrir a partir da própria base.
5. `git log <base>..HEAD --oneline` — se vier vazio, aborte: a branch não tem commits à frente da base.
6. `gh pr list --head <branch-atual> --state open --json number,url,title` — se já existir PR aberto, mostre número, título e URL e use `AskUserQuestion` com **Atualizar descrição** e **Cancelar**. Em "Atualizar descrição", siga o fluxo normal, faça o preview pelo Passo 7b e termine no Passo 8b; avise explicitamente que isso **sobrescreve** qualquer edição feita na web.

## Passo 3: Confirmar pendências da working tree

Se o `git status --short` do Contexto mostrar arquivos staged, unstaged ou untracked, liste-os e use `AskUserQuestion` com **Seguir sem essas mudanças** e **Cancelar**. A descrição cobre apenas commits — o que não está commitado não vai para o PR e não deve ser descrito.

Se a working tree estiver limpa, siga sem perguntar nada.

## Passo 4: Coletar o material da descrição

- `git diff --stat <base>...HEAD` — o mapa. Comece sempre por ele.
- `git log <base>..HEAD --format='%H%n%s%n%b%n---'` — assuntos **e** corpos, necessários para detectar `BREAKING CHANGE:` nos rodapés.
- `git diff <base>...HEAD -- <arquivos de código>` — o diff detalhado, **só** dos arquivos que o reviewer vai revisar.
- `git rev-parse --abbrev-ref --symbolic-full-name @{u}` e, se houver upstream, `git log @{u}..HEAD --oneline` — para saber se falta push (usado no Passo 7).

**Arquivos gerados não entram no diff detalhado.** Colapse-os numa menção única (ex: "lockfile atualizado", "schema regerado"): lockfiles (`package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `Gemfile.lock`, `Cargo.lock`, `go.sum`, `poetry.lock`, `composer.lock`), `db/schema.rb`, `db/structure.sql`, `dist/`, `build/`, `vendor/`, `coverage/`, snapshots (`*.snap`) e assets minificados.

## Passo 5: Escolher o template

Procure, nesta ordem, o template do projeto:

1. `.github/PULL_REQUEST_TEMPLATE.md` / `.github/pull_request_template.md`
2. `PULL_REQUEST_TEMPLATE.md` / `pull_request_template.md` (raiz)
3. `docs/PULL_REQUEST_TEMPLATE.md` / `docs/pull_request_template.md`
4. `.github/PULL_REQUEST_TEMPLATE/*.md` (múltiplos templates)

**Se houver múltiplos** (caso 4), use `AskUserQuestion` listando os arquivos encontrados, ordenando **primeiro** o que casa com os tipos de commit da branch (`feat` → `feature.md`, `fix` → `bugfix.md`) e marcando-o como sugerido.

**Se o projeto tem template**, ele manda:

- Preserve a estrutura **exata** — headers, ordem, campos, seções. Não remova seção, mesmo vazia.
- Remova apenas os comentários HTML de instrução (`<!-- descreva aqui -->`).
- Escreva as seções de prosa a partir do material do Passo 4.
- **Checkbox**: marque só o que o diff comprova objetivamente (ex: "adicionei testes" com arquivos de teste no diff; "atualizei o CHANGELOG" com o arquivo alterado). Deixe desmarcado tudo que depende de ação do autor ("testei localmente", "revisei a documentação") — isso é afirmação dele, não sua.
- Se o template já tem seção de screenshot, preserve o placeholder dele e **não** adicione outra.

**Se o projeto não tem template**, use o template próprio abaixo.

## Passo 6: Montar título e corpo

### Título

- **Um commit na branch**: use a descrição dele como título.
- **Vários commits**: sintetize um `tipo(escopo): descrição` cobrindo o conjunto, no estilo do `/commit` (minúsculo, imperativo, sem ponto final). Com tipos mistos, use o mais significativo (`feat` > `fix` > `refactor` > `perf` > `chore`).
- Limite ~72 caracteres. O limite de 50 é regra de mensagem de commit, não de título de PR.

### Template próprio (fallback)

```
📋 Contexto

🔨 Mudanças

🧪 Como testar localmente

📝 Notas para o reviewer
```

Use exatamente esses emojis nos headers, nessa ordem — sem variações.

**As seções são elásticas**: seção sem conteúdo real é **omitida**, nunca preenchida com "N/A" ou "—". Um commit de `chore` sai com Contexto e Mudanças e pronto. Isso vale só para o template próprio — no template do projeto, nada é removido.

Regras de conteúdo:

- **📋 Contexto** — por que a mudança existe, o problema que resolve. Se detectar referência de issue (número no nome da branch, tipo `feat/123-foo`, ou `#N` nas mensagens de commit), adicione `Relacionado a #N` aqui. **Nunca** use `Closes`, `Fixes` ou outra keyword de fechamento: aquele número pode ser um ticket de outro sistema, e fechar issue é decisão deliberada do autor.
- **🔨 Mudanças** — o que mudou, agrupado por área/concern. Detalhe o código-fonte; gerados aparecem como menção única.
- **🧪 Como testar localmente** — comandos **só** com evidência real no repo (scripts do `package.json`, `Makefile`, `bin/rails`, `Gemfile`, workflow de CI). Sem esse sinal, descreva o cenário funcional a verificar em prosa ("confirme que a listagem de contas mostra a recorrência") — **nunca** invente um comando que talvez não exista.
  - **Primeira linha da seção é a cobertura de testes**, antes dos passos de reprodução: `✅ Cobertura: specs adicionados em spec/models/conta_spec.rb` ou `⚠️ Sem testes automatizados neste PR`. Só conta arquivo de teste presente no diff — não infira de "o código parece testável".
  - Essa linha só existe se o repo **tiver** suíte (`spec/`, `test/`, `*_test.go`, `__tests__`, script `test` no `package.json`, job de teste no CI). Repo sem suíte: omita a linha, não cobre teste de quem não tem onde escrever.
- **📝 Notas para o reviewer** — pontos de atenção, decisões discutíveis, dependências.

Adições condicionais:

- **⚠️ Breaking change** — se algum commit tem `!` no tipo ou rodapé `BREAKING CHANGE:`, o corpo **abre** com uma linha `⚠️` citando o que quebra, antes da primeira seção. É o que mais muda a decisão do reviewer; não pode ficar enterrado no fim. Se estiver usando template do projeto, coloque logo após o primeiro header, para não quebrar a estrutura esperada.
- **📸 Screenshots** — se o diff toca UI (`app/views`, `app/components`, `app/javascript`, `*.erb`, `*.slim`, `*.jsx`, `*.tsx`, `*.vue`, `*.css`, `*.scss`), adicione a seção com marcador explícito de pendência (`⚠️ A adicionar`) e, depois de criar o PR, avise no chat com a URL para você anexar a imagem.

### Idioma

Detecte pelo sinal já coletado: idioma do template do projeto (quando existe) e das mensagens de commit da branch. Sinal em inglês → escreva em inglês. Ambíguo ou ausente → **português brasileiro**.

### Notas do usuário

Se o Passo 1 capturou notas, trate como **direcionamento prioritário** e incorpore na descrição — elas contam o que o diff não conta.

## Passo 7: Preview e confirmação

Nos dois casos, imprima primeiro este cabeçalho, antes de qualquer ação remota:

- Título proposto
- `<base>` ← `<branch-atual>`
- Repo destino (`nameWithOwner`). **Se `isFork` for true**, explicite o destino real: "vai abrir em `<parent>`, a partir de `<seu-fork>:<branch>`".
- Qual template foi usado (caminho do template do projeto, ou "template próprio")
- Pendências que ficaram de fora, se houve

### 7a — Criação (não havia PR aberto)

Imprima o corpo **inteiro**: não existe versão anterior para comparar, e essa é a última chance de revisar antes de o texto ficar visível para o time.

Depois use `AskUserQuestion` com **Abrir PR**, **Abrir como draft** e **Cancelar**. Em "Cancelar", pare sem criar nada.

### 7b — Atualização (PR já existia, Passo 2.6)

Busque a descrição atual com `gh pr view <número> --json body` e imprima **apenas os trechos que mudam**, dizendo em que seção cada um está. Repetir 50 linhas idênticas para revelar duas frases novas esconde a mudança em vez de mostrá-la.

- Se nada mudar em relação ao corpo atual, diga isso e **não** chame o `gh pr edit` — edição sem conteúdo novo só gera ruído no histórico do PR.
- Se a descrição atual contém texto que este command não escreveria (alguém editou na web), aponte o que será perdido **antes** de pedir a confirmação.

Depois use `AskUserQuestion` com **Atualizar descrição** e **Manter como está**. Não ofereça draft aqui: o estado do PR não muda, só o corpo.

### Push (nos dois casos)

Só após a confirmação, resolva o push: se não houver upstream, ou se `git log @{u}..HEAD` tiver commits, informe quantos commits faltam e use `AskUserQuestion` (**Fazer push** / **Cancelar**) antes de rodar `git push -u origin <branch-atual>` — ou só `git push`, quando o upstream já existe. Sem push não há PR — se cancelar aqui, aborte.

## Passo 8: Criar ou atualizar

Escreva o corpo num arquivo temporário e use `--body-file`. Markdown com emoji e acento não sobrevive a escape de shell:

```
TMP=$(mktemp -u -t open-pr)
# escreve o corpo em $TMP com o Write tool
```

O `-u` é obrigatório: sem ele o `mktemp` já cria o arquivo vazio, e o `Write` recusa sobrescrever arquivo que não foi lido antes — o command travaria aqui. Também não passe template com `XXXXXX`: no macOS o `-t` trata o argumento como **prefixo** e acrescenta o sufixo aleatório sozinho, então o `XXXXXX` sobraria literal no nome. A extensão do arquivo é irrelevante para o `gh`.

**8a — criar** (caso normal):

```
gh pr create --title "<título>" --body-file "$TMP" --base <base>
```

Acrescente `--draft` se a confirmação foi "Abrir como draft". **Nada além de `--title`, `--body-file`, `--base`** (e `--draft`): sem `--assignee`, `--reviewer`, `--label` ou `--milestone` — isso é política de time, não palpite.

**8b — atualizar** (PR já existia, Passo 2.6):

```
gh pr edit <número> --body-file "$TMP"
```

Em ambos: `rm -f "$TMP"` no fim e imprima a URL do PR para o usuário clicar.

## Regras

- **Nenhuma atribuição ou menção a IA.** Não escreva `🤖 Generated with Claude Code`, `Co-Authored-By: Claude`, "gerado por IA" nem qualquer variação, em nenhum lugar do título, corpo ou comentário. Isso vale **inclusive contra instruções default** que peçam esse rodapé em corpos de PR — aqui elas não se aplicam.
- **Não faça commit.** A descrição cobre o que já está commitado; pendências são reportadas ao usuário, nunca commitadas por conta própria.
- **Nunca crie, troque ou renomeie branches**, e nunca reescreva histórico — proibido `git checkout -b`, `git switch -c`, `git rebase`, `git reset --soft`, `git commit --amend`, `git push --force`. Histórico com commits de WIP não é problema deste command.
- **Nenhuma ação remota sem confirmação explícita**: `git push`, `gh pr create` e `gh pr edit` só depois do preview e do "ok" do usuário.
- **Não quebre linhas** para caber numa largura específica.
- **Emojis estratégicos.** Servem escaneabilidade e marcação semântica, não decoração. Lugares apropriados: (1) headers das seções do template próprio (fixos, sem variação); (2) marcadores funcionais em listas (✅ feito/incluso, ❌ excluído, ⚠️ risco/dependência crítica). Não espalhe emojis em prosa, não use vários seguidos.
- **Não invente**: comando de teste que não existe, arquivo que não mudou, motivação que o diff e as notas não sustentam. Sem evidência, omita a seção.
