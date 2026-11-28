# Configuração e validação de notificações push — MOZ SALÕES

## Arquitectura

1. `user_notifications` e `admin_notifications` guardam o histórico persistente das mensagens.
2. RLS restringe cada utilizador ao seu próprio destinatário; o administrador tem uma tabela/centro reservado.
3. O cliente pode actualizar apenas `read_at`; não pode editar título, mensagem, destinatário ou metadados.
4. `push_subscriptions` guarda uma subscrição por endpoint/dispositivo. O utilizador só pode consultar a sua própria subscrição. Escrita e transferência entre contas são feitas por Edge Function autenticada.
5. `manage-push-subscription` valida o JWT do utilizador, restringe endpoints a serviços push HTTPS conhecidos e transfere a propriedade do endpoint para a conta autenticada. Isto evita que um dispositivo partilhado continue associado à conta anterior.
6. `send-notification-push` recebe webhooks de inserção de notificações, confirma um segredo partilhado, consulta novamente a notificação e envia conteúdo genérico. Dados pessoais e detalhes de marcações permanecem no painel autenticado.
7. O Service Worker recebe push e abre o MOZ SALÕES; o histórico da conta continua a ser a fonte persistente.

## Segredos necessários (nunca guardar no GitHub nem no JavaScript público)

No Supabase Dashboard do projecto de produção `wxwbxvvjsgmsrukdfmzq`, abrir Edge Functions → Secrets e configurar:

- `MOZ_PUSH_WEBHOOK_SECRET`: segredo aleatório forte, pelo menos 32 bytes.
- `MOZ_VAPID_PUBLIC_KEY`: chave pública VAPID em base64url.
- `MOZ_VAPID_PRIVATE_KEY`: chave privada VAPID em base64url.
- `MOZ_VAPID_SUBJECT`: identificador de contacto VAPID, por exemplo `mailto:suporte@moz-saloes.co.mz` (usar apenas quando esse endereço existir).

A função usa também os segredos de sistema `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEYS` e `SUPABASE_SECRET_KEYS` disponibilizados pelo Supabase. Nunca criar ou copiar uma service-role/secret key para o browser.

## Configuração pública

Depois de gerar o par VAPID e guardar os dois valores no cofre do Supabase, colocar **apenas a chave pública** em `push-config.js`:

```js
window.MOZ_PUSH_VAPID_PUBLIC_KEY = "CHAVE_PUBLICA_VAPID";
```

A chave privada não deve aparecer neste ficheiro.

## Publicação das funções (apenas depois de testar em ambiente isolado)

- `manage-push-subscription`: publicar com verificação JWT activada (`verify_jwt=true`).
- `send-notification-push`: publicar com `verify_jwt=false`, pois o endpoint é chamado pelo webhook e valida obrigatoriamente `x-moz-webhook-secret` no código.

## Webhooks de base de dados

Depois das funções e segredos estarem configurados, criar dois Database Webhooks no Supabase:

- Tabela `public.user_notifications`, evento INSERT.
- Tabela `public.admin_notifications`, evento INSERT.

Ambos devem fazer POST para:

`https://wxwbxvvjsgmsrukdfmzq.supabase.co/functions/v1/send-notification-push`

Adicionar header personalizado:

`x-moz-webhook-secret: <valor exacto de MOZ_PUSH_WEBHOOK_SECRET>`

Usar o payload padrão do Database Webhook, que inclui `table` e `record`. Não colocar segredos no corpo do payload.

## Critérios de teste obrigatórios

- Conta cliente: recebe confirmação de pedido enviado, depois aceite/recusa; não consegue ler avisos de outro cliente.
- Conta proprietária: recebe novo pedido; não consegue ler avisos de outro proprietário.
- Conta administrativa: recebe registos, novos salões/serviços e marcações; conta comum não consegue consultar `admin_notifications`.
- Testar leitura/reabertura de mensagens: título e mensagem permanecem no histórico, sem contadores, números, badges ou bolinhas.
- Testar autorização push concedida, negada e ainda não decidida.
- Testar subscrição em Android/Chrome, iOS/Safari (instalado no ecrã principal, quando suportado) e desktop.
- Testar aplicação aberta, em segundo plano e fechada.
- Testar logout e troca de conta no mesmo dispositivo: o endpoint push tem de deixar de pertencer à conta anterior e passar para a conta actualmente autenticada.
- Testar endpoint expirado (404/410), revogação de permissão, duplicados e falhas temporárias de rede.
- Confirmar que o push é genérico e não revela telefone, email, nome do cliente, detalhes da marcação ou dados administrativos no ecrã bloqueado.

## Estado verificado em 28/11/2026

- Produção já contém `push_subscriptions`, `user_notifications` e `admin_notifications`, com RLS activo nas três tabelas.
- Produção já tem dois Database Webhooks AFTER INSERT, um para cada tabela de notificações, apontados para `send-notification-push`.
- Produção tem as Edge Functions `send-notification-push` e `manage-push-subscription` ACTIVE (versão 1). O código remoto ainda não foi actualizado para coincidir integralmente com a branch.
- O código de gestão de subscrições valida o utilizador com `auth.getUser(token)`, embora a opção `verify_jwt` apresentada no Dashboard esteja desligada; a branch mantém `verify_jwt=true` em `supabase/config.toml` para a próxima publicação.
- A chave pública VAPID está presente em `push-config.js`; a chave privada e o segredo do webhook permanecem apenas no cofre do Supabase. Não copiar valores secretos para documentação, GitHub ou mensagens.
- A branch `security-notifications-hardening` contém as correcções de destino do clique, prevenção de notificações duplicadas e endurecimento das migrações. Estas alterações ainda não foram publicadas.
- Os logs consultados nas últimas 24 horas mostram apenas chamadas GET/401/405 às funções; não foi observado nenhum POST bem-sucedido. Isso não prova entrega push.
- Ainda falta um teste ponta a ponta controlado com contas e dispositivos separados, incluindo aplicação fechada, clique na notificação, logout/troca de conta e revogação de permissão.

**Conclusão:** a infraestrutura existe em produção, mas o envio push real ainda não está confirmado. Não declarar a funcionalidade concluída até executar a matriz de testes. A produção permanece sem as alterações desta revisão até aprovação e publicação explícitas.
