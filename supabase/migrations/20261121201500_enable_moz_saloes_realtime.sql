-- Enable database change streams for the live MOZ SALÕES interface.
-- RLS continues to control which rows each connected user can receive.
DO $$
DECLARE
  table_name text;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime'
  ) THEN
    CREATE PUBLICATION supabase_realtime;
  END IF;

  FOREACH table_name IN ARRAY ARRAY[
    'salons',
    'salon_images',
    'categories',
    'services',
    'salon_hours',
    'subscription_plans',
    'subscriptions',
    'payments',
    'payment_events',
    'wallet_transactions',
    'promotions',
    'promotion_salons',
    'reviews',
    'favorites',
    'inquiries',
    'reports',
    'admin_settings',
    'audit_logs',
    'profiles',
    'appointments'
  ]
  LOOP
    IF to_regclass('public.' || table_name) IS NOT NULL
       AND NOT EXISTS (
         SELECT 1
         FROM pg_publication_tables
         WHERE pubname = 'supabase_realtime'
           AND schemaname = 'public'
           AND tablename = table_name
       )
    THEN
      EXECUTE format(
        'ALTER PUBLICATION supabase_realtime ADD TABLE public.%I',
        table_name
      );
    END IF;
  END LOOP;
END
$$;
