-- Remove default broad table grants; expose only the actions required by the account notification UI.
revoke all on table public.user_notifications from public, anon, authenticated;
grant select, delete on table public.user_notifications to authenticated;
grant update (read_at) on table public.user_notifications to authenticated;
