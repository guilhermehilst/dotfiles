# VIEWS_HELPERS — Boas práticas em views e helpers

Leia antes de criar ou alterar templates, partials, helpers ou formulários.

## Helpers para presentation logic, não presenters

Toda lógica de formatação/apresentação vai em `app/helpers/`:

```ruby
# Bom — helper
module UsersHelper
  def user_full_name(user)
    [user.first_name, user.last_name].compact.join(" ").presence || user.email
  end

  def user_avatar(user, size: 64)
    if user.avatar.attached?
      image_tag user.avatar.variant(resize_to_fill: [size, size]), class: "rounded-full"
    else
      tag.div class: "avatar-placeholder", style: "width: #{size}px; height: #{size}px"
    end
  end

  def user_status_badge(user)
    css_class = case user.status
                when "active"   then "badge-success"
                when "archived" then "badge-muted"
                else                 "badge-warning"
                end
    tag.span t("users.statuses.#{user.status}"), class: "badge #{css_class}"
  end
end
```

```ruby
# Ruim — presenter externo (gem draper)
class UserPresenter < Draper::Decorator
  def full_name
    [object.first_name, object.last_name].compact.join(" ")
  end
end
```

## Partials para markup reutilizável

Use `_` prefix e `render`:

```erb
<%# app/views/posts/_post.html.erb %>
<article class="post" id="<%= dom_id(post) %>">
  <h2><%= link_to post.title, post %></h2>
  <p class="meta">por <%= user_full_name(post.user) %> em <%= l(post.created_at, format: :short) %></p>
  <div class="body"><%= post.body %></div>
</article>
```

```erb
<%# app/views/posts/index.html.erb %>
<h1><%= t(".titulo") %></h1>

<%= render partial: "post", collection: @posts %>

<%# OU forma curta, mesmo resultado: %>
<%= render @posts %>
```

### Locais em partials

```erb
<%= render "users/avatar", user: @author, size: 128 %>

<%# Dentro de _avatar.html.erb: %>
<%= user_avatar(user, size: size) %>
```

### Partials de form

```erb
<%# app/views/posts/_form.html.erb %>
<%= form_with model: post do |f| %>
  <% if post.errors.any? %>
    <div class="errors">
      <h2><%= pluralize(post.errors.count, "erro") %> ao salvar:</h2>
      <ul>
        <% post.errors.full_messages.each do |msg| %>
          <li><%= msg %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div class="field">
    <%= f.label :title %>
    <%= f.text_field :title, required: true %>
  </div>

  <div class="field">
    <%= f.label :body %>
    <%= f.text_area :body, rows: 10 %>
  </div>

  <div class="actions">
    <%= f.submit %>
  </div>
<% end %>
```

```erb
<%# new.html.erb e edit.html.erb compartilham: %>
<%= render "form", post: @post %>
```

## `form_with` é o default (Rails 5.1+)

```erb
<%= form_with model: @post do |f| %>
  <%= f.text_field :title %>
<% end %>

<%# Não use form_for ou form_tag — descontinuados %>
```

Para formulários sem model:

```erb
<%= form_with url: search_path, method: :get do |f| %>
  <%= f.text_field :query %>
  <%= f.submit "Buscar" %>
<% end %>
```

## Tag helpers

Use os tag helpers — evite HTML literal quando há atributos dinâmicos:

```erb
<%# Bom %>
<%= link_to "Editar", edit_post_path(@post), class: "btn btn-primary" %>
<%= button_to "Deletar", post_path(@post), method: :delete, data: { turbo_confirm: "Tem certeza?" } %>
<%= image_tag @user.avatar, alt: @user.name, class: "avatar" %>

<%# Construir tags dinâmicas %>
<%= tag.div class: ["alert", "alert-#{type}"] do %>
  <%= message %>
<% end %>

<%# Múltiplas classes condicionalmente (Rails 6.1+) %>
<%= tag.div class: class_names("post", featured: post.featured?, draft: post.draft?) do %>
  <%= post.title %>
<% end %>
```

## Não coloque lógica em views

Cheiro: condicionais complexas, queries, cálculos em views.

```erb
<%# Ruim — query e cálculo na view %>
<% if @user.posts.where(published: true).where("created_at > ?", 30.days.ago).count > 5 %>
  <span class="badge">Ativo</span>
<% end %>
```

```ruby
# Bom — método no model
class User < ApplicationRecord
  def active_author?
    posts.published.where(created_at: 30.days.ago..).count > 5
  end
end
```

```erb
<%# View limpa %>
<% if @user.active_author? %>
  <span class="badge">Ativo</span>
<% end %>
```

## Não faça queries em views

```erb
<%# Ruim — query no template %>
<% Post.published.recent.limit(5).each do |post| %>
  <%= render post %>
<% end %>
```

```ruby
# Bom — query no controller
class HomeController < ApplicationController
  def index
    @recent_posts = Post.published.recent.limit(5)
  end
end
```

```erb
<%# View %>
<%= render @recent_posts %>
```

## i18n em views — sempre lazy lookup

```erb
<%# Bom %>
<h1><%= t(".titulo") %></h1>
<p><%= t(".descricao") %></p>
<%= link_to t(".criar_novo"), new_post_path %>
```

```yaml
# config/locales/pt-BR.yml
pt-BR:
  posts:
    index:
      titulo: "Posts publicados"
      descricao: "Veja os últimos posts"
      criar_novo: "Criar novo post"
```

A chave `.titulo` é resolvida automaticamente como `pt-BR.posts.index.titulo` (controller + action).

## XSS — sanitize sempre conteúdo do usuário

```erb
<%# OK — Rails escapa automaticamente %>
<%= @user.bio %>

<%# Perigoso — html_safe sem sanitize %>
<%= @user.bio.html_safe %>

<%# Bom — sanitize com tags permitidas %>
<%= sanitize @user.bio, tags: %w[strong em a], attributes: %w[href] %>

<%# Markdown — use gem confiável (commonmarker, redcarpet) e ainda assim sanitize %>
<%= sanitize render_markdown(@post.body), tags: %w[h1 h2 h3 p strong em a code pre ul ol li] %>
```

Cuidado com:
- `raw`
- `html_safe` em strings vindas do banco
- `<%==` (igual `raw`)
- Interpolação de params em atributos HTML

## Helpers que retornam HTML

Use `tag` helpers ou `content_tag` (descontinuado em favor de `tag.X`):

```ruby
# Bom — sempre seguro, sem html_safe manual
def user_badge(user)
  tag.span user.name, class: "badge", data: { user_id: user.id }
end
```

```ruby
# Ruim — string crua com html_safe
def user_badge(user)
  "<span class='badge' data-user-id='#{user.id}'>#{user.name}</span>".html_safe
end
```

## Caches de fragmento

Para views pesadas que mudam pouco:

```erb
<% cache @post do %>
  <article>
    <h2><%= @post.title %></h2>
    <%= render @post.comments %>
  </article>
<% end %>
```

Russian Doll caching com `touch:`:

```ruby
class Comment < ApplicationRecord
  belongs_to :post, touch: true   # toca updated_at do post quando comment muda
end
```

```erb
<% cache @post do %>
  <%= render @post.comments %>      <%# cache aninhado por comment %>
<% end %>

<%# Em _comment.html.erb %>
<% cache comment do %>
  <p><%= comment.body %></p>
<% end %>
```

## Anti-padrões

| Padrão                                          | Substituir por                            |
|-------------------------------------------------|-------------------------------------------|
| Presenter (`UserPresenter#full_name`)           | Helper (`user_full_name(user)`)           |
| Lógica condicional complexa em view             | Método no model + helper                  |
| Query em view (`Post.published.each`)           | Controller injeta `@posts`                |
| `form_for` ou `form_tag`                        | `form_with`                               |
| `content_tag(:div, ...)`                        | `tag.div(...)`                            |
| `"<span>...".html_safe`                         | `tag.span(...)`                           |
| String literal PT-BR em view                    | `t(".chave")` + locale YAML               |
| Partial gigante (>100 linhas)                   | Divida em sub-partials                    |
| `render "users/list", locals: { ... }`          | Forma curta: `render partial:, locals:`   |

## Checklist antes de commitar uma view

- [ ] Sem queries ActiveRecord (movidas para controller)
- [ ] Sem lógica condicional complexa (movida para model/helper)
- [ ] Todas strings de texto usam `t(".chave")`
- [ ] `form_with model: @x` (não `form_for`/`form_tag`)
- [ ] Conteúdo do usuário escapado automaticamente OU explicitamente sanitizado
- [ ] Partials para markup reutilizável
- [ ] Helpers para formatação repetida
