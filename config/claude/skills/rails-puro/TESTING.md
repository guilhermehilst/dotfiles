# TESTING — Boas práticas de testes em Rails

Leia este arquivo antes de escrever ou alterar testes.

## Preferência: MiniTest + fixtures

O Rails vem com MiniTest e fixtures por default. Use isso, a menos que o projeto já adote outro stack.

## Detectar o stack do projeto

Antes de escrever testes, verifique o que está em uso:

```sh
# RSpec?
test -d spec && grep -q "rspec-rails" Gemfile && echo "Use RSpec"

# Factory Bot?
grep -q "factory_bot" Gemfile && echo "Factory Bot disponível"

# MiniTest puro?
test -d test && ! test -d spec && echo "Use MiniTest"
```

Regras:
- `spec/` existe + `rspec-rails` no Gemfile → use **RSpec**
- `test/` existe e nada de RSpec → use **MiniTest** com fixtures
- `factory_bot` no Gemfile → use **Factory Bot**; senão, **fixtures YAML**
- Usuário pediu explicitamente um stack → respeite

## Estrutura de testes (Rails 7+/8 com MiniTest)

```
test/
├── application_system_test_case.rb
├── test_helper.rb
├── channels/
├── controllers/      # request-style tests
├── fixtures/         # YAML por tabela
├── helpers/
├── integration/      # fluxos cross-controller
├── jobs/
├── mailers/
├── models/
└── system/           # E2E com Capybara
```

## Fixtures

YAML em `test/fixtures/<table>.yml`. Referencie outras fixtures por nome:

```yaml
# test/fixtures/users.yml
alice:
  name: Alice
  email: alice@example.com
  role: admin
  created_at: <%= 30.days.ago %>

bob:
  name: Bob
  email: bob@example.com
  role: member
```

```yaml
# test/fixtures/posts.yml
hello_world:
  user: alice           # referência por nome
  title: "Hello World"
  body: "First post"
  published_at: <%= 1.day.ago %>
```

Use a fixture nos testes:

```ruby
test "alice can edit her own post" do
  user = users(:alice)
  post = posts(:hello_world)
  assert user.can_edit?(post)
end
```

### Regras para fixtures
- **Reutilize**: não crie `alice2`, `alice3` — varie pelos testes via `update!`
- **ERB com parcimônia**: `<%= 30.days.ago %>` é OK; lógica complexa não
- **Cobre estados representativos**: ativo, inativo, admin, etc. — não 50 variações
- **Determinístico**: nunca `Faker` em fixtures (gera flakes)
- **Não duplique entre tabelas**: use `<<: *defaults` (anchors YAML)

## Boas práticas de teste

### Tipos de assert e quando usar

```ruby
# Mudança de count (criação/deleção)
assert_difference "Post.count", 1 do
  post :create, params: { post: { title: "x" } }
end

assert_no_difference "Post.count" do
  post :create, params: { post: { title: "" } }
end

# Mudança de estado
assert_changes -> { user.reload.status }, from: "pending", to: "active" do
  user.activate!
end

assert_no_changes -> { user.reload.email } do
  user.update(name: "Other Name")
end

# Jobs enfileirados
assert_enqueued_with(job: WelcomeEmailJob, args: [user.id]) do
  User.create!(email: "x@example.com")
end

# Emails
assert_emails 1 do
  UserMailer.welcome(user).deliver_later
end

# Tempo
travel_to Time.zone.local(2026, 1, 1) do
  assert_equal 2026, User.new.created_at.year
end
```

### Não mocke `Time.now`/`DateTime.now`

Use `travel_to`, `travel`, `freeze_time` do `ActiveSupport::Testing::TimeHelpers`:

```ruby
# Bom
travel_to 1.day.from_now do
  assert_equal Date.tomorrow, Date.current
end

# Ruim
Time.stubs(:now).returns(Time.zone.local(2026, 1, 1))
```

### Um conceito por teste — não um assert

Vários `assert_*` no mesmo teste é OK se testam o mesmo conceito:

```ruby
test "user is created with default role" do
  user = User.create!(email: "x@example.com")
  assert user.persisted?
  assert_equal "member", user.role
  assert_not_nil user.created_at
end
```

Mas separe se forem caminhos diferentes:

```ruby
test "invalid email is rejected" do
  user = User.new(email: "invalid")
  assert_not user.valid?
  assert_includes user.errors[:email], "is invalid"
end

test "duplicate email is rejected" do
  User.create!(email: "x@example.com")
  user = User.new(email: "x@example.com")
  assert_not user.valid?
  assert_includes user.errors[:email], "has already been taken"
end
```

## Tipos de teste

### Model test (`test/models/user_test.rb`)

```ruby
require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid with required fields" do
    user = User.new(email: "x@example.com", name: "X")
    assert user.valid?
  end

  test "requires email" do
    user = User.new(name: "X")
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "active scope returns only active users" do
    assert_includes User.active, users(:alice)
    assert_not_includes User.active, users(:archived_user)
  end

  test "full_name combines first and last" do
    user = User.new(first_name: "Alice", last_name: "Wonder")
    assert_equal "Alice Wonder", user.full_name
  end
end
```

### Controller test (request-style, preferido)

```ruby
require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in users(:alice) }

  test "index lists users" do
    get users_url
    assert_response :success
    assert_select "h1", "Usuários"
  end

  test "create with valid params" do
    assert_difference "User.count", 1 do
      post users_url, params: { user: { email: "new@example.com", name: "New" } }
    end
    assert_redirected_to user_url(User.last)
  end

  test "create with invalid params re-renders form" do
    assert_no_difference "User.count" do
      post users_url, params: { user: { email: "" } }
    end
    assert_response :unprocessable_entity
  end
end
```

### System test (E2E com Capybara)

```ruby
require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
  test "criar usuário pelo formulário" do
    visit new_user_url
    fill_in "Email", with: "novo@example.com"
    fill_in "Nome", with: "Novo Usuário"
    click_button "Criar"

    assert_text "Usuário criado com sucesso"
    assert_current_path user_path(User.last)
  end
end
```

**Use seletores semânticos**: `fill_in "Email"`, `click_button "Criar"`, `find_button`, `find_link`. Evite CSS frágil (`find(".btn-primary.large")`).

**Driver**: `headless_chrome` por padrão em CI:

```ruby
# test/application_system_test_case.rb
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
end
```

### Job test

```ruby
require "test_helper"

class WelcomeEmailJobTest < ActiveJob::TestCase
  test "envia email para o usuário" do
    user = users(:alice)
    assert_emails 1 do
      WelcomeEmailJob.perform_now(user.id)
    end
  end

  test "discard quando user não existe" do
    assert_no_emails do
      WelcomeEmailJob.perform_now(999_999)
    end
  end
end
```

### Mailer test

```ruby
require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "welcome email" do
    user = users(:alice)
    email = UserMailer.welcome(user)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal ["alice@example.com"], email.to
    assert_equal "Bem-vinda, Alice", email.subject
    assert_match "Olá, Alice", email.body.encoded
  end
end
```

## Parallel testing

Ativo por default em Rails 6+. Cada worker recebe banco isolado (`test-0`, `test-1`...). Cuidado com:

- Fixtures que dependem de IDs hardcoded (use referências por nome)
- Side effects globais (Redis, arquivos no disco) — use sufixo do worker
- Mocks globais que vazam entre testes

Configurado em `test/test_helper.rb`:

```ruby
class ActiveSupport::TestCase
  parallelize(workers: :number_of_processors)
  fixtures :all
end
```

## Anti-padrões

- **Mock excessivo**: prefira fixtures + integração real. Mocks ficam datados.
- **Testar Rails**: `assert_equal "Alice", User.new(name: "Alice").name` testa o setter do Ruby, não seu código.
- **Testes que dependem de ordem**: sempre criar/limpar via fixtures + transactional fixtures
- **`sleep` em system tests**: use `assert_text` (que tem retry automático) em vez de `sleep 2`
- **Teste para cada getter/setter** sem lógica: ruído puro
- **Fixtures com `Faker`**: não-determinístico, gera flakes
- **Setup gigante de 50 linhas**: divida em testes menores ou crie fixture específica

## Quando o projeto usa RSpec

Convenções gerais (siga o que o projeto já faz):

```ruby
# spec/models/user_spec.rb
require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
  end

  describe "associations" do
    it { should have_many(:posts).dependent(:destroy) }
  end

  describe ".active" do
    let!(:active_user) { create(:user, status: :active) }
    let!(:archived_user) { create(:user, status: :archived) }

    it "retorna apenas usuários ativos" do
      expect(User.active).to include(active_user)
      expect(User.active).not_to include(archived_user)
    end
  end

  describe "#full_name" do
    subject(:user) { build(:user, first_name: "Alice", last_name: "Wonder") }

    it { expect(user.full_name).to eq("Alice Wonder") }
  end
end
```

Padrões:
- `describe` para classes/métodos (`.class_method`, `#instance_method`)
- `context` para condições (`when admin`, `when archived`)
- `it` curto, descritivo, em português ou inglês conforme o projeto
- `let`/`let!` para setup; `subject` para o objeto sob teste
- `build` para objetos não-persistidos; `create` quando precisa do registro no DB
- `shoulda-matchers` para validações e associações

## Checklist antes de commitar testes

- [ ] Teste passa isoladamente: `bin/rails test test/models/user_test.rb -n test_email_required`
- [ ] Suite inteira passa: `bin/rails test`
- [ ] Sem warnings de fixtures duplicadas ou referências quebradas
- [ ] Sem `puts`, `binding.irb`, `byebug` esquecidos
- [ ] System tests não dependem de `sleep` arbitrário
- [ ] Nomes de teste descrevem o **comportamento** (`test "rejects invalid email"`) não o método (`test "validates_format"`)
