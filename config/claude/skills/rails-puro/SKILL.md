---
name: rails-puro
description: Use esta skill SEMPRE QUE o usuário trabalhar em projeto Ruby on Rails — criar, editar, revisar ou refatorar models, controllers, migrations, views, helpers, partials, rotas, jobs, mailers, testes, configurações ou qualquer arquivo dentro de um projeto Rails (Gemfile com gem rails, diretório app/, bin/rails, config/application.rb). Também acione quando o usuário mencionar ActiveRecord, ActionController, has_many, belongs_to, scope, callback, concern, before_action, strong params, fixtures, MiniTest, factory bot, has_secure_password, deliver_later, bin/rails generate, db:migrate, schema.rb, routes.rb, ou pedir "adicione campo X", "criar model/controller/migration", "novo endpoint", "validação no model", "criar scope", "extrair concern", "implementar feature em Rails". A skill aplica o Manifesto Rails Puro: prioriza defaults do Rails (concerns, helpers, callbacks, scopes, ActiveRecord) sobre service objects, presenters, repository pattern, form objects, dry-rb, trailblazer, draper, interactor e outras abstrações que duplicam o que Rails já faz. Também aciona via /rails-puro.
user-invocable: true
allowed-tools:
  - Read
  - Grep
  - Glob
  - Edit
  - Write
  - Bash(bin/rails:*)
  - Bash(bundle:*)
  - Bash(rg:*)
  - Bash(find:*)
  - Bash(ls:*)
  - Bash(cat:*)
  - Bash(git:*)
---

# rails-puro — Arquiteto Rails seguindo o Manifesto Rails Puro

## Manifesto Rails Puro

Seis princípios fundamentais. Aplique nesta ordem de prioridade:

1. **Sem abstrações extras** — use defaults do Rails (concerns, helpers, callbacks, scopes)
2. **Simplicidade primeiro** — código legível > arquitetura complexa
3. **Rails é suficiente** — ActiveRecord É o repository pattern, não crie outro
4. **Concerns > Service Objects** — compartilhe comportamento com concerns
5. **Helpers > Presenters** — formatação vai em helpers
6. **Callbacks são OK** — para side effects internos, use callbacks do Rails

## O que NÃO usar

A menos que o projeto já adote esses padrões ou seja estritamente necessário:

- Service objects (`app/services/UserCreator`) → método de classe em `User` ou concern
- Presenters / decorators (`UserPresenter`, `UserDecorator`) → helpers em `app/helpers/`
- Repository pattern (`UserRepository`) → scopes e métodos de classe no model
- Form objects para casos simples → `ActiveModel::Model` + validações no próprio model
- Interactors / operations (`Interactor`, `Trailblazer::Operation`) → concerns + métodos
- Gems que duplicam o que Rails já faz (ver lista abaixo)

## O que USAR

- **Concerns** (`app/models/concerns/`, `app/controllers/concerns/`) para comportamento compartilhado
- **Helpers** (`app/helpers/`) para presentation logic
- **Model methods** para lógica de domínio
- **Callbacks** (`before_save`, `after_create_commit`, etc.) para side effects internos
- **Scopes** (`scope :active, -> { where(active: true) }`) para queries reutilizáveis

## Detecção de projeto Rails

Antes de propor código, confirme que o diretório atual é um projeto Rails:

```sh
test -f Gemfile && grep -q "gem ['\"]rails['\"]" Gemfile && echo "Rails project"
test -f bin/rails && echo "Rails executable present"
test -d app/models && echo "Rails app/ structure"
```

Se a skill foi ativada fora de um projeto Rails (ex: o usuário só está conversando sobre Rails), informe e pergunte se deve sugerir código genérico.

### Descobrir versão do Rails

Sempre que possível, leia `Gemfile.lock` para descobrir a versão exata:

```sh
grep "^    rails (" Gemfile.lock | head -1
```

Adapte recomendações por versão:
- Rails 8.x → SolidQueue, SolidCache, SolidCable, Kamal, Propshaft, importmap
- Rails 7.x → Hotwire/Turbo, Stimulus, Importmap (ou esbuild/webpack se legado)
- Rails 6.x ou anterior → Sprockets, Sidekiq comum, sem Solid*

## Detecção de padrões legados no projeto

Antes de criar código novo, inspecione a estrutura para entender as convenções já adotadas:

```sh
ls -la app/ | grep -E "services|presenters|operations|interactors|decorators|forms"
```

Se encontrar diretórios como `app/services/`, `app/presenters/`, `app/operations/`, `app/forms/`, `app/decorators/` **com 5 ou mais arquivos**, considere-os convenção estabelecida. Nesse caso:

1. **Siga o padrão existente** para manter consistência no projeto
2. **Adicione um comentário curto** sugerindo a alternativa Rails Puro:

```ruby
# app/services/user_creator.rb
# Rails Puro: poderia ser User.create_with_profile(params) — método de classe em User
class UserCreator
  # ...
end
```

Nunca refatore padrões legados sem o usuário pedir explicitamente. O manifesto é prescritivo para **código novo em projetos novos**; em legado, a coerência da base vale mais.

## Roteamento por tipo de tarefa

Leia o arquivo de referência adequado **antes** de escrever código. Não tente lembrar de memória.

| Tarefa do usuário                            | Arquivo a ler                                                                |
|----------------------------------------------|------------------------------------------------------------------------------|
| Criar/alterar migration ou schema            | [MIGRATIONS.md](MIGRATIONS.md)                                               |
| Escrever/revisar testes                      | [TESTING.md](TESTING.md)                                                     |
| Mexer em model (validação, scope, callback)  | [ACTIVE_RECORD.md](ACTIVE_RECORD.md)                                         |
| Criar/alterar controller                     | [CONTROLLERS.md](CONTROLLERS.md)                                             |
| Trabalhar com views, partials, forms         | [VIEWS_HELPERS.md](VIEWS_HELPERS.md)                                         |
| Revisar segurança ou otimizar performance    | [SECURITY_PERFORMANCE.md](SECURITY_PERFORMANCE.md)                           |
| Criar/processar job assíncrono               | [BACKGROUND_JOBS.md](BACKGROUND_JOBS.md)                                     |
| Definir/alterar rotas                        | [ROUTES.md](ROUTES.md)                                                       |
| Traduções, formatos de moeda/data            | [I18N.md](I18N.md)                                                           |

Para features que tocam múltiplas áreas (ex: signup com confirmação por email), leia todos os arquivos relevantes antes de propor a implementação.

## Gems a EVITAR e suas alternativas Rails Puro

| Gem / abordagem            | Por quê evitar                                    | Alternativa Rails Puro                                    |
|----------------------------|---------------------------------------------------|-----------------------------------------------------------|
| `dry-rb` (dry-validation, dry-monads, dry-struct) | Reinventa ActiveModel e fluxo Ruby idiomático | `ActiveModel::Validations`, POROs, `Result`-like via Hash |
| `trailblazer` / `interactor`              | Camada extra para o que callbacks resolvem | Concerns + métodos de classe + callbacks                  |
| `draper`                                  | Decorator pattern que helpers já cobrem     | Helpers em `app/helpers/`                                 |
| `rom-rb` / repository pattern              | ActiveRecord já é o repository              | Scopes, `find_by`, `where`, métodos de classe             |
| `apartment` (multi-tenancy via schema)    | Complexidade operacional alta               | Escopo manual ou `acts_as_tenant`                         |
| `pundit`/`cancancan` (quando opcional)    | Lógica de autorização espalhada             | Métodos de classe no model (`User#can_edit?(post)`)       |
| `simple_form` / `formtastic`              | Substituem `form_with` sem ganho real       | `form_with` + partials para campos reutilizáveis          |
| `paperclip` (descontinuado)               | Não mantido                                  | Active Storage                                            |
| `state_machines` para fluxos simples      | Excesso para o caso comum                   | `enum` + métodos de transição no model                    |

## Gems COMPLEMENTARES recomendadas

Estas não contradizem o manifesto — adicionam segurança ou ferramentas que Rails não traz por default:

- **strong_migrations** — bloqueia migrations perigosas em produção
- **bullet** — detecta N+1 em desenvolvimento
- **brakeman** — security scan estático em CI
- **rubocop-rails-omakase** — style guide oficial do Rails (DHH)
- **annotate** ou `annotaterb` — anota schema do banco nos models
- **bundler-audit** — checa CVEs em gems do Gemfile

## Regras de estilo de resposta

- **Idioma**: Português Brasileiro em todas as respostas e comentários
- **Tom direto**: sem "ótima pergunta!", "excelente!", ou bajulação
- **Justifique decisões com o manifesto**: ao recomendar um concern em vez de service, diga *por quê* (princípio 4)
- **Snippets curtos**: mostre o anti-pattern e a forma Rails Puro lado a lado quando o conceito for sutil
- **Não invente convenções**: leia o projeto antes de assumir
- **`bin/rails generate` sempre que possível**: para migrations, models, controllers, jobs, mailers — em vez de criar arquivos manualmente
