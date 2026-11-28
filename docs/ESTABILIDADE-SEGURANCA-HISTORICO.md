# MOZ SALÕES — Registo técnico e histórico de alterações

Este documento é o diário de referência do projecto. Deve ser actualizado em cada intervenção, antes de encerrar a tarefa. O objectivo é permitir localizar regressões comparando a última versão estável, os commits, as migrações e as alterações de interface.

## Regras permanentes de desenvolvimento

1. A versão publicada e funcional é a referência estável. Nunca publicar directamente uma alteração não verificada.
2. Trabalhar em branch isolada; comparar com `main`; abrir revisão antes de integrar.
3. Fazer alterações pequenas e identificáveis. Evitar misturar interface, regras de segurança e migrações numa única mudança extensa.
4. Antes de editar: registar commit base, ficheiros, versão do Service Worker, estado dos workflows, migrações e verificações da base de dados.
5. Depois de editar: rever diff; testar sintaxe JS, IDs, eventos, acessibilidade, consultas, permissões e comportamento em Android/iOS/desktop; executar workflows; verificar publicação e logs.
6. Não alterar dados de produção para corrigir problemas de interface. Nunca apagar dados de utilizadores como atalho.
7. Se surgir anomalia, comparar o último ponto estável com cada commit/migração desde então e isolar a primeira alteração que introduziu o problema.
8. Não afirmar que uma funcionalidade está operacional sem teste observável. Distinguir sempre implementado, testado, publicado e confirmado em produção.
9. Não expor chaves secretas, tokens, endpoints privados ou dados pessoais em código público, logs ou relatórios.

## Objectivo de privacidade e segurança (definição do proprietário)

A segurança pedida é principalmente a protecção dos dados pessoais de clientes, proprietários e administrador, com separação de permissões:
- Cliente: só os seus dados, marcações e mensagens/avisos destinados à sua conta.
- Proprietário: só os dados do seu perfil/salão, serviços, marcações e mensagens/avisos a que tem direito.
- Administrador: acesso administrativo apenas através de autenticação e autorização explícitas; dados e ferramentas administrativas nunca devem aparecer nas contas comuns.
- Aplicar menor privilégio, RLS em todas as tabelas privadas, validação no servidor, controlo de acesso a Storage, prevenção de IDOR, protecção de sessões, limitação de abuso e registo de eventos administrativos sem guardar segredos.
- Não confiar apenas em esconder botões na interface: a base de dados e as funções de servidor têm de impor as permissões.

## Requisitos de notificações (definição do proprietário)

- As notificações devem estar disponíveis tanto no site como na aplicação instalada.
- Mostrar as mensagens/notificações, não um contador, número, badge ou bolinha de quantidade.
- Cada notificação deve permanecer guardada e poder ser aberta/lida novamente quantas vezes o utilizador quiser.
- Separação estrita por destinatário e papel: cliente, proprietário e administrador.
- Exemplos: novas marcações, aceitação/recusa/cancelamento, actualizações relevantes, novos registos e tarefas administrativas.
- Notificação do sistema/push é complementar ao centro de mensagens persistente; não substitui o histórico dentro do site/app.
- Não pedir autorização repetidamente. O navegador/SO exige consentimento explícito; nunca fingir que a permissão foi concedida automaticamente.
- O push só pode ser declarado concluído depois de testar subscrição, envio, recepção, clique, revogação e entrega com aplicação fechada nos dispositivos suportados.

## Ambiente conhecido

- Repositório: `MOZ-SALOES/MOZ-SALOES`
- Site: https://moz-saloes.github.io/MOZ-SALOES/
- Supabase de produção: projecto `wxwbxvvjsgmsrukdfmzq`, região eu-west-2.
- Projecto Supabase antigo a evitar: `wmcypueuaszizekaljok`.
- Branch de trabalho actual: `security-notifications-hardening`.
- A branch é isolada; não equivale a publicação em produção.
- Não colocar credenciais no frontend. A chave publicável Supabase pode estar no cliente; service_role e VAPID private key nunca.

## Histórico conhecido (cronologia consolidada)

### 2026-11-27 — experiência e funcionalidades
- Ajustes de painel do proprietário (nome do salão/perfil e descrição).
- Centro de Ajuda/assistente virtual e preparação de preferências de idioma.
- Preparação da experiência PWA e actualização de cache/Service Worker.
- Push quando a aplicação está totalmente fechada ainda não estava garantido.

### 2026-11-28 — recuperação de estabilidade
- O utilizador pediu para recuperar o funcionamento sem apagar dados; depois esclareceu que queria corrigir as ampliações, não desfazê-las.
- Auditoria confirmou Supabase ACTIVE_HEALTHY e leituras públicas funcionais; foram vistos 14 categorias, 13 salões e 7 serviços em consultas de verificação daquela sessão.
- Identificado e corrigido ciclo de actualização potencialmente infinito no observador da área de comparação.
- Corrigido envio/submissão de login associado à perda de foco/blur.
- Corrigido carregamento das categorias: consulta passou a incluir `slug`, usado na apresentação.
- Corrigido ID HTML duplicado `serviceMode` no filtro e formulário de prestador; o campo do formulário passou a `providerServiceMode`.
- Adicionada deduplicação visual de serviços idênticos por salão, nome normalizado e preço; sem apagar linhas da base de dados.
- Cache do Service Worker foi avançada até `moz-saloes-shell-v7` na versão de produção reportada na auditoria.
- Verificações reportadas: 7/7 scripts inline válidos, nenhum ID duplicado, sem IDs de listeners em falta e nenhum HTTP 4xx nos logs consultados das últimas 24 horas naquela sessão.
- O utilizador confirmou posteriormente que o site voltou a funcionar normalmente.

### 2026-11-28 — branch de segurança/notificações
- Criada branch `security-notifications-hardening`; não integrar nem publicar sem revisão e aprovação de testes.
- Adicionado centro de notificações administrativas em `index.html`, com consulta filtrada por `recipient_id`, actualização em tempo real e fallback periódico, marcação individual e colectiva como lida.
- A sincronização administrativa é iniciada após a sessão administrativa confirmada e parada em SIGNED_OUT.
- Actualizado `sw.js` para cache `moz-saloes-shell-v8` e adicionado listener `push`, com validação do URL de destino para a mesma origem/escopo.
- Criada migração `supabase/migrations/20261128110000_secure_push_subscriptions.sql`: tabela `push_subscriptions`, referência a `auth.users`, unicidade por utilizador/endpoint, limites de comprimento, RLS e políticas de gestão apenas pelo próprio utilizador autenticado.
- A migração ainda não foi aplicada à produção; nenhum push de ponta a ponta está activo/confirmado.
- Revisão adicional removeu o contador visível do centro administrativo, alinhando a interface à preferência do proprietário: mensagens sem número/badge.

## Pendências técnicas conhecidas

1. Implementar e testar o centro de mensagens persistentes para clientes e proprietários, reutilizando o esquema real existente e respeitando os destinatários.
2. Confirmar que nenhuma interface mostra contador, badge numérico ou bolinha de quantidade de notificações.
3. Implementar o fluxo de subscrição push por utilizador/dispositivo, incluindo guardar/actualizar/remover subscrições; nunca confiar em dados de destinatário enviados pelo cliente.
4. Criar envio push seguro no servidor (Edge Function ou equivalente) com VAPID secrets no cofre de segredos; validar autenticação, autorização, destinatário e payload.
5. Ligar os eventos reais (marcação criada, aceite, recusada, cancelada, registos/denúncias) às notificações correctas; evitar duplicados e fuga de dados entre papéis.
6. Testar entrega push com app aberta, em segundo plano e fechada, em navegadores/dispositivos suportados; documentar limitações de iOS/Android.
7. Rever políticas RLS, Storage, funções SECURITY DEFINER, exposição de dados pessoais, autenticação e protecção de sessão para todas as tabelas sensíveis.
8. Confirmar o alerta anteriormente observado de protecção de palavras-passe comprometidas desactivada; depende das opções/plano disponíveis no Supabase Auth.
9. Resolver a divergência histórica: cinco versões de migração existiam na base de produção mas não estavam no directório GitHub consultado: `20261122141630`, `20261123164401`, `20261124040110`, `20261124093624`, `20261124095621`. Não recriar nem aplicar migrações por suposição; recuperar o SQL exacto e reconciliar o histórico primeiro.
10. Rever workflows GitHub (Pages, CodeQL, SEO) e só integrar quando todos os checks relevantes terminarem com sucesso.

## Modelo obrigatório para cada novo registo

Para cada alteração, acrescentar:
- Data/hora e objectivo.
- Branch e commit base.
- Ficheiros alterados e resumo exacto.
- Migrações SQL e impacto (ou "nenhuma").
- Tabelas, funções, políticas RLS e permissões afectadas.
- Testes executados e resultados.
- Estado de workflows e deploy.
- Confirmação em produção e dispositivo/browser testado.
- Plano de reversão e ponto estável anterior.
- Anomalias observadas e hipótese/commit que as introduziu.

**Estado actual:** trabalho de segurança/notificações em desenvolvimento isolado. Não está aprovado para merge nem publicação. A produção deve permanecer na última versão estável até concluir a revisão e os testes.


### Continuação — segurança de notificações (branch isolada)
- Removido o contador visível do centro de notificações do proprietário; as mensagens ficam apresentadas como histórico.
- Mensagens de cliente/proprietário agora mantêm a acção de abrir novamente mesmo depois de lidas; o centro administrativo também permite reabrir mensagens já lidas.
- Criada migração `20261128120000_notification_privacy_and_customer_ack.sql`: reduz permissões de UPDATE para apenas `read_at`, remove permissões/políticas de apagar notificações e passa a criar confirmação persistente para o cliente quando submete uma marcação.
- Criada migração `20261128130000_lock_push_subscription_writes.sql`: endpoint push único por dispositivo; escrita/transferência de subscrições reservada ao servidor; utilizador autenticado apenas consulta a sua própria subscrição.
- Criada Edge Function `manage-push-subscription`: valida JWT, valida HTTPS e hosts de push permitidos e reassocia endpoint à conta autenticada, reduzindo risco de notificações da conta anterior em dispositivo partilhado.
- Criada Edge Function `send-notification-push`: valida segredo webhook, consulta a notificação pelo ID no servidor, envia conteúdo push genérico e desactiva subscrições expiradas (HTTP 404/410).
- Adicionado `push-config.js` como configuração exclusivamente pública para futura chave pública VAPID; está vazio de propósito até a chave pública ser gerada e a privada guardada no cofre de segredos.
- Ligação do painel comum (clientes/proprietários) e painel administrativo ao fluxo de registo de subscrição; sincronização automática apenas se o utilizador já concedeu permissão e a chave pública estiver configurada; remoção da subscrição antes do logout.
- Service Worker avançado para `moz-saloes-shell-v9` e inclui o ficheiro público de configuração na cache.
- Criado `docs/PUSH-SETUP-E-TESTES.md` com segredos necessários, webhooks e matriz de testes.
- Ainda pendente: gerar/guardar VAPID e segredo webhook no Supabase Dashboard; inserir chave pública no ficheiro de configuração; aplicar migrações apenas num ambiente isolado de teste; publicar Edge Functions e webhooks; executar testes reais com contas e dispositivos separados.
- Limitação operacional: as ferramentas disponíveis nesta sessão permitem preparar o código e migrações no GitHub, mas não disponibilizam gestão de Edge Function Secrets. Não colocar segredos em commits ou mensagens. Por isso, não activar nem declarar push de ponta a ponta antes dessa configuração.
