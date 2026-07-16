# BACKGROUND_JOBS — Boas práticas com jobs assíncronos

Leia antes de criar/alterar jobs ou enfileirar trabalho assíncrono.

## ActiveJob como interface, sempre

Use `ApplicationJob` como base, independente do adapter (SolidQueue, Sidekiq, GoodJob, Resque):

```ruby
# app/jobs/application_job.rb
class ApplicationJob < ActiveJob::Base
  retry_on ActiveRecord::Deadlocked
  discard_on ActiveJob::DeserializationError
end
```

## Detectar o adapter do projeto

```sh
grep -E "adapter|active_job" config/application.rb config/environments/production.rb
grep -E "solid_queue|sidekiq|good_job|resque" Gemfile
```

Adapters comuns:
- **SolidQueue** — default em Rails 8, no banco (Postgres/MySQL/SQLite)
- **Sidekiq** — Redis, muito comum em produção
- **GoodJob** — PostgreSQL, single-process friendly
- **Resque** — Redis, legado

## Gerar jobs com o generator

```sh
bin/rails generate job WelcomeEmail
bin/rails generate job ProcessUpload
```

Gera:
```ruby
# app/jobs/welcome_email_job.rb
class WelcomeEmailJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find_by(id: user_id)
    return if user.nil?

    UserMailer.welcome(user).deliver_now
  end
end
```

## Quando usar um job

✅ Bons casos:
- Envio de email (`UserMailer.welcome(user).deliver_later`)
- Integração com API externa (webhook, pagamento, OCR)
- Processamento de arquivo grande (importação CSV)
- Recálculo de estatísticas
- Notificações push
- Indexação de busca

❌ Casos onde job é exagero:
- Operação rápida (<100ms) — faça síncrono
- Validação — deve ser síncrona, com resposta imediata
- Lógica crítica de UX que o usuário espera ver na hora

## Argumentos: passe IDs ou GlobalID

```ruby
# Bom — ID escalar
WelcomeEmailJob.perform_later(user.id)

# Bom — GlobalID (Rails serializa automaticamente)
WelcomeEmailJob.perform_later(user)

# Ruim — atributos serializados podem ficar desatualizados ao executar
WelcomeEmailJob.perform_later(user.attributes)

# Crítico — instância grande não-serializável
WelcomeEmailJob.perform_later(user, ActiveRecord::Relation)
```

Por que IDs/GlobalID: o job pode rodar minutos/horas depois. O estado pode ter mudado. Sempre recarregue dentro do `perform`.

## Idempotência

Jobs **podem** rodar mais de uma vez (retry, requeue, falha de rede). Faça-os seguros:

```ruby
# Ruim — re-execução duplica o email
class WelcomeEmailJob < ApplicationJob
  def perform(user_id)
    user = User.find(user_id)
    UserMailer.welcome(user).deliver_now
  end
end

# Bom — checa estado antes de agir
class WelcomeEmailJob < ApplicationJob
  def perform(user_id)
    user = User.find(user_id)
    return if user.welcome_email_sent_at?

    UserMailer.welcome(user).deliver_now
    user.update_column(:welcome_email_sent_at, Time.current)
  end
end
```

### Padrões de idempotência

```ruby
# Find or create
def perform(invoice_id)
  invoice = Invoice.find(invoice_id)
  Payment.find_or_create_by!(invoice: invoice) do |p|
    p.amount_cents = invoice.amount_cents
  end
end

# Update com WHERE de estado
def perform(user_id)
  User.where(id: user_id, confirmation_sent_at: nil)
      .update_all(confirmation_sent_at: Time.current)
  # se outro processo já tocou, este UPDATE não faz nada
end

# Chave única no banco
add_index :payments, [:invoice_id, :external_id], unique: true
```

## Retries e descarte

```ruby
class SendWebhookJob < ApplicationJob
  queue_as :webhooks

  retry_on Net::ReadTimeout, wait: :polynomially_longer, attempts: 5
  retry_on RateLimitError, wait: 1.minute, attempts: 10
  discard_on ActiveRecord::RecordNotFound

  def perform(webhook_id)
    webhook = Webhook.find(webhook_id)
    response = HTTP.post(webhook.url, json: webhook.payload)
    webhook.update!(response_code: response.code)
  end
end
```

### Estratégias de wait

- `:polynomially_longer` (default) — 3s, 18s, 83s, 258s...
- `wait: 5.seconds` — fixo
- Lambda customizada: `wait: ->(executions) { executions ** 4 }`

### Quando usar `discard_on`

- Erros que não devem retrybar: `ActiveRecord::RecordNotFound`, `ActiveJob::DeserializationError`
- Erros permanentes do domínio (recurso não existe mais)

## Filas por prioridade

Use múltiplas filas para isolar workloads críticos:

```ruby
class WelcomeEmailJob < ApplicationJob
  queue_as :mailers
end

class CleanupOldLogsJob < ApplicationJob
  queue_as :low
end

class PaymentProcessingJob < ApplicationJob
  queue_as :critical
end
```

Configuração de workers (SolidQueue exemplo):

```yaml
# config/queue.yml
production:
  dispatchers:
    - polling_interval: 1
      batch_size: 500
  workers:
    - queues: [critical]
      threads: 5
      processes: 2
    - queues: [default, mailers]
      threads: 5
      processes: 2
    - queues: [low]
      threads: 1
      processes: 1
```

Sidekiq:
```yaml
# config/sidekiq.yml
:queues:
  - [critical, 4]
  - [default, 2]
  - [mailers, 2]
  - [low, 1]
```

## Mailers — sempre `deliver_later`

```ruby
# Bom — assíncrono via ActiveJob
UserMailer.welcome(user).deliver_later

# Só para casos críticos síncronos
UserMailer.welcome(user).deliver_now
```

## Agendamento (recurring jobs)

### SolidQueue
```yaml
# config/recurring.yml
production:
  daily_cleanup:
    class: CleanupOldLogsJob
    queue: low
    schedule: every day at 3am
```

### Sidekiq
- `sidekiq-cron` ou `sidekiq-scheduler` para periodic
- ❌ Evite `whenever` se Sidekiq já está no projeto

## Cuidados especiais

### Job que enfileira N jobs filhos

```ruby
# Cuidado — explosão de fila
class NotifyAllUsersJob < ApplicationJob
  def perform
    User.find_each { |u| NotifyUserJob.perform_later(u.id) }
  end
end
```

Para 10M usuários, isso cria 10M jobs. Considere:
- **Batches** — Sidekiq Batches ou job que divide em chunks
- **Time-spread** — agendar com offset: `NotifyUserJob.set(wait: rand(1.hour)).perform_later(u.id)`

### Job que faz lógica de domínio complexa

Mantenha jobs como **orquestradores finos**. A lógica pesada vai no model:

```ruby
# Bom
class GenerateInvoiceJob < ApplicationJob
  def perform(customer_id, period)
    customer = Customer.find(customer_id)
    customer.generate_invoice_for(period)
  end
end

class Customer < ApplicationRecord
  def generate_invoice_for(period)
    # toda a lógica aqui — testável sem fila
  end
end
```

```ruby
# Ruim — job com 100 linhas de lógica
class GenerateInvoiceJob < ApplicationJob
  def perform(customer_id, period)
    # ...100 linhas de lógica de domínio...
  end
end
```

### Logs e observabilidade

```ruby
class SendWebhookJob < ApplicationJob
  around_perform do |job, block|
    Rails.logger.tagged("webhook", job.arguments.first) do
      block.call
    end
  end
end
```

Para APMs: Sidekiq/SolidQueue se integram com Scout, NewRelic, Skylight automaticamente.

## Testando jobs

Ver [TESTING.md](TESTING.md) seção "Job test". Resumo:

```ruby
class WelcomeEmailJobTest < ActiveJob::TestCase
  test "envia email" do
    user = users(:alice)
    assert_emails 1 do
      WelcomeEmailJob.perform_now(user.id)
    end
  end
end
```

Em controller tests, verifique que o job foi enfileirado:

```ruby
test "criar user enfileira welcome email" do
  assert_enqueued_with(job: WelcomeEmailJob) do
    post users_url, params: { user: { email: "x@example.com", name: "X" } }
  end
end
```

## Anti-padrões

| Padrão                                       | Substituir por                                  |
|----------------------------------------------|-------------------------------------------------|
| Passar `user` com `attributes` serializados  | Passar `user.id` ou `user` (GlobalID)           |
| Job que não checa estado antes de agir       | Idempotência com check ou unique constraint     |
| `rescue Exception` que silencia erros        | `retry_on` ou `discard_on` específico           |
| Lógica de 100 linhas no job                  | Mover para método de domínio no model           |
| `deliver_now` em mailers fora de testes      | `deliver_later`                                 |
| Job sem `queue_as` (tudo cai em `:default`)  | Filas por workload crítico/normal/baixa         |
| `Sidekiq::Worker` direto                     | `ApplicationJob` (ActiveJob)                    |

## Checklist antes de commitar um job

- [ ] Herda de `ApplicationJob` (não `Sidekiq::Worker` direto)
- [ ] `queue_as :nome_apropriado`
- [ ] Argumentos são IDs ou GlobalID, não atributos
- [ ] É idempotente (checa estado, find_or_create, unique constraint)
- [ ] `retry_on` para erros transitórios
- [ ] `discard_on` para `RecordNotFound` e similares
- [ ] Lógica pesada delegada ao model
- [ ] Teste cobre caminho feliz E erros (record não existe, retry, etc.)
- [ ] Mailers chamados com `deliver_later`
