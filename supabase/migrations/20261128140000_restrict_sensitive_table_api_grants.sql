-- Reduce Data API exposure for records that are never public.
revoke all privileges on table
  public.profiles,
  public.appointments,
  public.favorites,
  public.subscriptions,
  public.payments,
  public.payment_events,
  public.wallet_transactions,
  public.admin_settings,
  public.audit_logs
from anon, public;

-- Public forms may submit inquiries and reports, but may not read or modify them.
revoke all privileges on table public.inquiries, public.reports from anon, public;
grant insert on table public.inquiries, public.reports to anon;
