create extension if not exists pgcrypto;
create schema if not exists private;

create table public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 full_name text not null default '',
 email text,
 phone text,
 role text not null default 'customer' check (role in ('customer','owner','admin')),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);

create or replace function private.is_admin()
returns boolean language sql stable security definer set search_path = ''
as $$
 select exists (
   select 1 from public.profiles p
   where p.id = (select auth.uid()) and p.role = 'admin'
 );
$$;
revoke all on function private.is_admin() from public;
grant usage on schema private to authenticated;
grant execute on function private.is_admin() to authenticated;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
 insert into public.profiles(id, full_name, email, role)
 values (
   new.id,
   coalesce(new.raw_user_meta_data->>'full_name',''),
   new.email,
   case when lower(coalesce(new.email,'')) = 'miltonjustino888@gmail.com' then 'admin' else 'customer' end
 )
 on conflict (id) do update set email = excluded.email;
 return new;
end;
$$;
drop trigger if exists on_auth_user_created_moz_saloes on auth.users;
create trigger on_auth_user_created_moz_saloes
 after insert on auth.users for each row execute procedure public.handle_new_user();

create table public.categories (
 id uuid primary key default gen_random_uuid(),
 name text not null unique,
 slug text not null unique,
 description text,
 active boolean not null default true,
 sort_order int not null default 0,
 created_at timestamptz not null default now()
);

create table public.salons (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null references public.profiles(id) on delete cascade,
 name text not null,
 slug text unique,
 description text,
 category_id uuid references public.categories(id) on delete set null,
 phone text,
 whatsapp text,
 email text,
 province text not null,
 district text not null,
 municipality text,
 city text,
 neighborhood text,
 address text,
 latitude double precision,
 longitude double precision,
 status text not null default 'pending' check (status in ('pending','active','suspended','rejected')),
 verified boolean not null default false,
 publication_expires_at timestamptz,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);

create table public.services (
 id uuid primary key default gen_random_uuid(),
 salon_id uuid not null references public.salons(id) on delete cascade,
 category_id uuid references public.categories(id) on delete set null,
 name text not null,
 description text,
 price_mzn numeric(12,2),
 price_type text not null default 'fixed' check (price_type in ('fixed','variable','from')),
 duration_minutes int,
 image_path text,
 active boolean not null default true,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 check (price_mzn is null or price_mzn >= 0)
);

create table public.salon_images (
 id uuid primary key default gen_random_uuid(),
 salon_id uuid not null references public.salons(id) on delete cascade,
 image_path text not null,
 caption text,
 sort_order int not null default 0,
 created_at timestamptz not null default now()
);

create table public.salon_hours (
 id uuid primary key default gen_random_uuid(),
 salon_id uuid not null references public.salons(id) on delete cascade,
 weekday smallint not null check (weekday between 0 and 6),
 opens_at time,
 closes_at time,
 closed boolean not null default false,
 unique(salon_id, weekday)
);

create table public.subscription_plans (
 id uuid primary key default gen_random_uuid(),
 name text not null unique,
 duration_days int not null check (duration_days > 0),
 price_mzn numeric(12,2) not null check (price_mzn >= 0),
 active boolean not null default true,
 created_at timestamptz not null default now()
);

create table public.subscriptions (
 id uuid primary key default gen_random_uuid(),
 salon_id uuid not null references public.salons(id) on delete cascade,
 plan_id uuid not null references public.subscription_plans(id),
 status text not null default 'pending' check (status in ('pending','active','expired','cancelled')),
 starts_at timestamptz,
 ends_at timestamptz,
 created_at timestamptz not null default now()
);

create table public.payments (
 id uuid primary key default gen_random_uuid(),
 subscription_id uuid references public.subscriptions(id) on delete set null,
 salon_id uuid references public.salons(id) on delete set null,
 payer_id uuid references public.profiles(id) on delete set null,
 provider text check (provider in ('mpesa','emola','manual')),
 provider_reference text unique,
 amount_mzn numeric(12,2) not null check (amount_mzn >= 0),
 status text not null default 'pending' check (status in ('pending','confirmed','failed','refunded')),
 confirmed_at timestamptz,
 metadata jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);

create table public.payment_events (
 id uuid primary key default gen_random_uuid(),
 payment_id uuid references public.payments(id) on delete set null,
 provider text,
 event_type text,
 provider_event_id text unique,
 payload jsonb not null default '{}'::jsonb,
 processed_at timestamptz,
 created_at timestamptz not null default now()
);

create table public.wallet_transactions (
 id uuid primary key default gen_random_uuid(),
 payment_id uuid references public.payments(id) on delete set null,
 transaction_type text not null check (transaction_type in ('payment','fee','withdrawal','refund','adjustment')),
 amount_mzn numeric(12,2) not null,
 status text not null default 'pending' check (status in ('pending','confirmed','failed','cancelled')),
 description text,
 created_at timestamptz not null default now()
);

create table public.promotions (
 id uuid primary key default gen_random_uuid(),
 name text not null,
 description text,
 discount_type text not null check (discount_type in ('percentage','fixed_price')),
 discount_value numeric(12,2) not null check (discount_value >= 0),
 starts_at timestamptz,
 ends_at timestamptz,
 active boolean not null default false,
 funded_by text not null default 'platform' check (funded_by in ('platform','salon','shared')),
 created_at timestamptz not null default now()
);

create table public.promotion_salons (
 promotion_id uuid references public.promotions(id) on delete cascade,
 salon_id uuid references public.salons(id) on delete cascade,
 primary key (promotion_id, salon_id)
);

create table public.reviews (
 id uuid primary key default gen_random_uuid(),
 salon_id uuid not null references public.salons(id) on delete cascade,
 customer_id uuid not null references public.profiles(id) on delete cascade,
 rating smallint not null check (rating between 1 and 5),
 comment text,
 status text not null default 'published' check (status in ('published','hidden','pending')),
 created_at timestamptz not null default now(),
 unique(salon_id, customer_id)
);

create table public.favorites (
 customer_id uuid references public.profiles(id) on delete cascade,
 salon_id uuid references public.salons(id) on delete cascade,
 created_at timestamptz not null default now(),
 primary key (customer_id, salon_id)
);

create table public.inquiries (
 id uuid primary key default gen_random_uuid(),
 salon_id uuid not null references public.salons(id) on delete cascade,
 customer_id uuid references public.profiles(id) on delete set null,
 customer_name text,
 customer_phone text,
 message text,
 created_at timestamptz not null default now()
);

create table public.reports (
 id uuid primary key default gen_random_uuid(),
 salon_id uuid references public.salons(id) on delete cascade,
 reporter_id uuid references public.profiles(id) on delete set null,
 reason text not null,
 details text,
 status text not null default 'open' check (status in ('open','reviewing','resolved','dismissed')),
 created_at timestamptz not null default now()
);

create table public.admin_settings (
 key text primary key,
 value jsonb not null,
 updated_at timestamptz not null default now()
);

create table public.audit_logs (
 id uuid primary key default gen_random_uuid(),
 actor_id uuid references public.profiles(id) on delete set null,
 action text not null,
 entity_type text,
 entity_id uuid,
 details jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);

create index salons_owner_idx on public.salons(owner_id);
create index salons_search_idx on public.salons(status, province, district, neighborhood);
create index services_salon_idx on public.services(salon_id, active);
create index reviews_salon_idx on public.reviews(salon_id, status);
create index payments_status_idx on public.payments(status, created_at desc);

insert into public.categories(name,slug,sort_order) values
 ('Cabelo','cabelo',1),('Tranças','trancas',2),('Unhas','unhas',3),
 ('Dreadlocks','dreadlocks',4),('Barbearia','barbearia',5),
 ('Maquilhagem','maquilhagem',6),('Tratamentos','tratamentos',7),
 ('Sobrancelhas e pestanas','sobrancelhas-pestanas',8),('Beleza geral','beleza-geral',9)
on conflict (slug) do nothing;

insert into public.subscription_plans(name,duration_days,price_mzn) values
 ('30 dias',30,5),('60 dias',60,15),('90 dias',90,25)
on conflict (name) do nothing;

insert into public.admin_settings(key,value) values
 ('platform_name','"MOZ SALÕES"'),
 ('admin_email','"miltonjustino888@gmail.com"'),
 ('default_currency','"MZN"'),
 ('payments_enabled','false'),
 ('withdrawals_enabled','false')
on conflict (key) do nothing;

alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.salons enable row level security;
alter table public.services enable row level security;
alter table public.salon_images enable row level security;
alter table public.salon_hours enable row level security;
alter table public.subscription_plans enable row level security;
alter table public.subscriptions enable row level security;
alter table public.payments enable row level security;
alter table public.payment_events enable row level security;
alter table public.wallet_transactions enable row level security;
alter table public.promotions enable row level security;
alter table public.promotion_salons enable row level security;
alter table public.reviews enable row level security;
alter table public.favorites enable row level security;
alter table public.inquiries enable row level security;
alter table public.reports enable row level security;
alter table public.admin_settings enable row level security;
alter table public.audit_logs enable row level security;

create policy "profiles_read_self_or_admin" on public.profiles for select to authenticated using ((select auth.uid()) = id or (select private.is_admin()));
create policy "profiles_update_self_or_admin" on public.profiles for update to authenticated using ((select auth.uid()) = id or (select private.is_admin())) with check ((select auth.uid()) = id or (select private.is_admin()));

create policy "categories_public_read" on public.categories for select to anon, authenticated using (active or (select private.is_admin()));
create policy "categories_admin_manage" on public.categories for all to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));

create policy "salons_public_read_active" on public.salons for select to anon, authenticated using (status = 'active' or owner_id = (select auth.uid()) or (select private.is_admin()));
create policy "salons_owner_insert" on public.salons for insert to authenticated with check (owner_id = (select auth.uid()) and not (select private.is_admin()) is false or (select private.is_admin()));
create policy "salons_owner_update" on public.salons for update to authenticated using (owner_id = (select auth.uid()) or (select private.is_admin())) with check (owner_id = (select auth.uid()) or (select private.is_admin()));
create policy "salons_owner_delete" on public.salons for delete to authenticated using (owner_id = (select auth.uid()) or (select private.is_admin()));

create policy "services_public_read_active" on public.services for select to anon, authenticated using ((active and exists(select 1 from public.salons s where s.id=salon_id and s.status='active')) or exists(select 1 from public.salons s where s.id=salon_id and s.owner_id=(select auth.uid())) or (select private.is_admin()));
create policy "services_owner_manage" on public.services for all to authenticated using (exists(select 1 from public.salons s where s.id=salon_id and s.owner_id=(select auth.uid())) or (select private.is_admin())) with check (exists(select 1 from public.salons s where s.id=salon_id and s.owner_id=(select auth.uid())) or (select private.is_admin()));

create policy "salon_images_public_read" on public.salon_images for select to anon, authenticated using (exists(select 1 from public.salons s where s.id=salon_id and (s.status='active' or s.owner_id=(select auth.uid()))) or (select private.is_admin()));
create policy "salon_images_owner_manage" on public.salon_images for all to authenticated using (exists(select 1 from public.salons s where s.id=salon_id and s.owner_id=(select auth.uid())) or (select private.is_admin())) with check (exists(select 1 from public.salons s where s.id=salon_id and s.owner_id=(select auth.uid())) or (select private.is_admin()));

create policy "hours_public_read" on public.salon_hours for select to anon, authenticated using (exists(select 1 from public.salons s where s.id=salon_id and (s.status='active' or s.owner_id=(select auth.uid()))) or (select private.is_admin()));
create policy "hours_owner_manage" on public.salon_hours for all to authenticated using (exists(select 1 from public.salons s where s.id=salon_id and s.owner_id=(select auth.uid())) or (select private.is_admin())) with check (exists(select 1 from public.salons s where s.id=salon_id and s.owner_id=(select auth.uid())) or (select private.is_admin()));

create policy "plans_public_read_active" on public.subscription_plans for select to anon, authenticated using (active or (select private.is_admin()));
create policy "plans_admin_manage" on public.subscription_plans for all to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));

create policy "subscriptions_owner_read" on public.subscriptions for select to authenticated using (exists(select 1 from public.salons s where s.id=salon_id and s.owner_id=(select auth.uid())) or (select private.is_admin()));
create policy "subscriptions_admin_manage" on public.subscriptions for all to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));

create policy "payments_owner_read" on public.payments for select to authenticated using (payer_id=(select auth.uid()) or exists(select 1 from public.salons s where s.id=salon_id and s.owner_id=(select auth.uid())) or (select private.is_admin()));
create policy "payments_admin_manage" on public.payments for all to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));

create policy "payment_events_admin_only" on public.payment_events for all to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));
create policy "wallet_admin_only" on public.wallet_transactions for all to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));

create policy "promotions_public_read_active" on public.promotions for select to anon, authenticated using (active or (select private.is_admin()));
create policy "promotions_admin_manage" on public.promotions for all to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));
create policy "promotion_salons_public_read" on public.promotion_salons for select to anon, authenticated using (exists(select 1 from public.promotions p where p.id=promotion_id and p.active) or (select private.is_admin()));
create policy "promotion_salons_admin_manage" on public.promotion_salons for all to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));

create policy "reviews_public_read" on public.reviews for select to anon, authenticated using (status='published' or customer_id=(select auth.uid()) or (select private.is_admin()));
create policy "reviews_customer_insert" on public.reviews for insert to authenticated with check (customer_id=(select auth.uid()));
create policy "reviews_owner_or_admin_update" on public.reviews for update to authenticated using (exists(select 1 from public.salons s where s.id=salon_id and s.owner_id=(select auth.uid())) or customer_id=(select auth.uid()) or (select private.is_admin())) with check (exists(select 1 from public.salons s where s.id=salon_id and s.owner_id=(select auth.uid())) or customer_id=(select auth.uid()) or (select private.is_admin()));

create policy "favorites_self_manage" on public.favorites for all to authenticated using (customer_id=(select auth.uid()) or (select private.is_admin())) with check (customer_id=(select auth.uid()) or (select private.is_admin()));

create policy "inquiries_customer_insert" on public.inquiries for insert to anon, authenticated with check (true);
create policy "inquiries_owner_or_admin_read" on public.inquiries for select to authenticated using (exists(select 1 from public.salons s where s.id=salon_id and s.owner_id=(select auth.uid())) or (select private.is_admin()));

create policy "reports_public_insert" on public.reports for insert to anon, authenticated with check (true);
create policy "reports_admin_manage" on public.reports for all to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));

create policy "settings_admin_only" on public.admin_settings for all to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));
create policy "audit_admin_only" on public.audit_logs for all to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values ('salon-images','salon-images',true,5242880,array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;

create policy "salon_images_bucket_public_read" on storage.objects for select to anon, authenticated using (bucket_id='salon-images');
create policy "salon_images_owner_upload" on storage.objects for insert to authenticated with check (
 bucket_id='salon-images' and (storage.foldername(name))[1]=(select auth.uid())::text
);
create policy "salon_images_owner_update" on storage.objects for update to authenticated using (
 bucket_id='salon-images' and ((storage.foldername(name))[1]=(select auth.uid())::text or (select private.is_admin()))
) with check (
 bucket_id='salon-images' and ((storage.foldername(name))[1]=(select auth.uid())::text or (select private.is_admin()))
);
create policy "salon_images_owner_delete" on storage.objects for delete to authenticated using (
 bucket_id='salon-images' and ((storage.foldername(name))[1]=(select auth.uid())::text or (select private.is_admin()))
);

