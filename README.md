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

## Preparação para produção no Olympus

O Ciclum está configurado para ser servido pelo Caddy compartilhado do Olympus em `https://ciclum.farmacia.ufmg.br`. A base SQLite e os bancos locais de cache e fila ficam em `/rails/storage`, montado no volume persistente `ciclum-storage`.

Antes do primeiro deploy, crie `ciclum/.env.production` a partir de `.env.production.example` e informe o conteúdo de `config/master.key` em `RAILS_MASTER_KEY`. Inclua `ciclum-storage` no plano de backup.

Crie uma conta em <http://ciclum.farmacia.local/cadastro/>. Depois, entre com e-mail e senha em <http://ciclum.farmacia.local/entrar/>. Registros antigos sem proprietário são associados à primeira conta permanente criada após a atualização.

Também é possível continuar como visitante pela tela de entrada. Ciclos, disciplinas e sessões do visitante ficam no PostgreSQL; o navegador guarda somente o token da sessão. A sessão é encerrada ao sair e os dados são removidos após 24 horas sem atividade. Se criar uma conta durante a sessão, os ciclos são transferidos para a conta permanente.

O Caddy do Olympus encaminha o domínio local ao servidor Rails. Esta aplicação não foi projetada para exposição pública.

## Testes

```bash
bin/rails test
```

## Uso

Cadastre as disciplinas pelo nome e configure os minutos práticos depois. Sugestões dependem das questões e pontos cadastrados e nunca mudam a meta prática automaticamente. Sessões podem ser lançadas para qualquer disciplina disponível; o estudo de outra disciplina gera crédito para quando a rotação a alcançar. Edite ou arquive disciplinas sem perder sessões históricas.

A data da sessão informa quando o estudo ocorreu e alimenta os totais Hoje/Semana/Mês/Total. Para a rotação, cada sessão conserva a sequência original de lançamento. Alterar sua data não muda essa sequência; editar ou excluir sessões refaz o cálculo da rotação.
