# MIGRATIONS — Boas práticas de migrations em Rails

Leia este arquivo antes de criar ou alterar qualquer migration.

## Regra de ouro: use o generator

**SEMPRE** crie migrations via `bin/rails generate migration`, nunca manualmente.

```sh
# Adicionar coluna
bin/rails generate migration AddEmailToUsers email:string:index

# Criar tabela
bin/rails generate migration CreateInvoices customer:references amount:decimal status:string

# Remover coluna
bin/rails generate migration RemoveDeprecatedFieldFromUsers deprecated_field:string

# Adicionar índice composto
bin/rails generate migration AddIndexOnUsersEmailStatus
```

### Convenções de nomenclatura

O Rails infere a estrutura pelo nome:

| Padrão                       | Gera                                              |
|------------------------------|---------------------------------------------------|
| `AddXToY x:type`             | `add_column :y, :x, :type`                        |
| `RemoveXFromY x:type`        | `remove_column :y, :x, :type` (reversível)        |
| `CreateY ...`                | `create_table :y do |t| ... end`                  |
| `ChangeY ...`                | esqueleto vazio para alterações customizadas      |
| `AddReferenceToY z:references` | `add_reference :y, :z, foreign_key: true`       |

## Reversibilidade

Prefira `change` sempre que o Rails saiba reverter automaticamente:

```ruby
# OK — Rails sabe reverter
class AddEmailToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :email, :string, null: false
    add_index :users, :email, unique: true
  end
end
```

Use `up`/`down` apenas quando reversão for ambígua ou destrutiva:

```ruby
# Necessário: backfill em down não é trivial
class NormalizeUserEmailCase < ActiveRecord::Migration[8.0]
  def up
    User.update_all("email = LOWER(email)")
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
```

## Migrations seguras em produção

A gem [`strong_migrations`](https://github.com/ankane/strong_migrations) é altamente recomendada. Sem ela, siga estas regras manualmente:

### Adicionar coluna NOT NULL com dados existentes

**Ruim** (lock prolongado, falha se tabela tem linhas):
```ruby
add_column :users, :role, :string, null: false
```

**Bom** (3 passos em 3 deploys/migrations distintos):
```ruby
# Migration 1: adiciona nullable
add_column :users, :role, :string

# Em uma rake task ou job (NÃO em migration): backfill
User.in_batches.update_all(role: "member")

# Migration 2 (após deploy do backfill): aplica NOT NULL
change_column_null :users, :role, false
```

**Exceção Rails 7+**: adicionar coluna com `default` E `null: false` em uma única migration é seguro (não trava a tabela):
```ruby
add_column :users, :role, :string, default: "member", null: false
```

### Adicionar índice em tabela grande

**Ruim** (lock da tabela durante o índice):
```ruby
add_index :users, :email
```

**Bom** (CONCURRENTLY no PostgreSQL):
```ruby
class AddIndexOnUsersEmail < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :users, :email, algorithm: :concurrently
  end
end
```

### Renomear coluna

**Ruim** em produção ativa — código antigo continua referenciando o nome velho:
```ruby
rename_column :users, :name, :full_name
```

**Bom** (multi-deploy):
1. Adicione `full_name`, dual-write nos dois campos
2. Backfill `full_name` com `name`
3. Migre código para usar `full_name`
4. Remova `name` em deploy posterior

### Remover coluna

**Ruim** (queries antigas em workers podem quebrar):
```ruby
remove_column :users, :legacy_field, :string
```

**Bom**:
1. Adicione `self.ignored_columns += [:legacy_field]` no model
2. Deploy
3. Em migration posterior: `remove_column :users, :legacy_field, :string`

## Backfills nunca em migration

Migrations devem ser rápidas. Backfill grande trava deploy.

**Ruim**:
```ruby
class BackfillUserSlug < ActiveRecord::Migration[8.0]
  def change
    User.find_each { |u| u.update!(slug: u.name.parameterize) }
  end
end
```

**Bom**:
- Crie migration apenas para `add_column :users, :slug, :string`
- Crie rake task ou job dedicado para backfill
- Documente o passo no PR

```ruby
# lib/tasks/backfill_user_slug.rake
namespace :backfill do
  task user_slug: :environment do
    User.where(slug: nil).find_each(batch_size: 1000) do |u|
      u.update!(slug: u.name.parameterize)
    end
  end
end
```

## Foreign keys

Sempre defina FK explícita ao criar `references`:

```ruby
# Bom
add_reference :posts, :user, foreign_key: true, null: false

# Ruim — sem integridade referencial
add_reference :posts, :user
```

Quando opcional (associação que pode ser nula):
```ruby
add_reference :posts, :editor, foreign_key: { to_table: :users }, null: true
```

## Tipos de coluna preferidos

| Use            | Em vez de                          |
|----------------|------------------------------------|
| `references`   | `integer` + `add_index` manual     |
| `string`       | (até 255 chars, raramente `limit:`)|
| `text`         | textos longos                      |
| `bigint`       | `integer` para IDs ou contadores grandes |
| `decimal`      | valores monetários (com `precision:` e `scale:`) |
| `datetime`     | timestamps com timezone            |
| `boolean`      | flags                              |
| `jsonb`        | (PostgreSQL) blobs estruturados, com `default: {}` e `null: false` |

**Decimal para dinheiro**:
```ruby
add_column :invoices, :amount_cents, :integer, default: 0, null: false
# OU
add_column :invoices, :amount, :decimal, precision: 10, scale: 2, null: false
```

Prefira `amount_cents` (inteiro) sobre `amount` (decimal) para evitar erros de arredondamento.

## Timestamps obrigatórios

Toda `create_table` deve ter `t.timestamps`:

```ruby
create_table :invoices do |t|
  t.references :customer, foreign_key: true, null: false
  t.integer :amount_cents, null: false, default: 0
  t.string :status, null: false, default: "pending"
  t.timestamps
end
```

## schema.rb vs structure.sql

- **Default `schema.rb`** — funciona em 99% dos casos, suporta múltiplos bancos
- **Mude para `structure.sql`** apenas se usar features específicas do PostgreSQL não representáveis em `schema.rb`:
  - Triggers
  - Materialized views
  - Stored procedures
  - Extensions customizadas (PostGIS, pg_trgm com config específica)
  - Constraints complexas com `CHECK`

Configure em `config/application.rb`:
```ruby
config.active_record.schema_format = :sql
```

## Checklist antes de commitar uma migration

- [ ] Foi gerada com `bin/rails generate migration` (não criada manualmente)
- [ ] Usa `change` (não `up`/`down`) sempre que possível
- [ ] `null:` e `default:` explícitos em colunas novas
- [ ] FK com `foreign_key: true` em `references`
- [ ] Índices em colunas usadas em `where`, `order`, `join`
- [ ] Tabela grande? Índice com `algorithm: :concurrently` e `disable_ddl_transaction!`
- [ ] Sem `User.find_each` ou queries de backfill dentro da migration
- [ ] Versão da migration `[8.0]` corresponde à versão do Rails do projeto
- [ ] `t.timestamps` em `create_table`
- [ ] Foi executada localmente com `bin/rails db:migrate` E revertida com `bin/rails db:rollback` para validar reversibilidade
