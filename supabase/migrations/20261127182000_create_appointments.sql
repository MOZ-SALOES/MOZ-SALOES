-- Appointment schema used by customer, owner and administrator workflows.
create table if not exists public.appointments (
  id uuid primary key default gen_random_uuid(),
  salon_id uuid not null references public.salons(id) on delete cascade,
  service_id uuid references public.services(id) on delete set null,
  customer_id uuid not null references public.profiles(id) on delete cascade,
  customer_phone text not null,
  appointment_date date not null check (appointment_date >= current_date),
  appointment_time time not null,
  customer_note text,
  owner_response text,
  status text not null default 'pending'
    check (status in ('pending','accepted','rejected','cancelled','completed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists appointments_customer_date_idx
  on public.appointments(customer_id, appointment_date desc, appointment_time);
create index if not exists appointments_salon_date_idx
  on public.appointments(salon_id, appointment_date, appointment_time);
create index if not exists appointments_service_id_idx
  on public.appointments(service_id);
create index if not exists appointments_salon_pending_date_idx
  on public.appointments(salon_id, appointment_date, appointment_time)
  where status='pending';
alter table public.appointments enable row level security;
drop policy if exists appointments_admin_read on public.appointments;
create policy appointments_admin_read on public.appointments for select to authenticated
  using ((select private.is_admin()));
drop policy if exists appointments_customer_create on public.appointments;
create policy appointments_customer_create on public.appointments for insert to authenticated
  with check (
    customer_id=(select auth.uid())
    and exists(select 1 from public.salons s where s.id=salon_id and s.status='active')
    and (service_id is null or exists(
      select 1 from public.services sv
      where sv.id=service_id and sv.salon_id=salon_id and sv.active=true
    ))
    and status='pending'
  );
drop policy if exists appointments_customer_read on public.appointments;
create policy appointments_customer_read on public.appointments for select to authenticated
  using (customer_id=(select auth.uid()));
drop policy if exists appointments_owner_decide on public.appointments;
create policy appointments_owner_decide on public.appointments for update to authenticated
  using (
    status='pending' and exists(
      select 1 from public.salons s where s.id=salon_id and s.owner_id=(select auth.uid())
    )
  )
  with check (
    status in ('accepted','rejected') and exists(
      select 1 from public.salons s where s.id=salon_id and s.owner_id=(select auth.uid())
    )
  );
drop policy if exists appointments_owner_read on public.appointments;
create policy appointments_owner_read on public.appointments for select to authenticated
  using (exists(select 1 from public.salons s where s.id=salon_id and s.owner_id=(select auth.uid())));
create or replace function public.appointments_touch_updated_at()
returns trigger language plpgsql set search_path = '' as $function$
begin
  new.updated_at = now();
  return new;
end;
$function$;
drop trigger if exists appointments_touch_updated_at on public.appointments;
create trigger appointments_touch_updated_at before update on public.appointments
  for each row execute function public.appointments_touch_updated_at();
do $publication$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname='supabase_realtime' and schemaname='public' and tablename='appointments'
  ) then
    alter publication supabase_realtime add table public.appointments;
  end if;
end;
$publication$;
