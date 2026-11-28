-- Private administrator notification inbox.
create table if not exists public.admin_notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references auth.users(id) on delete cascade,
  notification_type text not null,
  title text not null,
  message text not null,
  actor_id uuid references auth.users(id) on delete set null,
  entity_type text,
  entity_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists admin_notifications_recipient_created_idx
  on public.admin_notifications(recipient_id, created_at desc);
create index if not exists admin_notifications_actor_id_idx
  on public.admin_notifications(actor_id);
alter table public.admin_notifications enable row level security;
drop policy if exists admin_notifications_admin_read on public.admin_notifications;
create policy admin_notifications_admin_read on public.admin_notifications for select to authenticated
  using (recipient_id=(select auth.uid()) and (select private.is_admin()));
drop policy if exists admin_notifications_admin_update on public.admin_notifications;
create policy admin_notifications_admin_update on public.admin_notifications for update to authenticated
  using (recipient_id=(select auth.uid()) and (select private.is_admin()))
  with check (recipient_id=(select auth.uid()) and (select private.is_admin()));
drop policy if exists admin_notifications_admin_delete on public.admin_notifications;
create policy admin_notifications_admin_delete on public.admin_notifications for delete to authenticated
  using (recipient_id=(select auth.uid()) and (select private.is_admin()));
revoke all on table public.admin_notifications from public, anon, authenticated;
grant select on table public.admin_notifications to authenticated;
grant update (read_at) on table public.admin_notifications to authenticated;
do $publication$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname='supabase_realtime' and schemaname='public' and tablename='admin_notifications'
  ) then
    alter publication supabase_realtime add table public.admin_notifications;
  end if;
end;
$publication$;
