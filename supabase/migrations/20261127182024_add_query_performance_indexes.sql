-- Improve join and ownership-query performance for MOZ SALOES.
-- All indexes are additive and safe to apply more than once.
CREATE INDEX IF NOT EXISTS admin_notifications_actor_id_idx ON public.admin_notifications (actor_id);
CREATE INDEX IF NOT EXISTS appointments_service_id_idx ON public.appointments (service_id);
CREATE INDEX IF NOT EXISTS audit_logs_actor_id_idx ON public.audit_logs (actor_id);
CREATE INDEX IF NOT EXISTS favorites_salon_id_idx ON public.favorites (salon_id);
CREATE INDEX IF NOT EXISTS inquiries_customer_id_idx ON public.inquiries (customer_id);
CREATE INDEX IF NOT EXISTS inquiries_salon_created_idx ON public.inquiries (salon_id, created_at DESC);
CREATE INDEX IF NOT EXISTS payment_events_payment_id_idx ON public.payment_events (payment_id);
CREATE INDEX IF NOT EXISTS payments_payer_id_idx ON public.payments (payer_id);
CREATE INDEX IF NOT EXISTS payments_salon_id_idx ON public.payments (salon_id);
CREATE INDEX IF NOT EXISTS payments_subscription_id_idx ON public.payments (subscription_id);
CREATE INDEX IF NOT EXISTS promotion_salons_salon_id_idx ON public.promotion_salons (salon_id);
CREATE INDEX IF NOT EXISTS reports_reporter_id_idx ON public.reports (reporter_id);
CREATE INDEX IF NOT EXISTS reports_salon_id_idx ON public.reports (salon_id);
CREATE INDEX IF NOT EXISTS reviews_customer_id_idx ON public.reviews (customer_id);
CREATE INDEX IF NOT EXISTS salon_images_salon_id_idx ON public.salon_images (salon_id);
CREATE INDEX IF NOT EXISTS salons_category_id_idx ON public.salons (category_id);
CREATE INDEX IF NOT EXISTS services_category_id_idx ON public.services (category_id);
CREATE INDEX IF NOT EXISTS subscriptions_plan_id_idx ON public.subscriptions (plan_id);
CREATE INDEX IF NOT EXISTS subscriptions_salon_id_idx ON public.subscriptions (salon_id);
CREATE INDEX IF NOT EXISTS wallet_transactions_payment_id_idx ON public.wallet_transactions (payment_id);

-- Speed up the owner's pending-appointment queue without changing access rules.
CREATE INDEX IF NOT EXISTS appointments_salon_pending_date_idx
  ON public.appointments (salon_id, appointment_date, appointment_time)
  WHERE status = 'pending';

-- Support recent enquiries in the private owner workspace.
CREATE INDEX IF NOT EXISTS inquiries_salon_recent_idx
  ON public.inquiries (salon_id, created_at DESC);