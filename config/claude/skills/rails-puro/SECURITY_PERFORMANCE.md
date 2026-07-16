# SECURITY_PERFORMANCE — Segurança e performance em Rails

Leia ao revisar código existente, otimizar gargalos, ou antes de subir feature sensível à produção.

## Segurança

### Strong params (ver também CONTROLLERS.md)

Nunca:
```ruby
User.new(params[:user])           # mass assignment vulnerability
```

Sempre:
```ruby
User.new(user_params)

private

def user_params
  params.require(:user).permit(:name, :email)
end
```

### CSRF

Habilitado por default em `ApplicationController` (`protect_from_forgery with: :exception` em Rails 5.2+; mais novo: `action_controller_request_forgery_protection`).

Para APIs JSON:
```ruby
class Api::BaseController < ActionController::API
  # API mode já não inclui CSRF middleware
end
```

Para controllers que misturam HTML + JSON com token API:
```ruby
class ApiController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_via_api_token!
end
```

### SQL injection

**Nunca** interpole strings em queries:

```ruby
# Crítico — SQL injection
User.where("name = '#{params[:name]}'")
User.where("created_at > #{params[:date]}")
```

**Sempre** parametrize:

```ruby
# Seguro — placeholders
User.where("name = ?", params[:name])
User.where("name = :name AND age > :age", name: "Alice", age: 18)

# Melhor — hash
User.where(name: params[:name])
```

Para LIKE com user input, sanitize:

```ruby
User.where("name ILIKE ?", "%#{User.sanitize_sql_like(params[:query])}%")
```

### XSS

Rails escapa automaticamente em ERB:

```erb
<%= user.bio %>   <%# seguro — escapado %>
```

Perigoso:
```erb
<%= user.bio.html_safe %>          <%# anula escape %>
<%= raw user.bio %>                <%# mesma coisa %>
<%== user.bio %>                   <%# mesma coisa %>
```

Quando precisa de HTML do usuário (ex: Markdown, WYSIWYG):

```ruby
# helper
def safe_markdown(text)
  html = render_markdown(text)
  sanitize html, tags: %w[p h1 h2 h3 strong em a code pre ul ol li blockquote],
                 attributes: %w[href]
end
```

### Mass assignment via JSON

Cuidado com APIs que aceitam JSON arbitrário:

```ruby
# Ruim
def update
  @user.update(params[:user])
end

# Bom
def update
  @user.update(user_params)
end

def user_params
  params.require(:user).permit(:name, :email)   # role NÃO está aqui
end
```

### Autenticação e sessão

- **`has_secure_password`** do Rails para hash de senha (bcrypt)
- Para apps novos em Rails 8: use o gerador `bin/rails generate authentication` (built-in)
- Tokens via `has_secure_token` para reset, confirmação, API key
- Cookies de sessão com `secure: true` em produção
- `session_store :cookie_store, key: '_app_session', secure: Rails.env.production?, httponly: true`

```ruby
class User < ApplicationRecord
  has_secure_password
  has_secure_token :confirmation_token
end
```

### Autorização

Para apps simples, métodos no model:

```ruby
class User < ApplicationRecord
  def can_edit?(post)
    admin? || post.user_id == id
  end
end

class PostsController < ApplicationController
  before_action :authorize_edit!, only: [:edit, :update, :destroy]

  private

  def authorize_edit!
    redirect_to posts_url, alert: "Sem permissão" unless current_user.can_edit?(@post)
  end
end
```

Apenas adote `pundit`/`cancancan` se a complexidade justificar (matriz de permissões muito grande, múltiplos roles, escopos de query).

### Brakeman

Adicione ao `Gemfile`:

```ruby
group :development, :test do
  gem "brakeman", require: false
end
```

Rode em CI:
```sh
bundle exec brakeman --no-pager --quiet --exit-on-warn
```

### Bundler-audit

Detecta gems com CVEs:

```ruby
group :development, :test do
  gem "bundler-audit", require: false
end
```

```sh
bundle exec bundle-audit check --update
```

### Outros cuidados

- **`force_ssl = true`** em produção
- **Strong content security policy** (`config.content_security_policy` em initializers)
- **Rate limiting** com `rack-attack` ou `Rack::Attack`
- **Headers de segurança**: `X-Frame-Options`, `X-Content-Type-Options` (Rails configura por default)
- **Senhas em logs**: `config.filter_parameters += [:password, :token, :secret, :api_key]`

## Performance

### Eager loading — combate ao N+1

**Sempre** use `includes` quando vai iterar associações:

```ruby
# Ruim — N+1
@posts = Post.all
@posts.each { |p| puts p.user.name }  # 1 query por post

# Bom — 2 queries totais
@posts = Post.includes(:user)

# Múltiplas associações
@posts = Post.includes(:user, :tags, comments: :user)
```

#### `includes` vs `preload` vs `eager_load`

- **`includes`** — Rails escolhe: preload (2 queries) ou eager_load (LEFT JOIN). Use quando não precisa filtrar pela associação.
- **`preload`** — sempre 2 queries separadas. Use para evitar JOIN.
- **`eager_load`** — sempre LEFT JOIN em 1 query. Use quando filtra/ordena pela associação:

```ruby
# Precisa filtrar pela associação — use eager_load
Post.eager_load(:comments).where(comments: { approved: true })

# Apenas carregar — preload é mais barato
Post.preload(:comments)
```

### Detecte N+1 com Bullet

```ruby
# Gemfile
group :development do
  gem "bullet"
end

# config/environments/development.rb
config.after_initialize do
  Bullet.enable        = true
  Bullet.alert         = true
  Bullet.bullet_logger = true
  Bullet.console       = true
end
```

### `pluck` quando só precisa de coluna(s)

```ruby
# Ruim — carrega objetos inteiros
User.where(active: true).map(&:email)

# Bom — só a coluna
User.where(active: true).pluck(:email)

# Múltiplas
User.where(active: true).pluck(:id, :email)
```

### `select` para limitar colunas

```ruby
# Quando models têm colunas grandes (ex: text com 100KB)
Post.select(:id, :title, :user_id).recent.limit(10)
```

### Counter cache (ver também ACTIVE_RECORD.md)

```ruby
# Migration
add_column :users, :posts_count, :integer, default: 0, null: false

# Model
class Post < ApplicationRecord
  belongs_to :user, counter_cache: true
end
```

### Caching

#### Low-level cache
```ruby
def expensive_calculation
  Rails.cache.fetch("user:#{id}:stats", expires_in: 1.hour) do
    # cálculo caro
    posts.published.group_by_month(:created_at).count
  end
end
```

#### Fragment cache em view
```erb
<% cache @post do %>
  <%= render @post %>
<% end %>
```

#### Russian Doll caching
```ruby
class Comment < ApplicationRecord
  belongs_to :post, touch: true   # toca o post quando comment muda
end
```

```erb
<% cache @post do %>
  <h1><%= @post.title %></h1>
  <% cache @post.comments do %>
    <%= render @post.comments %>
  <% end %>
<% end %>
```

#### Cache stores
- **Dev/teste**: `:memory_store`
- **Produção single-server**: `:file_store` (simples)
- **Produção multi-server**: `:redis_cache_store` ou `:solid_cache_store` (Rails 8 default)

### Iterações grandes — `find_each`

```ruby
# Ruim — carrega 100k em memória
User.all.each { |u| u.recalculate_stats! }

# Bom — 1000 por vez
User.find_each(batch_size: 1000) { |u| u.recalculate_stats! }
```

### `update_all` / `insert_all` para operações em massa

```ruby
# Lento — N callbacks
User.where(active: false).each { |u| u.update!(archived: true) }

# Rápido — 1 UPDATE
User.where(active: false).update_all(archived: true, archived_at: Time.current)
```

**Cuidado**: `update_all` pula validações, callbacks e `updated_at`. Inclua `updated_at: Time.current` manualmente se importar.

```ruby
# Insert em massa (Rails 6+)
User.insert_all([
  { name: "A", email: "a@x.com", created_at: Time.current, updated_at: Time.current },
  { name: "B", email: "b@x.com", created_at: Time.current, updated_at: Time.current }
])

# Upsert (Rails 6+)
User.upsert_all(records, unique_by: :email)
```

### Índices de banco

Adicione índices para colunas usadas em:
- `where` frequente
- `order_by`
- JOINs (já vem com `references`)
- Constraints únicas

```ruby
add_index :users, :email, unique: true
add_index :posts, [:user_id, :published_at]   # composto: ordem importa
add_index :posts, :published_at, where: "deleted_at IS NULL"  # parcial (PG)
```

### Análise de queries

```ruby
# No console
User.where(active: true).explain

# Em logs — busque queries lentas (config/environments/production.rb)
config.active_record.warn_on_records_fetched_greater_than = 1000
```

### Monitoramento em produção

- **`rack-mini-profiler`** em dev
- **`scout_apm`/`new_relic`/`skylight`** em produção
- **`pg_stat_statements`** no PostgreSQL para top queries lentas

## Checklist antes de subir para produção

- [ ] Strong params em todos controllers
- [ ] CSRF ativo (default)
- [ ] Sem interpolação de string em queries
- [ ] Sem `html_safe`/`raw` em conteúdo de usuário não sanitizado
- [ ] `force_ssl = true` em produção
- [ ] `config.filter_parameters` filtra senhas/tokens
- [ ] Brakeman passou sem warnings
- [ ] bundler-audit sem CVEs
- [ ] Queries iterativas usam `includes`/`preload`/`eager_load`
- [ ] Iterações grandes usam `find_each`
- [ ] Índices nas colunas críticas
- [ ] Counter cache em contadores frequentemente lidos
- [ ] Cache aplicado em queries/fragments custosos
