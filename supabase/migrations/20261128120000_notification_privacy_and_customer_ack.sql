-- Tighten notification data permissions and ensure customers receive a persistent acknowledgement.

-- RLS policies for public catalogue rows also call this helper as anon; remove the broad PUBLIC grant and grant only the two API roles explicitly.
revoke all on function private.is_admin() from public;
grant execute on function private.is_admin() to anon, authenticated;
-- Users may read their own messages and update only read_at; they cannot rewrite/delete message content.

revoke update, delete on table public.user_notifications from anon, public, authenticated;
grant update (read_at) on table public.user_notifications to authenticated;
drop policy if exists user_notifications_delete_own on public.user_notifications;

revoke update, delete on table public.admin_notifications from anon, public, authenticated;
grant update (read_at) on table public.admin_notifications to authenticated;
drop policy if exists admin_notifications_admin_delete on public.admin_notifications;

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
    -- Cliente recebe confirmação persistente de que o pedido foi enviado.
    insert into public.user_notifications
      (recipient_id, notification_type, title, message, entity_type, entity_id, metadata)
    values
      (new.customer_id, 'appointment_submitted', 'Pedido de marcação enviado',
       'O teu pedido para ' || v_salon_name || ' em ' || v_when || ' foi enviado e aguarda resposta.',
       'appointment', new.id,
       jsonb_build_object('salon_id', new.salon_id, 'appointment_id', new.id, 'status', new.status));

    -- Proprietário recebe o pedido, sem expor os dados do cliente na notificação push.
    if v_owner_id is distinct from new.customer_id then
      insert into public.user_notifications
        (recipient_id, notification_type, title, message, entity_type, entity_id, metadata)
      values
        (v_owner_id, 'appointment_new', 'Nova marcação recebida',
         'Recebeste um pedido para ' || v_salon_name || ' em ' || v_when || '.',
         'appointment', new.id,
         jsonb_build_object('salon_id', new.salon_id, 'appointment_id', new.id));
    end if;

    insert into public.admin_notifications
      (recipient_id, notification_type, title, message, actor_id, entity_type, entity_id, metadata)
    select p.id, 'appointment_new', 'Nova marcação no MOZ SALÕES',
           'Foi recebido um pedido de atendimento para ' || v_salon_name || ' em ' || v_when || '.',
           new.customer_id, 'appointment', new.id,
           jsonb_build_object('salon_id', new.salon_id, 'appointment_id', new.id)
      from public.profiles p
     where p.role = 'admin';

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

      insert into public.admin_notifications
        (recipient_id, notification_type, title, message, actor_id, entity_type, entity_id, metadata)
      select p.id,
             case when new.status = 'accepted' then 'appointment_accepted' else 'appointment_rejected' end,
             case when new.status = 'accepted' then 'Marcação aceite pelo salão' else 'Marcação recusada pelo salão' end,
             'O pedido para ' || v_salon_name || ' em ' || v_when ||
               case when new.status = 'accepted' then ' foi aceite.' else ' foi recusado.' end,
             v_owner_id, 'appointment', new.id,
             jsonb_build_object('salon_id', new.salon_id, 'appointment_id', new.id, 'status', new.status)
        from public.profiles p
       where p.role = 'admin';
    end if;
  end if;

  return new;
end;
$function$;

-- Ensure only the trusted trigger owner can execute this privileged function.
revoke all on function private.notify_appointment_participants() from public, anon, authenticated;
