# Especificação funcional e técnica — Aplicação local de Ciclo de Estudos

> **Instrução para o Codex:** implemente uma aplicação web funcional, do início ao fim, conforme esta especificação. Não entregue apenas protótipos, wireframes ou pseudocódigo. Crie o projeto Rails, migrations, models, services, controllers, views, estilos, testes e documentação para executá-lo localmente. Tome decisões técnicas pequenas quando necessário, mas **não altere as regras de negócio** descritas aqui. Priorize simplicidade de uso, legibilidade e correção dos recálculos.

## 1. Visão geral

Aplicação pessoal para planejar e acompanhar **ciclos contínuos de estudo para concursos públicos**, inspirada na ideia de ciclo de estudos descrita por Alexandre Meirelles, mas com regras de créditos e edição definidas especificamente neste documento. Não se trata de agenda por dias da semana nem de um sistema que zera o progresso a cada segunda-feira.

O usuário define disciplinas e a quantidade **prática** de minutos que deseja estudar em cada passagem pelo ciclo. Ao registrar sessões, o sistema desconta os minutos da disciplina atual, avança automaticamente quando a meta é cumprida e guarda excedentes ou estudos de outras disciplinas como créditos para a próxima passagem pertinente.

Uma carga **semanal de referência** serve como parâmetro para sugestões e proporções; **não é limite**, nem determina a duração, o fechamento ou o reinício do ciclo.

### 1.1. Decisões fechadas

- Uso **individual e somente no próprio computador**; **sem login**, contas, cadastro de usuários ou autenticação.
- Aplicação web **Ruby on Rails + Bootstrap**, com **SQLite** como banco de dados local.
- Sem hospedagem, domínio, serviços externos, integração em nuvem ou acesso pela rede local.
- Sem importação CSV/Excel, sem recurso de backup dentro da aplicação e sem necessidade de migrar planilhas antigas.
- Todo o planejamento e as sessões usam **minutos inteiros** como unidade de entrada, armazenamento, cálculo e exibição principal. Não exigir formato `hh:mm`.
- Pode haver vários ciclos cadastrados, mas **apenas um ciclo ativo por vez**. Alternar ciclos mantém o estado do ciclo anterior.
- Ciclo contínuo: **não reiniciar por semana, mês, virada do dia ou passagem de calendário**.
- Disciplinas podem ser adicionadas, editadas, reordenadas e retiradas da rotação a qualquer momento, preservando histórico.
- Sessões de estudo podem ser criadas, editadas e excluídas; toda alteração recalcula progresso e créditos.

## 2. Requisito obrigatório do primeiro uso: ciclo Default

**Ao instalar/inicializar o banco de dados, a aplicação já deve ter exatamente um ciclo inicial pré-cadastrado:**

| Campo | Valor inicial |
|---|---|
| Nome | `Default` |
| Carga semanal de referência | `1440` minutos |
| Equivalência informativa | 24 horas |
| Status | **Ativo** |
| Disciplinas | Nenhuma |
| Sessões registradas | Nenhuma |
| Créditos | Nenhum |

**Comportamento exigido:** ao acessar `http://127.0.0.1:4000/` pela primeira vez, abrir **diretamente o dashboard do ciclo Default**. Não exigir que o usuário crie um ciclo, faça cadastro, responda a questionário ou execute um assistente inicial. Mostrar um estado vazio amigável, com ação evidente **“Adicionar disciplina”**. O usuário poderá imediatamente adicionar matérias ao ciclo existente.

Implementar o cadastro inicial de forma **idempotente** em `db/seeds.rb` ou mecanismo equivalente: rodar seed novamente **não** pode duplicar `Default`, apagar disciplinas, restaurar a carga que tenha sido alterada pelo usuário nem tomar a ativação de outro ciclo. Usar uma chave interna estável para reconhecer o ciclo inicial; o nome visível poderá ser editado sem recriá-lo.

## 3. Conceitos e distinções importantes

### 3.1. Ciclo

Um ciclo é uma sequência **ordenada e circular** de disciplinas. Ao terminar a última, volta para a primeira, indefinidamente. Essa passagem completa pode ser chamada de **volta do ciclo** ou **rodada**. A rodada **não** corresponde necessariamente a uma semana.

### 3.2. Disciplina atual

É a disciplina na qual a rotação está posicionada agora. O dashboard deve dizer qual é e quantos minutos faltam para completar sua **passagem atual**.

### 3.3. Minutos sugeridos, minutos práticos e referência

São conceitos **diferentes**, e a interface deve deixar isso claro:

1. **Referência semanal do ciclo:** por padrão, 1.440 minutos. É apenas uma base de cálculo e comparação, não um teto.
2. **Minutos sugeridos da disciplina:** cálculo orientativo baseado na participação nos pontos da prova e no conhecimento declarado pelo usuário.
3. **Minutos práticos/configurados da disciplina:** meta que **de fato controla a passagem pelo ciclo**. Pode ser igual à sugestão ou modificada manualmente.

Exemplo: o sistema pode sugerir **180 min** para Português e o usuário definir **190 min práticos**. Ambos os valores devem aparecer. A soma de minutos práticos das disciplinas pode ficar abaixo ou acima da referência semanal, sem impedir salvamento.

Os percentuais individuais configurados **não precisam somar 100%**: é permitido ter, por exemplo, 50% da referência em uma disciplina e 60% em outra (total 110%). Não ajustar ou distribuir automaticamente a diferença para “fechar” 100%.

### 3.4. Crédito

**Crédito** é tempo já estudado que ainda não foi consumido pela meta de uma passagem da disciplina. Pode surgir de duas formas:

- O usuário estuda mais minutos do que faltava na disciplina atual.
- O usuário registra estudo de outra disciplina que **não é a atual** (seleção manual no formulário), ou reduz a meta da disciplina atual para menos do que já foi consumido nela.

Esse crédito fica **vinculado à própria disciplina** e é aproveitado quando ela voltar a ser visitada na sequência. Não transferir crédito entre disciplinas e não descartar excedentes.

## 4. Fluxos de interface

### 4.1. Dashboard — página inicial `/`

O dashboard do ciclo ativo deve priorizar visualmente:

- **Disciplina atual** (destaque principal).
- **Minutos restantes para terminar a passagem atual** (valor em destaque).
- **Próxima disciplina efetiva** na sequência (considerando eventuais passagens automaticamente cobertas por créditos).
- Progresso da passagem atual: consumido / meta prática e barra de progresso.
- Botão em destaque **“Adicionar sessão de estudo”**.
- **Quatro indicadores compactos de tempo efetivamente estudado**: **Hoje**, **Semana**, **Mês** e **Total**, segundo a seção 4.1.1. Eles devem ficar visíveis no mini-dashboard, sem exigir navegação para outra página.

Em uma área secundária, mostrar o nome do ciclo ativo, referência semanal, soma dos minutos práticos configurados, diferença entre soma prática e referência, número de voltas concluídas e lista resumida de disciplinas com metas, sugestões e créditos.

Se não houver disciplina pronta para a rotação, mostrar orientação curta e botão **“Adicionar disciplina”**, sem mensagem de erro.

**Não é necessário cronômetro, Pomodoro, agenda, calendário semanal ou notificações** na versão inicial. O registro de estudo é manual.

### 4.1.1. Indicadores do mini-dashboard: Hoje, Semana, Mês e Total

Exibir quatro indicadores de **minutos efetivamente estudados**, próximos ao destaque da disciplina atual ou imediatamente abaixo dele, em quatro cartões compactos (responsivos no Bootstrap):

| Indicador | Intervalo de apuração |
|---|---|
| **Hoje** | Sessões cuja `studied_on` é a **data local atual** (`Date.current`, timezone `America/Sao_Paulo`) |
| **Semana** | Sessões de **segunda-feira a domingo da semana corrente**, inclusive, considerando a data local atual |
| **Mês** | Sessões do **primeiro ao último dia do mês calendário corrente**, inclusive |
| **Total** | **Todas** as sessões válidas do ciclo ativo, sem restrição de data |

**Escopo:** os quatro indicadores mostram somente sessões pertencentes ao **ciclo ativo**. Trocar de ciclo muda os números exibidos; cada ciclo preserva suas próprias sessões. Incluir sessões de disciplinas arquivadas, porque são tempo de estudo real daquele ciclo. Em ciclos sem sessões, mostrar **`0 min / 0 h`** nos quatro cartões.

**Apuração:** somar o campo `minutes` das sessões registradas **uma única vez por sessão**, usando **`studied_on`**, não `created_at`/`updated_at` nem a data em que o registro foi lançado. Minutos de crédito são apenas um mecanismo de alocação na rotação: **não são novo estudo e não devem ser somados novamente**. As metas e sugestões também não contam como tempo realizado. A virada do dia, da semana ou do mês **não reinicia o ciclo de disciplinas**; altera somente quais sessões entram nos indicadores por período.

**Exibição obrigatória:** apresentar primeiro os minutos em tamanho principal e, **na mesma linha, à direita**, a equivalência em horas em tipografia secundária menor, por exemplo com `<small class="text-muted">` no template ERB, sem mostrar HTML literal. Exemplos:

- `60 min / 1 h`
- `90 min / 1,5 h`
- `75 min / 1,25 h`
- `30 min / 0,5 h`
- `0 min / 0 h`

Calcular `horas = minutos / 60.0` **somente para apresentação**. Exibir até **duas casas decimais**, arredondadas e sem zeros decimais desnecessários; usar **vírgula decimal (pt-BR)**. As horas apresentadas podem ser aproximadas pelo arredondamento, mas todos os cálculos internos continuam em **minutos inteiros**. Exemplo de estrutura visual (adaptável ao ERB):

```html
<div class="card-body">
  <div class="text-muted">Hoje</div>
  <strong>60 min</strong>
  <small class="text-muted"> / 1 h</small>
</div>
```

**Atualização:** os quatro indicadores são recalculados imediatamente ao **criar, editar (minutos, disciplina ou data) ou excluir** uma sessão. Uma sessão retroativa entra no período da `studied_on` informada, mesmo se tiver sido cadastrada hoje. Mudanças em metas, créditos ou sugestões **não** alteram esses totais, pois não modificam os minutos reais lançados.

### 4.2. Gerenciamento de ciclos

- Listar ciclos existentes, nome, referência semanal e status ativo/inativo.
- Criar novo ciclo, editar nome/referência e selecionar qual ciclo está ativo.
- Apenas um ativo de cada vez; mudar de ativo **não zera nem reinicia** qualquer outro ciclo.
- Reabrir um ciclo anterior apresenta exatamente o estado calculado a partir de seu histórico e configurações.
- O ciclo `Default` continua sendo um ciclo comum após sua criação inicial.

### 4.3. Gerenciamento de disciplinas

Permitir adicionar, editar, alterar ordem (botões “subir/descer” são suficientes) e **retirar/arquivar** uma disciplina sem excluir suas sessões históricas.

Campos:

| Campo | Obrigatório? | Regras |
|---|---|---|
| Nome | Sim | Texto não vazio, único entre disciplinas não arquivadas do mesmo ciclo |
| Ordem no ciclo | Automática, editável | Inteiro/posição na rotação |
| Questões na prova | Não | Inteiro não negativo; usado nas sugestões |
| Pontos por questão | Não | Decimal positivo; na ausência, usar 1 quando houver número de questões |
| Nível de conhecimento | Não | Escala de 1 a 5; inicial 3 (“Regular”) |
| Minutos sugeridos | Calculado | Somente leitura; pode não estar disponível até haver dados suficientes |
| **Minutos práticos** | Para participar da rotação, sim | Inteiro positivo; campo opcional no cadastro inicial, mas a disciplina sem meta não entra na rotação até ser configurada |

Assim o usuário consegue simplesmente **ir adicionando nomes de matérias** no ciclo Default e configurá-las depois, sem passar por questionário obrigatório. Também pode preencher tudo de uma vez.

O usuário escolhe se aplica a sugestão ou informa minutos manualmente. Alterar uma meta prática individual **não redistribui** minutos nas outras disciplinas.

A tela da disciplina deve mostrar separadamente a sugestão, a meta prática, participação na referência, minutos restantes quando for atual e eventual saldo de crédito.

Retirar uma disciplina da rotação não apaga sessões. Se ela for a atual, avançar para a próxima disponível. Disciplinas arquivadas não podem receber novas sessões até serem reativadas, mas seus registros antigos permanecem consultáveis. Se a lista ficar vazia, o dashboard volta ao estado vazio.

### 4.4. Formulário “Adicionar sessão de estudo”

Exibir estes três campos, nesta ordem ou equivalente:

1. **Minutos estudados:** inteiro positivo, preenchido manualmente; aceitar 20, 30, 70, 180 etc. Não impor limite artificial de duração.
2. **Disciplina:** select com disciplinas disponíveis do ciclo, **pré-selecionando a disciplina atual**, mas permitindo escolher qualquer outra disciplina não arquivada.
3. **Data:** `Date.current`/data local de hoje **pré-selecionada**, editável para qualquer data válida, inclusive uma data passada.

Ao salvar, atualizar o dashboard e o mecanismo de créditos imediatamente. A escolha de uma disciplina diferente da atual **não equivale a um botão de pular** a disciplina atual.

### 4.5. Histórico de sessões

Tela de lista com data, disciplina e minutos; ordenar normalmente pelas sessões mais recentes e permitir filtros simples por disciplina/ciclo/data se forem fáceis de implementar. Cada sessão deve poder ser **editada** (inclusive data, disciplina e minutos) ou **excluída**, com confirmação para exclusão. Recalcular o estado da rotação e os créditos após qualquer mudança.

**Importante:** a data informada é a **data em que o estudo ocorreu**, usada no histórico. Para a lógica da rotação, manter uma **ordem determinística de lançamento/ocorrência de comandos no aplicativo**, independente dessa data. Alterar a data de uma sessão, por si só, não deve mover a sessão para outro ponto da sequência de processamento de créditos. Uma sessão antiga lançada hoje registra a data antiga, mas seu efeito na rotação ocorre no momento do lançamento; esse comportamento deve ser documentado na interface/README.

## 5. Motor do ciclo e regras de avanço

**Requisito central:** a disciplina atual **permanece atual até seus minutos restantes chegarem a zero**. Não há botão manual para pular matéria na versão inicial. Registrar uma sessão em outra matéria é permitido, mas não muda a atual; gera crédito para a matéria selecionada.

### 5.1. Sessão na disciplina atual

Exemplo: Português tem meta **180 min** e ainda faltam **180 min**. O usuário lança **30 min** para Português. O dashboard passa a mostrar **150 min restantes**.

Se faltavam **40 min** e a sessão for de **60 min**, os primeiros 40 encerram a passagem atual; os **20 min excedentes** ficam como crédito para a **próxima passagem por Português**. O sistema avança para a próxima disciplina.

### 5.2. Sessão em outra disciplina

Ordem: **Português (60 min) → Constitucional (60 min) → Administrativo (90 min)**. Atual: Português. O usuário lança **180 min de Constitucional**.

- Português continua atual, com **60 min faltantes**.
- Constitucional ganha **180 min de crédito**.
- Quando o usuário lançar 60 min de Português, ela termina e a rotação vai para Constitucional.
- Constitucional consome automaticamente 60 min do crédito, encerra aquela passagem e **avança automaticamente para Administrativo**.
- Sobram **120 min de crédito** em Constitucional, para futuras passagens.

Se o crédito ultrapassar uma ou mais passagens futuras, ele deve ser conservado e consumido de forma gradual sempre que a rotação encontrar aquela disciplina. Pode haver novas passagens integralmente cobertas, com avanço automático.

### 5.3. Mudança de meta prática durante a passagem

A mudança vale **imediatamente**, e não somente na próxima rodada.

Exemplo:

- Português tem meta prática de 180 min; **100 min já foram consumidos na passagem atual**; faltam 80.
- Reduzir a meta para **120 min** → faltam **20 min**.
- Em vez disso, reduzir a meta para **60 min** → a passagem é concluída, os **40 min excedentes viram crédito** para a próxima passagem por Português, e a rotação avança.
- Aumentar a meta de 180 para 200 com 100 já consumidos → faltam 100.

Se a disciplina editada não estiver atual, a nova meta valerá em sua **próxima visita**; o crédito existente dessa disciplina continua disponível.

### 5.4. Aplicação e consumo do crédito

Quando a rotação chega a uma disciplina, antes de exibi-la como atual:

1. Obter sua meta prática vigente, em minutos.
2. Consumir automaticamente do crédito disponível até o valor necessário para essa passagem.
3. Se ainda restar meta, exibir essa disciplina como atual com os minutos faltantes.
4. Se a meta for integralmente coberta, marcar a passagem como concluída e avançar para a próxima, **preservando eventual crédito excedente**.

Não criar um loop infinito caso haja grandes créditos ou poucas disciplinas. Mesmo no caso de uma só disciplina, cada passagem completa deve consumir a meta correspondente antes de iniciar a próxima; ao esgotar o crédito, a disciplina volta a aparecer com uma nova meta pendente.

### 5.5. Volta completa do ciclo

Quando a última disciplina termina, a próxima é a primeira. Contabilizar uma nova volta concluída, mas **não limpar créditos ou sessões** e **não resetar o que está em andamento** porque virou uma semana.

### 5.6. Edições e exclusões retroativas

**Não basta subtrair ou somar minutos em um contador isolado.** A alteração de uma sessão antiga pode modificar qual disciplina estaria atual e quais créditos seriam consumidos posteriormente. É obrigatório recalcular o estado de forma coerente.

Exemplo de regressão:

1. Português exige 60 min; Constitucional exige 60 min.
2. Registrar 60 min de Português → atual passa a Constitucional.
3. Registrar 30 min de Constitucional → faltam 30 nela.
4. **Editar** a primeira sessão de Português de 60 para 20 min.
5. Resultado coerente: Português volta a ser atual, faltando **40 min**, e os 30 min lançados em Constitucional passam a contar como **crédito de Constitucional** (serão usados quando ela voltar a ser alcançada).

Ao **excluir** uma sessão, aplicar a mesma lógica de reconstrução, agora sem o lançamento excluído. Nunca inventar ou duplicar tempo estudado.

## 6. Algoritmo de sugestão de minutos

A sugestão é **orientativa**, não uma regra obrigatória, e é uma heurística deste aplicativo — **não atribuir a Alexandre Meirelles esses multiplicadores numéricos**.

Para cada disciplina, considerar:

1. Pontos da disciplina na prova = `questoes * pontos_por_questao`.
2. Participação = `pontos_da_disciplina / soma_dos_pontos_das_disciplinas_da_prova_cadastradas`.
3. Fator pelo conhecimento declarado:

| Nível | Descrição | Multiplicador |
|---|---|---:|
| 1 | Péssimo | 1,50 |
| 2 | Ruim | 1,25 |
| 3 | Regular | 1,00 |
| 4 | Bom | 0,75 |
| 5 | Ótimo | 0,50 |

**Fórmula:**

```text
minutos_sugeridos = arredondar(
  minutos_referencia_semanal * participacao_na_pontuacao * multiplicador
)
```

Usar arredondamento consistente para inteiros (por exemplo, `round` com regra explicitada e testada). Não normalizar a soma para 100%, nem limitar sugestões ao total de referência.

**Exemplo com referência de 1.440 min:**

| Disciplina | Participação | Nível | Multiplicador | Sugestão |
|---|---:|---|---:|---:|
| Português | 30% | Ruim | 1,25 | 540 min |
| Constitucional | 40% | Regular | 1,00 | 576 min |
| Administrativo | 30% | Péssimo | 1,50 | 648 min |
| **Total** | **100%** | — | — | **1.764 min (122,5%)** |

Esse total superior a 1.440 min é **válido e esperado**.

**Dados incompletos:** não impedir a criação/edição de disciplinas. Se os dados de pontuação das disciplinas da prova estiverem incompletos ou o denominador for zero, mostrar **“Sugestão indisponível: informe os dados da prova”** em vez de inventar números. É possível editar metas práticas normalmente. Considerar como denominador a soma das pontuações das disciplinas **não arquivadas cadastradas no ciclo**; identificar na interface que esse percentual corresponde às disciplinas cadastradas, caso o usuário não tenha incluído toda a prova.

**Mudanças de conhecimento, questões ou pontos por questão:** recalcular **apenas o valor sugerido**, sem alterar automaticamente os minutos práticos, o progresso ou os créditos. Oferecer ação explícita **“Aplicar sugestão”** em cada disciplina; apenas essa ação altera a meta prática e dispara as regras de recálculo correspondentes.

**Adicionar disciplina:** oferecer a sugestão quando houver dados suficientes, mas sempre permitir configurar manualmente. Não mexer nas metas práticas das demais disciplinas ao adicionar uma matéria, mesmo que as sugestões calculadas delas mudem.

## 7. Mudança da carga semanal de referência

Ao alterar a referência semanal do ciclo, **recalcular automaticamente e proporcionalmente os minutos práticos já configurados**, mantendo a participação prática anterior de cada disciplina.

```text
nova_meta_pratica = arredondar(
  meta_pratica_anterior * nova_referencia / referencia_anterior
)
```

Exemplo: referência muda de **1.440** para **1.800 min**. Português tinha **720 min práticos (50%)**, e Constitucional tinha **864 min práticos (60%)**. Após a mudança:

- Português: **900 min (50%)**.
- Constitucional: **1.080 min (60%)**.
- Total prático: **1.980 min (110% da nova referência)** — permitido.

**Não** forçar soma igual à referência e **não** alterar proporções para tentar fechar 100%. Em metas positivas muito pequenas, preservar mínimo de **1 minuto** ao arredondar. A referência semanal deve ser inteiro **maior que zero**.

As metas práticas novas entram em vigor imediatamente. Para a disciplina atual, aplicar a regra da seção 5.3 (recalcular restante e crédito excedente). As sugestões teóricas também são recalculadas com a nova referência, sem se confundir com as metas práticas.

## 8. Modelagem de dados sugerida

É permitido refinar os nomes, mas **preservar as entidades e os invariantes**:

### `StudyCycle`

- `id`, `name`, `weekly_reference_minutes` (integer > 0), `active` (boolean), `seed_key`/identificador estável do Default (nullable unique), timestamps.
- Garantir **no máximo um ativo** inclusive no banco de dados, usando transação e, se conveniente, índice parcial único do SQLite.

### `CycleSubject` (disciplina vinculada a um ciclo)

- `id`, `study_cycle_id`, `name`, `position`, `questions_count` (nullable integer), `points_per_question` (decimal), `knowledge_level` (1..5), `configured_minutes` (nullable integer positivo), `archived_at` (nullable datetime), timestamps.
- Sugestão pode ser **calculada**, não precisa de coluna persistida, contanto que esteja sempre coerente.

### `StudySession`

- `id`, `study_cycle_id`, `cycle_subject_id`, `minutes` (integer positivo), `studied_on` (date), ordem imutável do lançamento (`sequence` ou referência a evento), `deleted_at` se optar por exclusão lógica, timestamps.
- A data de estudo não determina a ordem do motor do ciclo.

### Eventos e projeção do motor (recomendado)

Como alterações de metas, trocas de ordem, inclusão/arquivamento de matérias e edições/exclusões de sessões afetam créditos e posição, **recomenda-se um histórico de operações por ciclo** (`CycleEvent`, sequência monotônica, tipo e dados da operação) e um serviço que **reconstrua o estado do ciclo em ordem de operações**.

- Reproduzir inclusões/reordenações/retiradas de matérias, mudanças de metas e lançamentos de sessões na ordem em que ocorreram.
- Uma sessão editada **mantém sua posição lógica original**, mas participa do recálculo com os campos atuais. Uma excluída deixa de contribuir para o resultado.
- Configurações modificadas hoje não devem reescrever arbitrariamente as regras que valiam em passagens já concluídas; a mudança vale no ponto em que foi feita, conforme seções 5.3 e 7.
- A posição atual, os minutos consumidos/restantes, os créditos por disciplina e as voltas concluídas podem ser projeções calculadas ou cache reconstruível; **a fonte de verdade deve ser o histórico/estado persistente necessário para reproduzir o cálculo**.
- Operações que alteram o motor devem ser **atômicas**. Evitar duplicar crédito quando a página é recarregada ou o serviço é executado novamente.

Pode-se usar outro desenho interno equivalente, desde que todos os casos da seção 9 sejam atendidos. **Não** implementar apenas um total acumulado por disciplina sem registrar em qual passagem foi consumido: isso falhará nas regras de crédito e edição retroativa.

## 9. Testes de aceitação obrigatórios

Criar testes automatizados (Minitest nativo do Rails é suficiente) cobrindo, no mínimo:

1. **Primeiro uso:** banco novo cria somente um ciclo `Default` ativo, com referência `1440`, sem disciplinas/sessões, acessível como raiz `/`.
2. **Seed idempotente:** segunda execução não duplica `Default`, não altera referência editada e não rouba o status ativo de outro ciclo.
3. **Disciplina adicionada:** cadastrar somente nome é possível; sem meta prática, não prende o motor em loop; configurar minutos depois a habilita na rotação.
4. **Desconto simples:** meta 180, lançamento 30 na atual → restante 150.
5. **Excedente:** meta 40, lançamento 60 na atual → conclusão, crédito 20 para próxima passagem da mesma disciplina, avanço à próxima.
6. **Disciplina diferente:** com A atual 60 e B meta 60, lançar 180 em B → A continua 60, crédito B=180; concluir A → B consome 60, sobram 120, avança automaticamente.
7. **Alterar meta da atual:** meta 180, consumidos 100; mudar para 120 → resta 20; mudar para 60 → crédito 40 e avanço automático.
8. **Aumentar meta da atual:** meta 180, consumidos 100; mudar para 200 → resta 100.
9. **Reaproveitar crédito em volta posterior:** saldo 20 em A com meta 40 → ao chegar novamente a A, exibir apenas 20 faltantes.
10. **Crédito de múltiplas voltas:** crédito maior que várias metas persiste corretamente, é consumido por passagem e nunca duplica ou desaparece.
11. **Editar sessão retroativa:** A meta 60; A60 → B atual; B30 → B restam 30; editar A60 para A20 → A atual restam 40; B30 vira crédito para B.
12. **Excluir sessão retroativa:** ao apagar um lançamento, posição, restante e créditos são reconstruídos corretamente.
13. **Data:** sessão nova usa a data local de hoje; permite data passada; editar apenas data não altera os cálculos de avanço.
14. **Sugestões:** 1.440 min, participações 30/40/30% com níveis 2/3/1 → 540/576/648 min, soma 1.764 sem normalizar.
15. **Alterar conhecimento:** muda sugestão, **não** a meta prática; clicar em “Aplicar sugestão” muda a prática e recalcula restante/crédito.
16. **Alterar referência:** 1.440→1.800; metas 720 e 864 → 900 e 1.080, preservando 50% e 60% e o excesso global.
17. **Editar uma disciplina:** mudança manual individual não modifica metas das outras; total prático pode divergir da referência.
18. **Trocar de ciclo:** somente um ativo; voltar ao anterior preserva seu estado e suas sessões.
19. **Arquivar disciplina:** mantém histórico; se era a atual, avança; se todas arquivadas, dashboard não falha.
20. **Última para primeira:** terminar a última matéria avança para a primeira, sem reset semanal, respeitando os créditos.
21. **Isolamento:** sessões e créditos de um ciclo jamais contaminam outro.
22. **Validações:** não aceitar minutos de sessão zero/negativos, referência zero, nível fora de 1..5, associações cruzadas entre ciclos ou datas inválidas.
23. **Idempotência:** reprocessar o motor sem novos comandos produz exatamente o mesmo resultado.
24. **Indicadores vazios:** sem sessões, Hoje, Semana, Mês e Total exibem `0 min / 0 h`.
25. **Totais por período:** com sessões distribuídas entre ontem, hoje, outra semana, outro mês e o passado, Hoje/Semana/Mês/Total somam exatamente os minutos de `studied_on` nos intervalos respectivos; a semana começa **segunda-feira** e termina domingo.
26. **Data retroativa:** sessão lançada hoje com `studied_on` em outro período afeta o período correspondente à data estudada, e não o período da criação.
27. **Revisões do histórico:** editar minutos ou `studied_on`, mudar a disciplina dentro do mesmo ciclo, e excluir sessões recalcula os quatro indicadores corretamente, sem duplicação.
28. **Créditos e ciclos isolados:** consumo/produção de créditos e mudanças de metas não somam tempo adicional aos indicadores; trocar o ciclo ativo apresenta apenas seus próprios números, incluindo sessões históricas de disciplinas arquivadas.
29. **Formatação:** 60 → `60 min / 1 h`; 90 → `90 min / 1,5 h`; 75 → `75 min / 1,25 h`; 30 → `30 min / 0,5 h`; horas aparecem na mesma linha, em `<small>` (ou estilo tipográfico equivalente), sem alterar o valor inteiro dos minutos.

Além dos testes, fazer um percurso manual de navegação do primeiro uso até o registro/edição de sessões e confirmar que a interface funciona e fica legível em tela de computador.

## 10. Diretrizes técnicas e de UX

- Usar uma versão estável e compatível de Rails/Ruby disponível no ambiente, SQLite, Bootstrap 5 e templates Rails tradicionais. Hotwire/Stimulus é opcional; **não criar SPA React nem API separada**.
- CSS e JavaScript necessários, inclusive Bootstrap, devem estar disponíveis **localmente**, sem depender de CDN ou conexão com internet durante o uso.
- Usar serviços Ruby de domínio (por exemplo `CycleProgressCalculator`, `StudyTimeRecommender`, `RecalculateCycle`) em vez de colocar regras complexas em controllers ou views.
- Interface em **português do Brasil**. Configurar timezone Rails `America/Sao_Paulo`; usar data local para o valor inicial do formulário.
- O layout deve ser limpo, responsivo, com navegação direta para **Dashboard**, **Disciplinas**, **Sessões** e **Ciclos**.
- Para minutos, mostrar, por exemplo, `150 min`; horas equivalentes são secundárias e **obrigatórias nos quatro indicadores do mini-dashboard**, conforme seção 4.1.1, sem substituir os minutos.
- Permitir ações normais por formulários HTTP Rails com validação e feedback claro (sucesso/erro). Confirmar exclusões.
- Executar o servidor **somente em `127.0.0.1`**, nunca em `0.0.0.0` por padrão; documentar explicitamente que o aplicativo não foi projetado para exposição pública, já que não tem autenticação.
- Não implementar componentes fora do escopo (login, backup pela interface, importação, exportação, sincronização, estatísticas avançadas, cronômetro, IA generativa, sistema multiusuário ou notificações).

## 11. Entregáveis esperados do Codex

1. Código-fonte completo do projeto Rails, com dependências e assets do Bootstrap.
2. Migrations e seed idempotente para o ciclo `Default` com 1.440 minutos.
3. Telas funcionais (dashboard, ciclos, disciplinas e sessões), **quatro indicadores Hoje/Semana/Mês/Total no mini-dashboard** e validações.
4. Motor de ciclo e de créditos com recálculo determinístico e suporte a edição/exclusão retroativa.
5. Algoritmo de sugestão, aplicação manual da sugestão e atualização proporcional das metas após mudança de referência.
6. Testes automatizados cobrindo a seção 9, todos passando.
7. `README.md` explicando pré-requisitos, como instalar, inicializar o SQLite, rodar os testes e iniciar o servidor em loopback. Priorizar comandos Rails convencionais, por exemplo:

   ```bash
   bundle install
   bin/rails db:prepare
   bin/rails db:seed
   bin/rails test
   bin/rails server -b 127.0.0.1
   ```

8. Resumo final do que foi implementado, dos comandos executados e de eventuais limitações reais. **Não afirmar que testes passaram sem executá-los.**

## 12. Critério final de sucesso

Ao executar a aplicação, o usuário abre `http://127.0.0.1:4000/`, encontra o **ciclo Default já ativo com referência de 1.440 min**, cadastra disciplinas, vê/ajusta as sugestões, registra minutos estudados e acompanha no dashboard **a disciplina atual, o tempo restante, a próxima disciplina e os totais de estudo de Hoje, Semana, Mês e Total (em minutos e horas)**. O sistema respeita uma rotação **contínua**, contabiliza créditos corretamente, aceita somas práticas diferentes da referência e se mantém consistente mesmo após mudanças de metas e edição/exclusão de sessões antigas.
