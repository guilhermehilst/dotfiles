---
name: write-prd
description: Transforma a conversa atual em um PRD (Product Requirements Document) em PT-BR, explorando o codebase para enriquecer seções técnicas. Use quando o usuário pedir para "gerar um PRD", "escrever um PRD", "documentar como PRD", "transformar isso em PRD", "criar requisitos do produto", ou digitar /write-prd. Útil ao final de uma discussão de feature, antes da implementação começar.
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Grep
  - Glob
  - Bash(git:*)
  - Bash(gh:*)
  - Bash(rg:*)
  - Bash(ls:*)
  - Bash(find:*)
  - Bash(mkdir:*)
  - Bash(mktemp:*)
  - Bash(rm:*)
  - Bash(date:*)
  - Agent
  - AskUserQuestion
---

# /write-prd — Geração de PRD a partir da conversa

Transforma a conversa atual em um Product Requirements Document estruturado, usando o codebase como evidência para informar as seções técnicas. O PRD é descritivo de **intenção** — não substitui o código, mas define o contrato do que será construído.

**A skill não entrevista o usuário sobre o conteúdo do PRD.** Trabalha estritamente com o que já está na conversa e no codebase. Se uma seção do template não tem suporte suficiente, ela é marcada como "A definir" no PRD — nunca perguntada de volta. As únicas interações com o usuário são operacionais (escolher destino do arquivo e confirmar criação de issue no GitHub).

## Entrada

- **Fonte primária**: toda a conversa atual com o usuário, do início até o turno em que a skill foi invocada.
- **Fonte secundária**: o codebase no diretório de trabalho.
- **Argumento opcional**: o usuário pode invocar com um foco curto (ex: `/write-prd autenticação SSO`). Use isso para guiar a exploração e o título do PRD, mas não trate como substituto da conversa.

## Passo 1: Mapear o que já está na conversa

Antes de explorar o codebase, faça um inventário do que a conversa já forneceu:

- Qual é o problema? Quem sofre com ele?
- Qual é a solução proposta? Está clara ou ainda está em formação?
- Que módulos, arquivos, fluxos ou componentes foram mencionados?
- Que decisões já foram tomadas explicitamente?
- Que restrições apareceram (performance, segurança, prazos, dependências)?
- Houve protótipos ou snippets que codificam decisões com precisão (state machine, schema, tipo)?

Esse inventário é o seu ponto de partida. A exploração do codebase (Passo 2) serve para **complementar** com evidência técnica, não para refazer o que a conversa já cobriu. Seções do template sem suporte suficiente serão marcadas como "A definir" no PRD final — você não pergunta ao usuário.

## Passo 2: Explorar o codebase

Sempre dispare exploração — mesmo que a conversa pareça completa. O codebase costuma ter padrões e prior art que enriquecem especialmente as seções **Decisões de Implementação** e **Decisões de Testes**.

Lance um `Agent` (ou até dois em paralelo) com `subagent_type=Explore` para:

- Localizar módulos relacionados ao escopo da feature
- Identificar prior art de testes similares (frameworks usados, estilo, fixtures)
- Mapear interfaces, contratos ou schemas públicos que serão afetados
- Encontrar convenções relevantes (logging, error handling, naming) que a feature deve seguir

**Importante**: instrua o subagent explicitamente a **não retornar caminhos de arquivo** para inclusão direta no PRD — o template proíbe. O subagent deve relatar a evidência em prosa ("o módulo de autenticação usa middleware X com padrão Y") para você usar como insumo, não como conteúdo literal.

## Passo 3: Gerar o PRD

Monte o PRD em memória (ainda não persista) seguindo **exatamente** este template em PT-BR:

```
# PRD: <título curto da feature>

## 📋 Declaração do Problema

## 💡 Solução

## 👥 Histórias de Usuário

## 🔨 Decisões de Implementação

## 🧪 Decisões de Testes

## 🚫 Fora de Escopo

## 📝 Notas Adicionais
```

Os emojis nos headers são **fixos por seção** — use exatamente os do template acima, na mesma ordem, sem variações. Isso garante consistência entre PRDs gerados em momentos diferentes e facilita navegar múltiplos documentos.

### Regras de conteúdo por seção

**Declaração do Problema** — descreva o problema do ponto de vista do usuário. O que ele não consegue fazer hoje? Que dor ele sente? Evite descrever a ausência da solução ("não temos X") — descreva a dor que justifica a solução.

**Solução** — descreva a solução também do ponto de vista do usuário. O que ele passará a conseguir fazer? Como a experiência muda? Mantém alto nível — implementação vem depois.

**Histórias de Usuário** — lista **longa** e numerada. Use o formato:

> Como um \<persona\>, quero \<ação\>, para que \<benefício\>.

Cubra:
- O golden path (fluxo principal)
- Casos alternativos (variações legítimas do fluxo)
- Casos de erro e recuperação
- Casos de borda relevantes
- Múltiplas personas, quando aplicável

Se em dúvida entre incluir ou não uma história, **inclua** — esta seção deve ser exaustiva.

**Decisões de Implementação** — prosa descrevendo:
- Que módulos serão modificados ou criados (descritos por papel, não por caminho de arquivo)
- Interfaces que serão alteradas (por contrato, não por assinatura literal)
- Decisões arquiteturais
- Mudanças de schema, contratos de API, eventos
- Interações específicas entre componentes

**Não inclua caminhos de arquivo nem snippets de código** — eles ficam desatualizados rápido. **Exceção**: se um protótipo discutido na conversa produziu um snippet que codifica uma decisão com mais precisão do que prosa (state machine, reducer, schema, tipo), inclua o snippet inline e marque com nota curta de que veio de protótipo. Apare o snippet para o essencial — não é demo funcional, é evidência da decisão.

**Decisões de Testes** — descreva:
- O que faz um bom teste neste contexto: foco em comportamento externo, não em detalhes de implementação
- Quais módulos/comportamentos serão testados
- Prior art encontrada no codebase (em prosa: "seguimos o padrão usado em testes de X", sem citar caminhos)
- Tipos de teste planejados e por quê

**Fora de Escopo** — lista explícita do que **não** está incluso neste PRD. Itens que apareceram na conversa mas foram adiados, sub-features deliberadamente cortadas, integrações futuras. Esta seção evita ambiguidade depois. Use `❌` no início de cada item para reforçar visualmente que é exclusão.

**Notas Adicionais** — qualquer contexto extra: dúvidas em aberto, links para outras discussões, riscos identificados, dependências externas, observações que não couberam acima. Use `⚠️` para itens de risco ou dependência crítica quando agregar clareza.

## Passo 4: Decidir o destino

Depois que o PRD está pronto, use `AskUserQuestion` com **4 opções**:

1. **Salvar em `tmp/prd-<slug>.md`** (recomendado) — o slug é um kebab-case curto derivado do título da feature (ex: `tmp/prd-autenticacao-sso.md`). Marque esta opção como "(Recomendado)".
2. **Salvar em caminho customizado** — se escolhida, faça uma segunda pergunta (texto livre via "Other") perguntando o caminho exato.
3. **Apenas exibir na conversa** — não cria arquivo. Imprima o PRD inteiro como markdown na resposta final, o usuário copia se quiser.
4. **Criar issue no GitHub** — abre uma issue no repo atual com o PRD inteiro como corpo. Não salva arquivo local.

Ao salvar como arquivo (opções 1 e 2), garanta que o diretório pai existe (`mkdir -p` quando necessário) antes do `Write`.

### Sub-fluxo da opção 4 (criar issue no GitHub)

Se o usuário escolheu criar issue, siga este fluxo:

**a) Verificar pré-requisitos.** Rode:

- `gh auth status` — confirma autenticação
- `gh repo view --json nameWithOwner -q .nameWithOwner` — confirma que o diretório é repo GitHub e captura o `owner/repo` de destino

Se qualquer um falhar, mostre uma mensagem clara explicando o que falta (`gh` não instalado / `gh auth login` necessário / diretório não é repo GitHub) e **ofereça fallback**: pergunte se quer salvar em `tmp/prd-<slug>.md` (opção 1) para não perder o PRD. Nunca aborte sem oferecer o fallback.

**b) Montar e exibir preview.** Imprima ao usuário:

- Título proposto: `PRD: <título da feature>`
- Repo destino: `<owner/repo>` do passo anterior
- Primeiras ~20 linhas do body (o markdown do PRD)

**c) Pedir confirmação.** Use `AskUserQuestion` com 2 opções: "Criar agora" e "Cancelar".

- Se **Cancelar**: volte ao menu de 4 opções do Passo 4. Nenhuma issue é criada.
- Se **Criar agora**: prossiga.

**d) Criar a issue.** Escreva o markdown do PRD em arquivo temporário e use `--body-file` para evitar problemas de escape:

```
TMP=$(mktemp -t prd-issue.XXXXXX.md)
# escreve o PRD em $TMP via Write tool
gh issue create --title "PRD: <título>" --body-file "$TMP"
rm -f "$TMP"
```

Capture a URL retornada pelo `gh issue create` e imprima ao usuário para ele clicar.

**e) Não salve cópia local nesta opção.** O conteúdo vive só na issue.

## Regras de estilo

- **PT-BR em todo o output** — tanto na sua comunicação com o usuário quanto no conteúdo do PRD.
- **Tom direto, sem bajulação**. Nada de "ótima pergunta!", "excelente ideia!". Vá direto ao ponto.
- **Emojis estratégicos OK** — use para servir escaneabilidade e marcação semântica, não para decoração. Lugares apropriados: (1) headers das 7 seções do template (um emoji por seção, fixo conforme o template — não inventar variações); (2) marcadores funcionais em listas (✅ feito/incluso, ❌ excluído, ⚠️ risco/dependência crítica). Não espalhe emojis no meio de prosa, não use múltiplos emojis seguidos, não use emojis aleatórios decorativos.
- **Não invente detalhes técnicos** que não aparecem na conversa nem no codebase. Se uma seção ficou sem evidência suficiente, escreva "A definir" e indique brevemente o que está faltando — não preencha com suposições.
- **Não entreviste o usuário sobre o conteúdo do PRD.** Nada de "qual o critério de aceitação?", "quais personas?", "qual o escopo de testes?". Se a conversa não cobriu, marque "A definir". As únicas perguntas permitidas são operacionais: destino do arquivo (Passo 4) e confirmação de criação de issue.
- **O PRD descreve intenção, não implementação detalhada**. Caminhos de arquivo, números de linha e snippets de código não entram (exceto a exceção do protótipo na seção de Decisões de Implementação).
- **Resista à tentação de expandir o escopo**. Se algo apareceu na conversa mas foi descartado, ele vai para "Fora de Escopo", não some.
- **Nunca execute `gh issue create` sem preview e confirmação explícita do usuário**. Criar issue é ação remota visível para o time — merece o passo extra. Se um pré-requisito falhar (`gh` ausente, sem auth, sem remote GitHub), não destrua o PRD gerado: ofereça fallback de salvar em `tmp/`.
