# Supabase database

Project reference: `wmcypueuaszizekaljok`.

## Important migration history note

The connected database reports these already-applied migrations:

- `20261104173058_beauty_map_initial_foundation`
- `20261104173116_beauty_map_security_hardening`
- `20261104173620_beauty_map_payments_and_admin_wallet`
- `20261104173626_beauty_map_payment_backend_privileges`
- `20261104173745_beauty_map_manual_mpesa_emola_withdrawal_preferences`

Their original SQL source files were not present in this repository or recoverable from the migration-history listing. Do not invent replacement SQL or reapply those versions. Restore the original source files from a trusted backup before using this repository to provision a brand-new project.

The migration in this repository is an incremental security correction for the existing project. It protects salon identity, ownership, publication status, featured status, rating aggregates, slug, and creation timestamp from owner-side updates. The existing trigger continues to allow the authorized administrator to manage these fields.

## Deployment

GitHub Actions deploys only new migrations committed under `supabase/migrations/`. Configure repository Actions secrets before enabling deployment:

- `SUPABASE_ACCESS_TOKEN`: a Supabase personal access token.
- `SUPABASE_DB_PASSWORD`: the database password for this project.

The project reference is stored in `supabase/config.toml`. Never put database passwords, access tokens, service-role keys, or secret API keys in frontend files.

Until the five historical migration source files are restored, this repository is not a complete reproducible database baseline for creating a fresh Supabase project.
