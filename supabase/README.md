# Supabase — MOZ-SALOES

Project ref: `wxwbxvvjsgmsrukdfmzq`
Region: London (`eu-west-2`)
Database: PostgreSQL 17

## Verified live status

- Project status: active and healthy.
- Eight migration versions are recorded by the remote database (2026-11-16).
- All eight SQL migration files have been restored to `supabase/migrations/` from the exact SQL statements retained in `supabase_migrations.schema_migrations`.
- An incompatible, unapplied draft migration dated 2026-11-17 was moved to `supabase/recovery/quarantine/` with a `.disabled` extension; it is not executable.
- The security advisor returned no lints at the last check.
- Performance advisor warnings include unused indexes and multiple permissive RLS policies. Do not remove indexes or rewrite policies solely to silence these notices; review them after real workload data exists.

## Migration history recovery

The files in `supabase/migrations/` are the eight migration sources recovered from the active project's remote migration records. The files in `supabase/recovery/reconstructed/` remain documentary reconstructions based on the current database catalog; they are not executable migrations.

Do not:
- move recovery files into `supabase/migrations/`;
- run them with `supabase db push`;
- use `migration repair` to mark old versions as reverted/applied;
- push schema changes to production before reviewing a verified snapshot and testing on a separate project.

## GitHub automation prepared

### Repository safety checks

`.github/workflows/repository-safety.yml` runs on pushes and pull requests. It checks the configured project reference and ensures recovery documents remain outside the executable migrations directory.

### Read-only schema backup

`.github/workflows/supabase-schema-backup.yml` is manual-only. It exports the current schema using the official Supabase CLI command `supabase db dump --db-url ... -f schema.sql` and uploads a seven-day artifact. It does not modify the database or its migration history.

To activate the backup workflow, add this one repository secret:

1. Open GitHub repository **Settings**.
2. Select **Secrets and variables → Actions**.
3. Select **New repository secret**.
4. Name: `SUPABASE_DB_URL`.
5. Value: the database connection string copied from Supabase Dashboard → **Connect**. Do not share it in chat or commit it.

Then open **Actions → Supabase schema backup → Run workflow**. If the secret is missing or invalid, the workflow will stop rather than change the database.

## Local CLI configuration

The file `config.toml` already points to project `wxwbxvvjsgmsrukdfmzq`.

After installing the Supabase CLI on a trusted computer:

```sh
supabase --version
supabase login
supabase link --project-ref wxwbxvvjsgmsrukdfmzq
supabase migration list --remote
```

The remote migration baseline is now restored locally. Before deploying any new migration, review its SQL and verify it against a backup and a test environment. The quarantined draft is not part of the baseline.

## Secrets and browser safety

Never commit database passwords, Supabase access tokens, `service_role` keys, or `sb_secret` keys. Only a publishable/anon key may be used in browser code, together with correctly configured RLS.
