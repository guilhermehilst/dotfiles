# CONTROLLERS — Boas práticas em controllers

Leia antes de criar ou alterar controllers.

## RESTful actions, sempre

Use as 7 actions canônicas: `index`, `show`, `new`, `create`, `edit`, `update`, `destroy`. Se precisa de uma "custom action", normalmente é sinal de um novo recurso.

```ruby
# Ruim — custom action que esconde um recurso
class UsersController < ApplicationController
  def promote
    @user = User.find(params[:id])
    @user.update!(role: :admin)
    redirect_to @user
  end
end

routes.rb:
resources :users do
  member { post :promote }
end
```

```ruby
# Bom — Promotion é o recurso
class PromotionsController < ApplicationController
  def create
    @user = User.find(params[:user_id])
    @user.update!(role: :admin)
    redirect_to @user, notice: "Promovido a admin"
  end
end

routes.rb:
resources :users do
  resource :promotion, only: :create
end
```

## Strong params em método privado

Sempre via método privado, nunca inline:

```ruby
class UsersController < ApplicationController
  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to @user, status: :created
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :role)
  end
end
```

### Variações de strong params

```ruby
# Nested
params.require(:user).permit(:name, profile_attributes: [:bio, :avatar])

# Array
params.require(:post).permit(:title, tag_ids: [])

# Hash livre (cuidado)
params.require(:settings).permit(preferences: {})

# Diferente por action
def create_params
  params.require(:user).permit(:email, :role)
end

def update_params
  params.require(:user).permit(:name, :email)  # role não atualizável
end
```

## `before_action` para responsabilidades transversais

```ruby
class PostsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post, only: [:show, :edit, :update, :destroy]
  before_action :authorize_post!, only: [:edit, :update, :destroy]

  def show; end

  def edit; end

  def update
    if @post.update(post_params)
      redirect_to @post
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy!
    redirect_to posts_url, status: :see_other
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def authorize_post!
    redirect_to posts_url, alert: "Sem permissão" unless current_user.can_edit?(@post)
  end

  def post_params
    params.require(:post).permit(:title, :body)
  end
end
```

## Concerns de controller

Para comportamento compartilhado entre controllers, use `app/controllers/concerns/`:

```ruby
# app/controllers/concerns/paginatable.rb
module Paginatable
  extend ActiveSupport::Concern

  PAGE_SIZE = 25

  private

  def paginate(scope)
    page = [params[:page].to_i, 1].max
    scope.offset((page - 1) * PAGE_SIZE).limit(PAGE_SIZE)
  end
end

# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  include Paginatable

  def index
    @posts = paginate(Post.published.recent)
  end
end
```

## Status codes — explícito

Não confie no default. Seja explícito:

```ruby
# Sucesso
render :show, status: :created                  # 201
render :show, status: :ok                       # 200 (default)
head :no_content                                # 204

# Erros do cliente
render :new, status: :unprocessable_entity      # 422 (form inválido)
head :unauthorized                              # 401
head :forbidden                                 # 403
head :not_found                                 # 404

# Redirect
redirect_to @post                               # 302 (default)
redirect_to @post, status: :see_other           # 303 (use após DELETE com Turbo)
redirect_to @post, status: :moved_permanently   # 301
```

**Importante com Hotwire/Turbo**: após `destroy`, use `status: :see_other` (303) para Turbo seguir o redirect:

```ruby
def destroy
  @post.destroy!
  redirect_to posts_url, status: :see_other
end
```

## `respond_to` para múltiplos formatos

```ruby
class PostsController < ApplicationController
  def show
    @post = Post.find(params[:id])

    respond_to do |format|
      format.html
      format.json { render json: @post }
      format.turbo_stream
    end
  end

  def create
    @post = Post.new(post_params)
    respond_to do |format|
      if @post.save
        format.html { redirect_to @post, status: :created }
        format.json { render json: @post, status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end
end
```

## Redirect após sucesso, render após falha

Padrão clássico (PRG — Post/Redirect/Get):

```ruby
def create
  @post = Post.new(post_params)
  if @post.save
    redirect_to @post, notice: "Post criado"            # PRG
  else
    render :new, status: :unprocessable_entity          # preserva params para form
  end
end
```

Por quê:
- **Redirect após sucesso**: evita re-submit ao dar F5
- **Render após falha**: mantém os params digitados no formulário

## Lógica de negócio fica no model

```ruby
# Ruim — controller grande
def create
  @user = User.new(user_params)
  @user.email = @user.email.strip.downcase
  @user.role = "member" if @user.role.blank?
  @user.confirmation_token = SecureRandom.hex(32)
  @user.confirmation_sent_at = Time.current

  if @user.save
    UserMailer.confirmation(@user).deliver_later
    redirect_to root_path
  else
    render :new
  end
end
```

```ruby
# Bom — model cuida de si
class User < ApplicationRecord
  before_validation :normalize_email
  before_create :assign_confirmation_token
  after_create_commit :send_confirmation_email

  validates :email, presence: true, uniqueness: { case_sensitive: false }

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end

  def assign_confirmation_token
    self.confirmation_token = SecureRandom.hex(32)
    self.confirmation_sent_at = Time.current
  end

  def send_confirmation_email
    UserMailer.confirmation(self).deliver_later
  end
end

class UsersController < ApplicationController
  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to root_path
    else
      render :new, status: :unprocessable_entity
    end
  end
end
```

## API mode — JSON via Jbuilder

Para APIs JSON, prefira Jbuilder (built-in) a serializers externos:

```ruby
# app/views/api/users/show.json.jbuilder
json.id @user.id
json.name @user.name
json.email @user.email
json.posts @user.posts do |post|
  json.id post.id
  json.title post.title
end
```

```ruby
class Api::UsersController < ApplicationController
  def show
    @user = User.find(params[:id])
    # render automaticamente busca show.json.jbuilder
  end
end
```

## ApplicationController

Comportamento global vai aqui:

```ruby
class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  rescue_from ActiveRecord::RecordNotFound do
    redirect_to root_path, alert: "Não encontrado"
  end

  private

  def authenticate_user!
    redirect_to login_path unless current_user
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end
  helper_method :current_user
end
```

## Anti-padrões

| Padrão                                       | Substituir por                                  |
|----------------------------------------------|-------------------------------------------------|
| Controller chamando service object simples   | Método de classe no model (`User.create_with_profile`) |
| Strong params inline (`permit(:a, :b)` em `create`) | Método privado `user_params`                   |
| Custom action ad hoc (`/users/:id/promote`)  | Novo recurso (`POST /users/:id/promotion`)      |
| Lógica de negócio no controller              | Move para o model (callbacks, métodos de domínio) |
| Re-render com redirect (`redirect_to :new`)  | `render :new, status: :unprocessable_entity` (preserva params) |
| `params[:user]` direto (sem strong params)   | Sempre via `require.permit`                     |
| `before_filter` (descontinuado)              | `before_action`                                 |

## Checklist antes de commitar um controller

- [ ] Apenas as 7 actions RESTful (ou justificativa explícita)
- [ ] Strong params em método privado
- [ ] `before_action` para autenticação, autorização, set_resource
- [ ] Status codes explícitos (`:created`, `:unprocessable_entity`, `:see_other`)
- [ ] Lógica de negócio delegada ao model
- [ ] Concerns para comportamento compartilhado entre controllers
- [ ] Redirect após sucesso, render após falha (com `:unprocessable_entity`)
- [ ] Sem queries ActiveRecord complexas (movê-las para scopes no model)
