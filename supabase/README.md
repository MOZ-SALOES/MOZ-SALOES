# Supabase — MOZ-SALOES

Project ref: `wxwbxvvjsgmsrukdfmzq`
Region: London (`eu-west-2`)
Database: PostgreSQL 17

## Estado verificado em 24-11-2026

- O projecto remoto está activo e saudável na última verificação disponível.
- O histórico remoto contém **18 versões de migração**.
- A pasta `supabase/migrations/` contém as primeiras 13 migrações, incluindo as oito versões iniciais.
- As cinco versões mais recentes (2026-11-22 a 2026-11-24) constam no histórico remoto, mas os respectivos SQL originais não foram recuperados para a pasta executável.
- Os ficheiros com essas cinco versões em `supabase/recovery/reconstructed/` são notas documentais baseadas na inspecção do catálogo actual. **Não são cópias dos SQL originais e não devem ser executados.**
- O frontend administrativo em `admin.js` consulta `admin_notifications`, apresenta notificações e subscreve eventos Realtime; a criação das notificações é feita pelos triggers no Supabase.
- A sincronização de esquema e migrações ainda não está completa.

## Migrações e recuperação

O histórico remoto regista as versões seguintes que ainda precisam de fonte SQL recuperada ou reconstruída e validada:

- `20261122141630_add_independent_beauty_providers`
- `20261123164401_add_optional_owner_profile_settings`
- `20261124040110_admin_notifications_and_registration_triggers`
- `20261124093624_private_owner_workspace_directory_access`
- `20261124095621_promote_salon_accounts_to_owner`

A base de dados remota guarda a versão e o nome das migrações, mas não mantém necessariamente o texto SQL original. Por isso, não afirmar que os documentos de recuperação são os originais. A próxima recuperação deve ser feita a partir de um dump de esquema verificado e das definições actuais de funções, triggers, políticas, índices, constraints e grants.

**Não** mover nem executar os documentos de `supabase/recovery/reconstructed/`. Não executar novamente migrações já aplicadas. Não usar `migration repair` para mascarar diferenças. Antes de qualquer alteração de esquema em produção, criar e validar um backup e testar num ambiente separado.

## GitHub automation

- `.github/workflows/repository-safety.yml`: validações estáticas do repositório.
- `.github/workflows/supabase-schema-backup.yml`: exportação manual e apenas de leitura do esquema, usando Supabase CLI.
- `.github/workflows/supabase-migrations.yml`: aplicação de migrações. A validação deve bloquear deploy enquanto qualquer fonte histórica estiver ausente, para evitar divergência.

### Backup manual

O workflow de backup requer o secret `SUPABASE_DB_URL` em GitHub → Settings → Secrets and variables → Actions. Copiar a connection string do painel Supabase → Connect directamente para o secret; nunca a partilhar no chat nem a guardar no repositório.

### Credenciais de migração

O workflow de migrações usa secrets guardados directamente no GitHub. Nunca colocar passwords, tokens, `service_role` ou `sb_secret` no código. No frontend, usar apenas a chave publishable/anon e políticas RLS correctas.

## Configuração local

`supabase/config.toml` aponta para `wxwbxvvjsgmsrukdfmzq`.

Antes de qualquer deploy futuro, verificar a versão da CLI, comparar migrações locais/remotas, rever o SQL e testar num ambiente separado.

