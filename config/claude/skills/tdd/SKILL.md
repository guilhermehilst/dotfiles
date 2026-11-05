---
name: tdd
description: Use esta skill SEMPRE QUE for implementar uma funcionalidade, corrigir um bug ou alterar o comportamento de código de produção, em qualquer linguagem — pedidos como "implemente X", "adicione suporte a Y", "corrija o bug Z", "crie uma função/método/endpoint", "mude a regra de W". Impõe o ciclo red-green-refactor do Test-Driven Development (um teste por vez, falha vista antes do código), com exceções explícitas para configuração, docs, spikes, estilo/markup, migrations/refactors mecânicos e código gerado. Também aciona via /tdd.
user-invocable: true
allowed-tools:
  - Read
  - Grep
  - Glob
  - Edit
  - Write
  - Bash(bundle exec:*)
  - Bash(bin/rails test:*)
  - Bash(go test:*)
  - Bash(pytest:*)
  - Bash(make test:*)
  - Bash(git diff:*)
  - Bash(git status:*)
---

# /tdd — Test-Driven Development com red-green-refactor

Todo código de produção nasce de um teste que falhou antes. Esta skill governa o **processo** de desenvolvimento e os **princípios** de um bom teste, válidos em qualquer linguagem ([BOAS_PRATICAS.md](BOAS_PRATICAS.md)). O **mecanismo** de cada stack (framework, fixtures, helpers de tempo, organização) vem do projeto ou de skills de domínio (ex.: [rails-puro/TESTING.md](../rails-puro/TESTING.md)).

## Quando NÃO aplicar

TDD não se aplica a:

- **Configuração, docs e dotfiles** — arquivos de config, infra, README, markdown, scripts de setup.
- **Spikes e protótipos** — código explicitamente declarado pelo usuário como exploratório/descartável.
- **Estilo, markup e copy** — CSS, textos, templates/views sem lógica condicional.
- **Migrations e refactor mecânico** — migrations de schema puras; renomeações e moves já cobertos por testes existentes (rode a suíte ao final).
- **Código gerado** — saída de ferramentas (protobuf, clientes OpenAPI, scaffolds de geradores). Testes vão no código que *usa* o gerado.

### Como decidir

- **Exceção clara:** anuncie em uma linha antes de começar — `Sem TDD: <motivo>` — e siga.
- **Caso ambíguo** (ex.: template com `if`, script que virou lógica de negócio): pergunte antes de começar.
- **Override do usuário:** "sem TDD", "pula os testes" ou equivalente desliga a skill **apenas para a tarefa atual**.

## Detectar o runner

1. O comando do projeto tem prioridade: CLAUDE.md, `Makefile` (`make test`), `bin/test`, scripts documentados.
2. Senão, use a tabela:

| Sinal no projeto                          | Comando                  |
|-------------------------------------------|--------------------------|
| `bin/rails` (sem `spec/`)                 | `bin/rails test`         |
| `Gemfile` com `rspec` + diretório `spec/` | `bundle exec rspec`      |
| `go.mod`                                  | `go test ./...`          |
| `pyproject.toml`, `pytest.ini`, `setup.cfg` | `pytest`               |

Em RED e GREEN, rode **só o teste alvo** (arquivo/linha, `-run`, `-k`). Rode a suíte completa ao final.

## Lei de Ferro

```
NENHUM CÓDIGO DE PRODUÇÃO SEM UM TESTE FALHANDO ANTES
```

Escreveu código de produção nesta tarefa antes de ver o RED? **Descarte esse código** e refaça a partir do teste. Não guarde "de referência", não adapte o que já estava escrito enquanto escreve o teste — isso é testar depois, com outro nome.

Vale só para código que **você** escreveu na tarefa atual sem teste. Nunca apague código preexistente do usuário com base nesta regra.

## O ciclo

### 0. Lista de casos

Antes do primeiro teste, liste os casos de teste curtos (comportamentos, não métodos). Inclua caminho feliz, bordas e erros relevantes.

- Tarefa pequena: a lista é informativa — mostre e siga.
- **Mais de ~5 casos ou requisito ambíguo: pare e peça aprovação da lista** antes do primeiro RED.

A lista pode crescer durante o ciclo; anote casos novos em vez de implementá-los de carona.

### 1. RED

- Antes do primeiro teste da tarefa, leia [BOAS_PRATICAS.md](BOAS_PRATICAS.md).
- Escreva **um** teste, para o próximo caso da lista.
- Rode e confirme que **falha pelo motivo certo**: asserção falhando ou método/função inexistente de forma esperada — não erro de sintaxe, import quebrado ou setup errado. Se falhou pelo motivo errado, corrija o teste e rode de novo.
- Se passou de primeira, o teste não prova nada: revise o teste ou o caso.

### 2. GREEN

- Escreva o **mínimo** de código de produção para o teste passar. Nada de generalizar para casos ainda não testados.
- Rode o teste alvo e confirme verde, com saída limpa: sem erros nem warnings novos.
- Falhou? Corrija o código de produção, não o teste.

### 3. REFACTOR

- Só com tudo verde. Remova duplicação, melhore nomes e estrutura — em código de produção e de teste.
- Revise os testes contra [BOAS_PRATICAS.md](BOAS_PRATICAS.md) (ex.: dependência de relógio real, data fixa, ordem, rede).
- Rode os testes de novo. Se nada a melhorar, diga e siga.

Volte ao RED com o próximo caso até esvaziar a lista.

### Proibido

- Escrever código de produção antes de ver o RED.
- Alterar ou enfraquecer um teste para fazê-lo passar.
- Implementar vários casos num único GREEN.

## Racionalizações e red flags

Se você se pegar pensando em qualquer uma destas, pare e volte ao RED:

| Desculpa                                  | Realidade                                                                 |
|-------------------------------------------|---------------------------------------------------------------------------|
| "É simples demais para testar"            | Código simples também quebra; o teste custa segundos.                     |
| "Testo depois"                            | Teste escrito depois passa de primeira e não prova nada.                  |
| "Já testei manualmente"                   | Teste manual não fica registrado nem roda de novo na próxima mudança.     |
| "Apagar o que já escrevi é desperdício"   | Custo afundado. Código sem teste confiável é dívida, não ativo.           |
| "Guardo de referência e escrevo o teste"  | Você vai adaptá-lo — é testar depois. Descarte.                           |
| "Preciso explorar antes"                  | Ok: declare um spike, explore, descarte e recomece pelo teste.            |
| "Este caso é diferente porque…"           | Se não está nas exceções, não é diferente. Na dúvida, pergunte.           |
| "TDD vai atrasar"                         | Depurar depois atrasa mais.                                               |

Sinais de que o ciclo já foi violado: código escrito antes do teste, teste que passou de primeira sem investigação, falha que você não sabe explicar, testes "para depois".

## Correção de bug

Primeiro um teste que **reproduz o bug** e falha (RED). Só então a correção (GREEN). O teste fica como regressão.

## Sem infra ou difícil de testar

- **Projeto sem infraestrutura de teste:** pare e proponha o setup mínimo (runner, primeiro arquivo de teste, comando). **Não instale dependências sem aprovação.**
- **Código difícil de testar** (legado acoplado, I/O, API externa): teste no ponto de entrada testável mais próximo, com fakes/stubs na fronteira de I/O. Se ainda assim for inviável, pergunte como seguir — não pule o TDD por conta própria.
- **Código legado sem teste:** antes de alterá-lo, escreva um teste de caracterização que fixe o comportamento atual (ele deve passar). Depois siga o ciclo normal para a mudança.

### Travou? Escute o teste

Dificuldade para testar costuma ser sinal de design:

| Sintoma                         | O que fazer                                                        |
|---------------------------------|--------------------------------------------------------------------|
| Não sei como testar             | Escreva a chamada da API que você gostaria de ter e a asserção primeiro. |
| Teste complicado demais         | A interface está complicada demais — simplifique-a.                |
| Precisa mockar tudo             | Acoplamento alto — injete as dependências.                         |
| Setup enorme                    | Extraia helpers de teste; se continuar enorme, reavalie o design.  |

## Relato

Mantenha a saída enxuta:

- Lista de casos no início.
- Uma linha por fase:
  - `RED — <caso>: falhou com <mensagem resumida>`
  - `GREEN — passou`
  - `REFACTOR — <o que mudou>` ou `REFACTOR — nada a fazer`
- Saída do runner **resumida** (a linha da falha, não o dump inteiro).
- Ao final: casos cobertos e resultado da suíte completa.

## Checklist de conclusão

Antes de dar a tarefa como pronta:

- [ ] Cada comportamento novo ou alterado tem teste.
- [ ] Cada teste foi visto falhando, pelo motivo certo, antes da implementação.
- [ ] Cada GREEN teve só o código mínimo.
- [ ] Suíte completa verde, com saída limpa.
- [ ] Mocks apenas na fronteira (ver [BOAS_PRATICAS.md](BOAS_PRATICAS.md)).
- [ ] Bordas e erros relevantes cobertos.

Algum item em aberto? A tarefa não está pronta.

## Commits

Nunca faça commits durante ou após o ciclo. Ao concluir, sugira usar `/commit`.
