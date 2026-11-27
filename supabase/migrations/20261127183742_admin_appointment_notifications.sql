-- Extend the private appointment trigger to notify the platform administrators as well.
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

revoke all on function private.notify_appointment_participants() from public, anon, authenticated;
