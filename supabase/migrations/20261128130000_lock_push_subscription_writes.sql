-- Push subscriptions are written only by the authenticated server-side function.
-- A globally unique endpoint prevents a shared browser/device from remaining attached to a previous account.
alter table public.push_subscriptions
  drop constraint if exists push_subscriptions_user_endpoint_unique;

do $$
begin
  if not exists (
    select 1
      from pg_constraint
     where conrelid = 'public.push_subscriptions'::regclass
       and conname = 'push_subscriptions_endpoint_unique'
  ) then
    alter table public.push_subscriptions
      add constraint push_subscriptions_endpoint_unique unique (endpoint);
  end if;
end;
$$;

revoke insert, update, delete on table public.push_subscriptions from anon, public, authenticated;
grant select on table public.push_subscriptions to authenticated;

drop policy if exists push_subscriptions_insert_own on public.push_subscriptions;
drop policy if exists push_subscriptions_update_own on public.push_subscriptions;
drop policy if exists push_subscriptions_delete_own on public.push_subscriptions;
drop policy if exists push_subscriptions_select_own on public.push_subscriptions;

create policy push_subscriptions_select_own
  on public.push_subscriptions for select to authenticated
  using ((select auth.uid()) = user_id);

comment on table public.push_subscriptions is
  'Private Web Push endpoints. Read-only to the owning user; subscription registration and reassignment are performed by an authenticated server-side function using service credentials.';
