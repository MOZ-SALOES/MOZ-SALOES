-- Persistent, private notifications for authenticated MOZ SALÕES customers and owners.
create schema if not exists private;

create table if not exists public.user_notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references auth.users(id) on delete cascade,
  notification_type text not null,
  title text not null,
  message text not null,
  entity_type text,
  entity_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists user_notifications_recipient_created_idx
  on public.user_notifications (recipient_id, created_at desc);

create index if not exists user_notifications_unread_idx
  on public.user_notifications (recipient_id, created_at desc)
  where read_at is null;

alter table public.user_notifications enable row level security;

drop policy if exists user_notifications_read_own on public.user_notifications;
create policy user_notifications_read_own
  on public.user_notifications for select
  to authenticated
  using ((select auth.uid()) = recipient_id);

drop policy if exists user_notifications_update_own on public.user_notifications;
create policy user_notifications_update_own
  on public.user_notifications for update
  to authenticated
  using ((select auth.uid()) = recipient_id)
  with check ((select auth.uid()) = recipient_id);

drop policy if exists user_notifications_delete_own on public.user_notifications;
create policy user_notifications_delete_own
  on public.user_notifications for delete
  to authenticated
  using ((select auth.uid()) = recipient_id);

grant select, delete on public.user_notifications to authenticated;
grant update (read_at) on public.user_notifications to authenticated;

create or replace function private.notify_appointment_participants()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_owner_id uuid;
  v_salon_name text;
  v_when text;
begin
  select s.owner_id, s.name
    into v_owner_id, v_salon_name
    from public.salons s
   where s.id = new.salon_id;

  if v_owner_id is null then
    return new;
  end if;

  v_when := to_char(new.appointment_date, 'DD/MM/YYYY') || ' às ' ||
            to_char(new.appointment_time, 'HH24:MI');

  if tg_op = 'INSERT' and new.status = 'pending' then
    if v_owner_id is distinct from new.customer_id then
      insert into public.user_notifications
        (recipient_id, notification_type, title, message, entity_type, entity_id, metadata)
      values
        (v_owner_id, 'appointment_new', 'Nova marcação recebida',
         'Recebeste um pedido para ' || v_salon_name || ' em ' || v_when || '.',
         'appointment', new.id,
         jsonb_build_object('salon_id', new.salon_id, 'appointment_id', new.id));
    end if;
  elsif tg_op = 'UPDATE' and new.status is distinct from old.status then
    if new.status in ('accepted', 'rejected') and new.customer_id is not null then
      insert into public.user_notifications
        (recipient_id, notification_type, title, message, entity_type, entity_id, metadata)
      values
        (new.customer_id,
         case when new.status = 'accepted' then 'appointment_accepted' else 'appointment_rejected' end,
         case when new.status = 'accepted' then 'Marcação aceite' else 'Marcação recusada' end,
         case when new.status = 'accepted'
              then 'O teu pedido em ' || v_salon_name || ' para ' || v_when || ' foi aceite.'
              else 'O teu pedido em ' || v_salon_name || ' para ' || v_when || ' foi recusado.' end,
         'appointment', new.id,
         jsonb_build_object('salon_id', new.salon_id, 'appointment_id', new.id, 'status', new.status));
    end if;
  end if;

  return new;
end;
$function$;

revoke all on function private.notify_appointment_participants() from public, anon, authenticated;

drop trigger if exists notify_appointment_participants on public.appointments;
create trigger notify_appointment_participants
  after insert or update of status on public.appointments
  for each row execute function private.notify_appointment_participants();

do $publication$
begin
  if not exists (
    select 1 from pg_publication_tables
     where pubname = 'supabase_realtime'
       and schemaname = 'public'
       and tablename = 'user_notifications'
  ) then
    alter publication supabase_realtime add table public.user_notifications;
  end if;
end;
$publication$;
