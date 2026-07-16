# ROUTES — Boas práticas de rotas RESTful

Leia antes de adicionar/alterar rotas em `config/routes.rb`.

## `resources` sempre, custom paths quase nunca

```ruby
# Bom — RESTful completo
resources :users
# Gera: GET /users, GET /users/:id, GET /users/new, POST /users,
#       GET /users/:id/edit, PATCH/PUT /users/:id, DELETE /users/:id
```

```ruby
# Ruim — paths manuais
get  "users",          to: "users#index"
get  "users/:id",      to: "users#show"
get  "users/new",      to: "users#new"
post "users",          to: "users#create"
# ... e assim por diante
```

## Limitar actions com `only:` / `except:`

```ruby
# Apenas leitura
resources :reports, only: [:index, :show]

# Tudo exceto destruir
resources :invoices, except: [:destroy]
```

## Singular resource (sem ID)

Quando o recurso é único no contexto do usuário (ex: perfil, configurações):

```ruby
resource :profile, only: [:show, :edit, :update]
# Gera: GET /profile, GET /profile/edit, PATCH /profile
# Action recebe profile via current_user.profile (não params[:id])
```

## Aninhamento — máximo 1 nível

```ruby
# Bom — 1 nível
resources :users do
  resources :posts
end
# /users/:user_id/posts, /users/:user_id/posts/:id
```

```ruby
# Ruim — aninhamento profundo
resources :users do
  resources :posts do
    resources :comments do
      resources :replies   # /users/1/posts/2/comments/3/replies/4 — feio
    end
  end
end
```

Para reduzir aninhamento profundo, use **shallow**:

```ruby
resources :users do
  resources :posts, shallow: true
end
# index/create/new aninhados: /users/:user_id/posts, /users/:user_id/posts/new
# show/edit/update/destroy "rasos": /posts/:id, /posts/:id/edit
```

## Custom actions com `member` e `collection`

Use quando uma action REALMENTE não cabe nas 7 RESTful:

```ruby
resources :posts do
  member do
    post :publish      # POST /posts/:id/publish
    post :unpublish    # POST /posts/:id/unpublish
  end

  collection do
    get :search        # GET /posts/search
    get :archive       # GET /posts/archive
  end
end
```

### Mas considere se é um recurso novo

```ruby
# Em vez de:
resources :posts do
  member { post :publish }
end

# Considere:
resources :posts do
  resource :publication, only: [:create, :destroy]
end
# POST /posts/:post_id/publication      → publica
# DELETE /posts/:post_id/publication    → despublica
```

Vantagem: dois verbos HTTP distintos, sem URL com verbo no path.

## Namespaces para áreas/módulos

```ruby
namespace :admin do
  resources :users
  resources :posts
end
# Gera: /admin/users → Admin::UsersController
```

Útil para:
- Painel admin
- Área de API versionada (`namespace :api do ... end`)

### API versionada

```ruby
namespace :api do
  namespace :v1 do
    resources :users, only: [:index, :show]
  end
  namespace :v2 do
    resources :users
  end
end
# /api/v1/users → Api::V1::UsersController
# /api/v2/users → Api::V2::UsersController
```

## Scope vs namespace

- **`namespace`** — adiciona prefixo no path E no módulo do controller
- **`scope`** — adiciona prefixo apenas no path
- **`scope module:`** — adiciona prefixo apenas no módulo

```ruby
# namespace :admin — URL /admin/users, controller Admin::UsersController
namespace :admin do
  resources :users
end

# scope path — URL /admin/users, controller UsersController (sem módulo)
scope "/admin" do
  resources :users
end

# scope module — URL /users, controller Admin::UsersController
scope module: :admin do
  resources :users
end
```

## Root route

Sempre defina:

```ruby
root "home#index"
# OU
root to: "home#index"
```

## Concerns de rota (para reuso)

Quando vários resources compartilham sub-rotas:

```ruby
concern :commentable do
  resources :comments, only: [:create, :destroy]
end

resources :posts, concerns: :commentable
resources :photos, concerns: :commentable
# Gera comments para ambos
```

## Constraints

### Por formato

```ruby
constraints format: :json do
  resources :users, only: [:index, :show]
end
```

### Por subdomínio

```ruby
constraints subdomain: "api" do
  namespace :api, path: "/" do
    resources :users
  end
end
# api.example.com/users → Api::UsersController
```

### Por regex no parâmetro

```ruby
get "/posts/:slug", to: "posts#show", constraints: { slug: /[a-z0-9-]+/ }
```

## Rotas com tokens / slugs

Use o gerador `friendly_id` ou implemente manualmente no model:

```ruby
class Post < ApplicationRecord
  def to_param
    slug.presence || id.to_s
  end
end
```

```ruby
# routes.rb — nada muda; Rails chama to_param automaticamente
resources :posts

# Controller — find pelo slug
def set_post
  @post = Post.find_by(slug: params[:id]) || Post.find(params[:id])
end
```

## `defaults` para parâmetros padrão

```ruby
resources :pages, defaults: { format: :html }
get "/api/users", to: "api/users#index", defaults: { format: :json }
```

## Nome customizado da rota (`as:`)

```ruby
resources :payments, as: :transactions
# Gera helpers: transactions_path, new_transaction_path
```

Útil quando o nome da tabela difere do conceito de domínio.

## Direct routes (Rails 5.1+)

Para helpers customizados:

```ruby
direct :homepage do
  "https://www.example.com"
end
# homepage_url → "https://www.example.com"

resolve "Post" do |post|
  [:custom, post]
end
# url_for(@post) → custom_post_path(@post)
```

## Verbos HTTP corretos

| Verbo  | Uso                              | Idempotente? |
|--------|----------------------------------|--------------|
| GET    | Leitura, sem efeito              | sim          |
| POST   | Criação, ações com efeito        | não          |
| PATCH  | Atualização parcial              | sim          |
| PUT    | Substituição completa            | sim          |
| DELETE | Remoção                          | sim          |

Rails usa **PATCH** por default em `update`, não PUT — porque updates raramente substituem todo o recurso.

## Anti-padrões

| Padrão                                            | Substituir por                                |
|---------------------------------------------------|-----------------------------------------------|
| `match "/users", to: ...` (qualquer verbo)       | `get`, `post`, etc. específicos               |
| `get "/users/:id/promote", to: ...`              | `POST /users/:id/promotion` (novo recurso)    |
| Custom action GET com efeito colateral            | POST/PATCH/DELETE conforme semântica          |
| Aninhamento 3+ níveis                             | Shallow nesting ou recurso achatado           |
| `resources :users` quando só precisa de 2 actions | `resources :users, only: [:index, :show]`     |
| Strings literais com path manual                  | Use helpers (`user_path(@user)`)              |

## Como debugar rotas

```sh
# Lista todas as rotas
bin/rails routes

# Filtra por nome ou path
bin/rails routes -g posts
bin/rails routes -g "POST"
bin/rails routes -c PostsController

# No browser (dev): http://localhost:3000/rails/info/routes
```

## Checklist antes de commitar mudança em routes.rb

- [ ] Usa `resources` (não paths manuais)
- [ ] Custom actions justificáveis (não cabem em recurso novo)
- [ ] Aninhamento máximo 1 nível (ou shallow)
- [ ] `only:` / `except:` para limitar actions a expostas
- [ ] Namespace para áreas (admin, api/v1)
- [ ] `root` definido
- [ ] Verbos HTTP corretos (GET sem efeito colateral)
- [ ] `bin/rails routes` mostra o esperado, sem duplicatas
