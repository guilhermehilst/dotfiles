# BOAS PRÁTICAS — Princípios de testes, em qualquer linguagem

Leia este arquivo antes de escrever o primeiro teste da tarefa e revise os testes contra ele no REFACTOR.

Aqui estão os **princípios**. O **mecanismo** de cada stack (helper de tempo, biblioteca de fakes, convenções do framework) vem do projeto ou da skill de domínio — ex.: `travel_to` em [rails-puro/TESTING.md](../rails-puro/TESTING.md). Os exemplos abaixo são pseudocódigo.

## Determinismo

Um teste que passa hoje tem que passar amanhã, mês que vem, em outra máquina e em qualquer ordem.

### 1. Atemporal

O teste não pode depender do relógio real nem de datas absolutas que "envelhecem".

- Congele ou injete o relógio; derive todas as datas dele.
- Nunca use uma data fixa como "futuro" ou "passado" relativo a hoje.
- Cuidado com bordas de calendário: virada de mês/ano, 29 de fevereiro, fuso horário, horário de verão.

```
# Ruim — quebra quando 2026-12-31 passar
assinatura = Assinatura(expira_em: "2026-12-31")
assert assinatura.ativa?

# Ruim — depende do relógio real (e de que horas o teste roda)
assinatura = Assinatura(expira_em: now() + 1.dia)

# Bom — relógio congelado, datas relativas a ele
congelar_relogio("2026-01-15 12:00") do
  assinatura = Assinatura(expira_em: hoje() + 1.dia)
  assert assinatura.ativa?
end
```

Uma data literal é aceitável **dentro** de um relógio congelado — o que não pode é ela ser comparada com o tempo real.

### 2. Sem aleatoriedade solta

Valores aleatórios só com seed fixa, ou quando não influenciam a asserção (ex.: um e-mail único qualquer). Se o teste falha "às vezes", procure aleatoriedade.

### 3. Independente de ordem

Cada teste monta e limpa o próprio estado. Nenhum teste depende de outro ter rodado antes; nada de estado global ou singleton mutado sem reset. A suíte deve passar com ordem aleatória.

### 4. Sem rede nem serviços externos reais

Nada de HTTP, filas, e-mail ou APIs de terceiros de verdade. Use fake/stub na fronteira. Banco de dados de teste do próprio projeto é aceitável.

### 5. Independente de ambiente

Não dependa de locale, fuso horário da máquina, variáveis de ambiente não definidas pelo teste, caminhos absolutos ou arquivos fora do repositório. Se precisar de um, defina explicitamente no teste.

## Clareza

Um teste é documentação executável: quem lê precisa entender o comportamento sem abrir a implementação.

### 6. Comportamento, não implementação

Asserte o resultado observável (retorno, estado persistido, efeito na fronteira). Não teste métodos privados nem a ordem interna de chamadas — refatorar sem mudar comportamento não deve quebrar testes.

### 7. Um comportamento por teste

Cada teste verifica uma coisa, e o nome descreve essa coisa:

```
# Ruim
test "pedido"

# Bom
test "rejeita pedido sem itens"
test "aplica frete grátis acima de 200"
```

### 8. Arrange-Act-Assert visível

Três blocos claros: preparar, executar, verificar. O dado que importa para o comportamento fica **explícito no próprio teste**, não escondido num setup distante ou numa factory com defaults mágicos.

### 9. Valores literais esperados

O esperado é um valor fixo, não recalculado com a mesma lógica da produção — senão o teste replica o bug.

```
# Ruim
assert total(itens) == itens.soma(preco) * (1 - DESCONTO)

# Bom
assert total(itens) == 90.00
```

## Confiabilidade

### 10. Mock só na fronteira

Substitua apenas o que é lento, não determinístico ou externo: I/O, tempo, rede, serviços de terceiros. Nunca mocke o objeto sob teste nem colaboradores internos baratos — use os reais. Detalhes em [Mocks e doubles](#mocks-e-doubles).

### 11. Sem `sleep`

Não espere processos assíncronos com pausas fixas. Use os mecanismos de sincronização do framework ou polling com timeout. `sleep` deixa o teste lento e ainda assim instável.

### 12. Flaky é bug

Teste que falha às vezes está apontando um problema (no teste ou no código). Investigue e corrija a causa — quase sempre um dos itens de Determinismo. Nunca adicione retry nem marque como "pular" para silenciar.

## Mocks e doubles

Complementam o item 10. Um double serve para isolar, não para ser testado.

### 13. Não asserte o mock

Verifique o comportamento do código real, não que o double existe ou foi chamado. A exceção é quando a chamada na fronteira **é** o comportamento (ex.: "envia o e-mail de boas-vindas").

```
# Ruim — prova que o fake funciona, não o cálculo
calculadora = fake(Frete, calcular: 15.0)
pedido = Pedido(itens, frete: calculadora)
assert calculadora.calcular foi chamado

# Bom — prova o efeito no objeto sob teste
calculadora = fake(Frete, calcular: 15.0)
pedido = Pedido(itens, frete: calculadora)
assert pedido.total == 115.00
```

### 14. Sem métodos só para teste em produção

Não adicione a classes de produção métodos que só os testes chamam (`reset!`, `limpar_tudo`, getters de estado interno). Limpeza e inspeção vão para helpers de teste. Método em produção parece API pública e pode ser chamado por engano.

### 15. Entenda antes de mockar

Antes de substituir um método, saiba que efeitos colaterais ele tem e se o teste depende deles. Mocke no nível mais baixo possível — a parte lenta ou externa (HTTP, disco, fila) —, não o método de alto nível cujo efeito o teste precisa. Na dúvida, rode primeiro com a implementação real e observe o que acontece.

### 16. Double completo

O double reproduz a estrutura real (todos os campos que o sistema consome), não só os campos que o teste olha. Double parcial passa no teste e quebra na integração quando outro trecho do código acessa um campo omitido. Baseie-se no contrato real (docs, schema, resposta de exemplo).

### 17. Mock complexo demais é sinal

Se o setup dos doubles é maior que o teste, ou o teste quebra sempre que o mock muda, prefira um teste de integração com componentes reais — ou simplifique o design (ver "Travou? Escute o teste" no SKILL.md).
