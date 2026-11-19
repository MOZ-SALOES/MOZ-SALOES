-- Keep client privileges minimal; RLS remains the row-level boundary.
revoke all privileges on table public.reviews from anon, authenticated;
revoke all privileges on table public.inquiries from anon, authenticated;
revoke all privileges on table public.reports from anon, authenticated;

grant select on table public.reviews to anon, authenticated;
grant insert, update, delete on table public.reviews to authenticated;

grant insert (salon_id, customer_id, customer_name, customer_phone, message)
  on table public.inquiries to anon, authenticated;
grant select on table public.inquiries to authenticated;

grant insert (salon_id, reporter_id, reason, details)
  on table public.reports to anon, authenticated;
grant select, update, delete on table public.reports to authenticated;

-- New reviews must enter moderation, never publish by default.
alter table public.reviews alter column status set default 'pending';

-- Replace overly broad review policies.
drop policy if exists reviews_customer_insert on public.reviews;
drop policy if exists reviews_owner_or_admin_update on public.reviews;
drop policy if exists reviews_admin_manage on public.reviews;
create policy reviews_customer_insert
  on public.reviews for insert to authenticated
  with check (
    customer_id = (select auth.uid())
    and status = 'pending'
    and exists (
      select 1 from public.salons s
      where s.id = reviews.salon_id and s.status = 'active'
    )
  );
create policy reviews_admin_manage
  on public.reviews for all to authenticated
  using ((select private.is_admin()))
  with check ((select private.is_admin()));

-- Public contact requests: only for currently active salons; callers cannot
-- impersonate another signed-in customer.
drop policy if exists inquiries_customer_insert on public.inquiries;
create policy inquiries_customer_insert
  on public.inquiries for insert to anon, authenticated
  with check (
    exists (
      select 1 from public.salons s
      where s.id = inquiries.salon_id and s.status = 'active'
    )
    and (
      (auth.uid() is null and customer_id is null)
      or
      (auth.uid() is not null and customer_id = (select auth.uid()))
    )
    and customer_name is not null
    and char_length(btrim(customer_name)) between 2 and 100
    and customer_phone is not null
    and customer_phone ~ '^[+0-9() .-]{7,25}$'
    and message is not null
    and char_length(btrim(message)) between 5 and 2000
  );

-- Public reports may be submitted without exposing reports to the public.
drop policy if exists reports_public_insert on public.reports;
create policy reports_public_insert
  on public.reports for insert to anon, authenticated
  with check (
    (salon_id is null or exists (
      select 1 from public.salons s where s.id = reports.salon_id
    ))
    and (
      (auth.uid() is null and reporter_id is null)
      or
      (auth.uid() is not null and reporter_id = (select auth.uid()))
    )
    and char_length(btrim(reason)) between 3 and 120
    and (details is null or char_length(details) <= 2000)
    and status = 'open'
  );

-- Add input-size checks without blocking migration on any historical rows.
alter table public.inquiries
  add constraint inquiries_customer_name_length_check
  check (customer_name is null or char_length(btrim(customer_name)) between 2 and 100) not valid;
alter table public.inquiries
  add constraint inquiries_customer_phone_format_check
  check (customer_phone is null or customer_phone ~ '^[+0-9() .-]{7,25}$') not valid;
alter table public.inquiries
  add constraint inquiries_message_length_check
  check (message is null or char_length(btrim(message)) <= 2000) not valid;
alter table public.reports
  add constraint reports_reason_length_check
  check (char_length(btrim(reason)) between 3 and 120) not valid;
alter table public.reports
  add constraint reports_details_length_check
  check (details is null or char_length(details) <= 2000) not valid;

-- Ensure RLS stays enabled.
alter table public.reviews enable row level security;
alter table public.inquiries enable row level security;
alter table public.reports enable row level security;

