# Supabase database

Project reference: `wmcypueuaszizekaljok`.

## Migration history and recovery status

The connected database reports these migrations as applied:

- `20261104173058_beauty_map_initial_foundation`
- `20261104173116_beauty_map_security_hardening`
- `20261104173620_beauty_map_payments_and_admin_wallet`
- `20261104173626_beauty_map_payment_backend_privileges`
- `20261104173745_beauty_map_manual_mpesa_emola_withdrawal_preferences`
- `20261117131448_protect_salon_system_fields`

The first five original SQL files were not found in the repository's reachable commit history, its only branch, or the available project migration-history metadata. Migration metadata records names and versions, not the SQL source. They must not be recreated by guessing.

### Recover a faithful current-schema snapshot

Use the Supabase CLI from a trusted computer with Docker installed and a database connection string copied from the Supabase Dashboard (**Connect**). Do not paste the password into chat or commit it.

```bash
supabase db dump --db-url "$SUPABASE_DB_URL" -f supabase/current_schema_snapshot.sql
```

This is a snapshot of the current database schema, not a recovery of the five historical migration files. The CLI dump excludes Supabase-managed schemas such as Auth and Storage. Keep a separate secure backup of data, roles, storage policies/buckets, and Edge Functions as applicable.

Before using a snapshot as a new-project baseline, inspect it, compare it with the live project, test restoring it into a separate empty Supabase project, and verify tables, functions, triggers, RLS policies, grants, and application behaviour. Do not run it against the existing production database.

The CLI's `supabase db pull` command can generate a migration from remote schema changes, but it may also reconcile migration history. Do not run migration repair, mark historical migrations reverted, or push until the history has been deliberately reviewed and backed up.

## Incremental migration in this repository

`20261117131448_protect_salon_system_fields.sql` records the security correction already applied to the connected project. It protects salon identity, ownership, publication status, featured status, rating aggregates, slug, and creation timestamp from owner-side updates.

## Automated deployment

The workflow at `.github/workflows/supabase-migrations.yml` is intentionally fail-closed. It will not run `supabase db push` until both credentials are configured and all five historical migration source files are present. This prevents migration-history drift and accidental changes to production.

Add these repository Actions secrets in GitHub:

- `SUPABASE_ACCESS_TOKEN`: a Supabase personal access token.
- `SUPABASE_DB_PASSWORD`: the database password for this project.

GitHub repository path: **Settings → Secrets and variables → Actions → New repository secret**.

The GitHub connector available to this assistant does not expose a repository-secret creation operation. Create the secrets directly in GitHub; do not send their values in chat, commit them, or put them in frontend files.

After the original migration files are restored and reviewed, run the workflow manually once and inspect its migration-list output before relying on automatic deployment. Never put `service_role`, `sb_secret`, database passwords, or access tokens in `index.html`.
