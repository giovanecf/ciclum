# Ciclum — Ciclo de estudos

Aplicação para planejar e acompanhar ciclos contínuos de estudo. Em desenvolvimento no Olympus, usa PostgreSQL compartilhado com a infraestrutura. Cada conta tem seus próprios ciclos, disciplinas e sessões.

## Requisitos

- Ruby 3.2 ou superior
- Bundler

## Executar no Olympus dev

```bash
../olympus/olymctl dev up ciclum
```

Abra <http://ciclum.farmacia.local/>. O serviço prepara o banco `ciclum_development` no `postgres-db` compartilhado ao iniciar. O primeiro acesso prepara o ciclo Default (1.440 min) automaticamente; rodar o seed novamente preserva alterações e ciclos ativos existentes.

Crie uma conta em <http://ciclum.farmacia.local/cadastro/>. Depois, entre com e-mail e senha em <http://ciclum.farmacia.local/entrar/>. Registros antigos sem proprietário são associados à primeira conta criada após a atualização.

O Caddy do Olympus encaminha o domínio local ao servidor Rails. Esta aplicação não foi projetada para exposição pública.

## Testes

```bash
bin/rails test
```

## Uso

Cadastre as disciplinas pelo nome e configure os minutos práticos depois. Sugestões dependem das questões e pontos cadastrados e nunca mudam a meta prática automaticamente. Sessões podem ser lançadas para qualquer disciplina disponível; o estudo de outra disciplina gera crédito para quando a rotação a alcançar. Edite ou arquive disciplinas sem perder sessões históricas.

A data da sessão informa quando o estudo ocorreu e alimenta os totais Hoje/Semana/Mês/Total. Para a rotação, cada sessão conserva a sequência original de lançamento. Alterar sua data não muda essa sequência; editar ou excluir sessões refaz o cálculo da rotação.
