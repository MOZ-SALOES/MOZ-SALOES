# MOZ-SALOES — MOZ SALÕES 🇲🇿

Directório digital de salões de beleza em Moçambique. A interface pública permite pesquisar salões por nome, serviço, província e categoria, consultar preços e contactar os estabelecimentos.

## Projecto Supabase de produção

- Project ref: `wxwbxvvjsgmsrukdfmzq`
- Região: `eu-west-2` (London)
- Estado verificado: `ACTIVE_HEALTHY`
- PostgreSQL: 17
- Configuração CLI: `supabase/config.toml`

**Não confundir com o projecto antigo BEAUTY-MAP-MOZ**, cujo ref era `wmcypueuaszizekaljok`. O frontend `index.html` está agora configurado para o projecto correcto MOZ-SALOES.

## Base de dados

As 21 migrações aplicadas no projecto remoto estão registadas no repositório:

| Versão | Migração |
|---|---|
| 20261116142902 | create_moz_saloes_core |
| 20261116142926 | tighten_moz_saloes_access |
| 20261116143053 | lock_internal_trigger_functions |
| 20261116143243 | protect_salon_approval_fields |
| 20261116145347 | configure_silda_admin_profile_on_signup |
| 20261116145917 | enforce_pending_status_on_salon_creation |
| 20261116150303 | tighten_reviews_inquiries_reports_security |
| 20261116150701 | secure_salon_image_storage_ownership |
| 20261121170000 | seed_real_maputo_salons_pending |
| 20261121171000 | update_publication_plan_prices |
| 20261121173000 | add_maputo_salon_image |
| 20261121201500 | enable_moz_saloes_realtime |
| 20261121202500 | broadcast_public_directory_invalidations |
| 20261122141630 | add_independent_beauty_providers |
| 20261123164401 | add_optional_owner_profile_settings |
| 20261124040110 | admin_notifications_and_registration_triggers |
| 20261124093624 | private_owner_workspace_directory_access |
| 20261124095621 | promote_salon_accounts_to_owner |
| 20261127182024 | add_query_performance_indexes |
| 20261127182047 | remove_duplicate_inquiry_index |
| 20261127182951 | persistent_user_notifications |

A migração de notificações cria a tabela privada por utilizador `user_notifications`, com RLS, índices para histórico/avisos por ler e um trigger que notifica o proprietário quando recebe uma marcação e o cliente quando o pedido é aceite ou recusado. A tabela está incluída no Supabase Realtime.

Tabelas principais: `profiles`, `categories`, `salons`, `services`, `salon_images`, `salon_hours`, `appointments`, `user_notifications`, `admin_notifications`, `subscription_plans`, `subscriptions`, `payments`, `payment_events`, `wallet_transactions`, `promotions`, `promotion_salons`, `reviews`, `favorites`, `inquiries`, `reports`, `admin_settings` e `audit_logs`.

As 22 tabelas do schema público foram verificadas com RLS activo. O bucket `salon-images` existe e aceita imagens JPEG, PNG e WebP até 5 MB.

## Frontend

O ficheiro `index.html` usa a chave publishable pública do projecto MOZ-SALOES e as tabelas/colunas reais da base de dados:
- `categories.active` e `categories.sort_order`
- `salons.status`, `province`, `district`, `city`, `latitude` e `longitude`
- `services.active`, `salon_id`, `category_id` e `price_mzn`
- autenticação administrativa confirmada por `profiles.role = 'admin'`

A chave publishable pode estar no frontend; nunca colocar no código uma chave `service_role`, chave secreta ou password da base de dados.

## Administração e autenticação

O email administrativo configurado em `admin_settings` é o endereço do proprietário da plataforma; o nome configurado é Silda. O trigger `handle_new_user` atribui o papel `admin` ao email administrativo definido na função. O primeiro acesso administrativo exige que a conta seja criada/confirmada pelo link de autenticação enviado pelo Supabase.

No momento da auditoria não existia ainda utilizador autenticado nem perfil administrativo para esse email. Isso é esperado antes do primeiro registo. O endereço final do site deve ser adicionado à lista de Redirect URLs do Supabase Auth antes de testar o link mágico em produção.

## Workflows GitHub Actions

- `.github/workflows/repository-safety.yml`: verifica a referência do projecto e mantém ficheiros de recuperação fora das migrações executáveis.
- `.github/workflows/supabase-migrations.yml`: compara o histórico e aplica apenas migrações pendentes.
- `.github/workflows/supabase-schema-backup.yml`: exporta manualmente um backup do schema, sem dados.

Secrets necessários em **Settings → Secrets and variables → Actions**:
- `SUPABASE_ACCESS_TOKEN`
- `SUPABASE_DB_URL` (Session pooler IPv4)

Nunca partilhar estes valores no chat nem os guardar no repositório.

## Estado funcional e próximos passos

A estrutura da base de dados e as migrações estão sincronizadas. Existem salões publicados e pendentes, e já existe um perfil administrativo. O fluxo de notificações de marcações está preparado para proprietários e clientes autenticados.

O site está publicado no GitHub Pages em https://moz-saloes.github.io/MOZ-SALOES/. As funcionalidades que dependem de autenticação e Internet continuam a exigir ligação activa; as notificações do painel são persistentes e actualizadas em tempo real enquanto a conta está ligada.

Pagamentos e levantamentos estão actualmente desactivados na configuração da plataforma. Não activar até a integração e os testes de M-Pesa/e-Mola estarem concluídos.

## Notas de recuperação

Os ficheiros em `supabase/recovery/` são documentação de recuperação e não migrações executáveis. Não os mover para `supabase/migrations/`, não executar e não usar `migration repair` com base nesses ficheiros.
