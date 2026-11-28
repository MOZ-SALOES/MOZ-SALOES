-- Secure per-device Web Push subscriptions.
-- Applied to production as migration 20261128092929_create_secure_push_subscriptions.
create table if not exists public.push_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  endpoint text not null,
  p256dh text not null,
  auth text not null,
  user_agent text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  disabled_at timestamptz,
  constraint push_subscriptions_endpoint_length check (char_length(endpoint) between 20 and 2048),
  constraint push_subscriptions_p256dh_length check (char_length(p256dh) between 20 and 256),
  constraint push_subscriptions_auth_length check (char_length(auth) between 8 and 128),
  constraint push_subscriptions_endpoint_unique unique (endpoint)
);
create index if not exists push_subscriptions_active_user_idx
  on public.push_subscriptions (user_id, last_seen_at desc)
  where disabled_at is null;
alter table public.push_subscriptions enable row level security;
revoke all on table public.push_subscriptions from anon, public;
revoke insert, update, delete on table public.push_subscriptions from authenticated;
grant select on table public.push_subscriptions to authenticated;
drop policy if exists push_subscriptions_select_own on public.push_subscriptions;
create policy push_subscriptions_select_own
  on public.push_subscriptions for select to authenticated
  using ((select auth.uid()) = user_id);
drop policy if exists push_subscriptions_insert_own on public.push_subscriptions;
drop policy if exists push_subscriptions_update_own on public.push_subscriptions;
drop policy if exists push_subscriptions_delete_own on public.push_subscriptions;
comment on table public.push_subscriptions is
  'Private Web Push endpoints. Read-only to the owning user; subscription registration and reassignment are performed by an authenticated server-side function using service credentials.';
