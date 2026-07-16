# ACTIVE_RECORD — Boas práticas em models

Leia antes de criar ou alterar models, scopes, validações, callbacks ou associações.

## Onde colocar lógica de domínio

A lógica de domínio vive **no model**, não em service objects.

```ruby
# Bom — método de domínio no model
class User < ApplicationRecord
  def full_name
    [first_name, last_name].compact.join(" ")
  end

  def self.create_with_profile(params)
    transaction do
      user = create!(params.slice(:email, :name))
      user.create_profile!(params.slice(:bio, :avatar))
      user
    end
  end
end
```

```ruby
# Ruim — service object para o que é responsabilidade do model
class UserCreator
  def self.call(params)
    User.transaction do
      user = User.create!(params.slice(:email, :name))
      user.create_profile!(params.slice(:bio, :avatar))
      user
    end
  end
end
```

## Validações

Sempre no model — nunca no controller, nunca em service:

```ruby
class User < ApplicationRecord
  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true, length: { maximum: 100 }
  validates :age, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
```

### Validações condicionais

```ruby
validates :cpf, presence: true, if: :brazilian?
validates :ssn, presence: true, if: :american?

# Ou bloco para lógica composta
validates :ein, presence: true, if: -> { american? && company? }
```

### Validações customizadas

```ruby
class User < ApplicationRecord
  validate :email_must_match_company_domain

  private

  def email_must_match_company_domain
    return if email.blank? || company.blank?
    return if email.ends_with?("@#{company.domain}")

    errors.add(:email, "deve usar o domínio @#{company.domain}")
  end
end
```

## Associações

Sempre `optional: false` (default em Rails 5+), `dependent:` explícito:

```ruby
class Post < ApplicationRecord
  belongs_to :user
  belongs_to :editor, class_name: "User", optional: true
  has_many :comments, dependent: :destroy
  has_many :tags, through: :post_tags
  has_one_attached :cover_image
end

class User < ApplicationRecord
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_one :profile, dependent: :destroy
end
```

### Opções de `dependent:`

- `:destroy` — chama `destroy` em cada associado (executa callbacks)
- `:delete_all` — SQL `DELETE` direto, sem callbacks (mais rápido, mais perigoso)
- `:nullify` — define FK como NULL
- `:restrict_with_exception` — impede deleção se há associados
- `:restrict_with_error` — adiciona erro no `errors`

Escolha conforme o domínio. Sem `dependent:` o Rails deixa órfãos.

## Scopes

Use scopes para queries reutilizáveis:

```ruby
class Post < ApplicationRecord
  scope :published, -> { where.not(published_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user) { where(user: user) }
  scope :in_period, ->(from, to) { where(created_at: from..to) }
end
```

Combinam:
```ruby
Post.published.recent.by_user(current_user).limit(10)
```

### Scope vs método de classe

Use **scope** quando retorna `ActiveRecord::Relation` (encadeável):
```ruby
scope :active, -> { where(active: true) }
```

Use **método de classe** quando tem lógica condicional complexa:
```ruby
def self.search(query)
  return all if query.blank?
  return active if query == "active"
  where("name ILIKE ?", "%#{sanitize_sql_like(query)}%")
end
```

Diferença prática: scope nunca retorna `nil`, método de classe pode.

## Concerns para comportamento compartilhado

Quando 2+ models têm o mesmo comportamento, extraia para concern em `app/models/concerns/`:

```ruby
# app/models/concerns/soft_deletable.rb
module SoftDeletable
  extend ActiveSupport::Concern

  included do
    scope :active,  -> { where(deleted_at: nil) }
    scope :deleted, -> { where.not(deleted_at: nil) }
  end

  def soft_delete!
    update!(deleted_at: Time.current)
  end

  def restore!
    update!(deleted_at: nil)
  end

  def deleted?
    deleted_at.present?
  end
end

# app/models/user.rb
class User < ApplicationRecord
  include SoftDeletable
end

# app/models/post.rb
class Post < ApplicationRecord
  include SoftDeletable
end
```

```ruby
# Bom — concern reutilizável
class User
  include SoftDeletable
end

# Ruim — service object para o mesmo objetivo
class UserSoftDeleter
  def self.call(user)
    user.update!(deleted_at: Time.current)
  end
end
```

## Callbacks

Use callbacks para side effects **internos do model**:

```ruby
class User < ApplicationRecord
  before_validation :normalize_email
  before_save :set_default_role
  after_create_commit :enqueue_welcome_email

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end

  def set_default_role
    self.role ||= "member"
  end

  def enqueue_welcome_email
    WelcomeEmailJob.perform_later(id)
  end
end
```

### Regras para callbacks

- **Side effects externos** (email, API, job): use `after_*_commit`, **não** `after_save` ou `after_create`. Commit garante que a transação foi persistida.
- **Nunca** lance exceções em callbacks de leitura (`after_find`)
- **Evite cascata grande**: callback que dispara callback que dispara callback fica difícil de debugar
- **`throw :abort`** para cancelar — não `false` (descontinuado em Rails 5+)

### Quando NÃO usar callbacks

- Quando o side effect depende do contexto da chamada (usuário em controller X faz Y, mas em controller Z faz W). Nesse caso, mova para o controller ou um concern de controller.
- Quando o side effect deve ser opcional (importação em lote sem disparar emails). Use `update_columns` ou `insert_all` que pulam callbacks, e dispare jobs manualmente quando preciso.

## Enums

Para campos com valores fechados:

```ruby
class Post < ApplicationRecord
  enum status: { draft: 0, published: 1, archived: 2 }
end

post.draft?           # => true/false
post.published!       # define status: :published
Post.published        # scope automático
Post.statuses         # => { "draft" => 0, "published" => 1, "archived" => 2 }
```

**Em Rails 7+**, sintaxe recomendada com posicional:
```ruby
enum :status, { draft: 0, published: 1, archived: 2 }, default: :draft
```

Use **integer** no banco (`add_column :posts, :status, :integer, default: 0, null: false`). String é OK mas perde ganho de espaço/índice.

## Counter cache

Quando você frequentemente faz `user.posts.count`, use counter cache:

```ruby
# Migration
add_column :users, :posts_count, :integer, default: 0, null: false

# Model
class Post < ApplicationRecord
  belongs_to :user, counter_cache: true
end

# Backfill (em rake task)
User.find_each { |u| User.reset_counters(u.id, :posts) }
```

Agora `user.posts_count` é uma leitura de coluna, não COUNT no banco.

## N+1

### Ruim — N+1 query
```ruby
Post.all.each do |post|
  puts post.user.name  # 1 query por post
end
```

### Bom — eager loading
```ruby
Post.includes(:user).each do |post|
  puts post.user.name  # 2 queries total
end
```

### Eager loading com WHERE em associação
```ruby
# Post.includes(:comments).where(comments: { approved: true })
# → ambíguo: o Rails decide entre preload (2 queries) e eager_load (LEFT JOIN)

# Explícito:
Post.eager_load(:comments).where(comments: { approved: true })
```

### Detecte N+1 em dev com Bullet
```ruby
# Gemfile
group :development do
  gem "bullet"
end

# config/environments/development.rb
config.after_initialize do
  Bullet.enable = true
  Bullet.alert = true
  Bullet.console = true
end
```

## Iterações em conjuntos grandes

```ruby
# Ruim — carrega 100k registros em memória
User.all.each { |u| u.send_newsletter }

# Bom — 1000 por vez
User.find_each(batch_size: 1000) { |u| u.send_newsletter }

# Quando precisa do batch inteiro
User.in_batches(of: 1000) do |batch|
  batch.update_all(notified: true)
end
```

## `update_columns` / `update_all` — sem callbacks

```ruby
# Pula validações, callbacks, timestamps
user.update_columns(last_seen_at: Time.current)

# SQL UPDATE direto, em massa
User.where(active: false).update_all(archived: true)
```

Use quando:
- Performance é crítica
- Você intencionalmente quer pular validações/callbacks (backfill, métricas)

Não use quando:
- Há lógica em callbacks que precisa rodar
- Você só está "evitando validar" para fazer dado inválido passar — isso é um cheiro

## Outros padrões

### Strong params? Não. No model use atribuição direta após filtragem no controller.

### `ApplicationRecord` como base
Todo model herda de `ApplicationRecord`, que herda de `ActiveRecord::Base`. Coloque comportamento global lá (ex: concerns aplicados a todos os models).

### `attribute :name, :type` para atributos virtuais
```ruby
class User < ApplicationRecord
  attribute :temporary_password, :string  # não persistido se não há coluna
end
```

## Anti-padrões

| Padrão                                              | Substituir por                                  |
|-----------------------------------------------------|-------------------------------------------------|
| `UserCreator.call(params)` — service object simples | `User.create_with_profile(params)` — método de classe |
| `UserPresenter.new(user).full_name`                 | `user.full_name` no model OU `user_full_name(user)` em helper |
| `UserForm` (form object) para formulário simples    | `ActiveModel::Model` + validações no próprio User |
| `UserRepository.find_active`                        | `User.active` (scope)                           |
| `UserPolicy` quando autorização é simples           | `user.can_edit?(post)` método no model          |

## Checklist antes de commitar um model

- [ ] Validações no model (não no controller)
- [ ] `belongs_to`/`has_many` com `dependent:` explícito
- [ ] `optional: false` (default) em `belongs_to` quando obrigatório
- [ ] Scopes para queries reutilizáveis
- [ ] Concerns para comportamento compartilhado entre 2+ models
- [ ] Callbacks usam `after_*_commit` para side effects externos
- [ ] Sem `Faker`/randomização em validações
- [ ] Iterações grandes usam `find_each`/`in_batches`
- [ ] Queries com associação usam `includes`/`eager_load` para evitar N+1
- [ ] Counter cache em contadores frequentemente lidos
