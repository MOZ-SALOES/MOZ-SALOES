-- Send a minimal public invalidation event whenever directory-visible data changes.
-- The payload intentionally contains no salon, owner, payment, or customer data.
CREATE OR REPLACE FUNCTION public.broadcast_directory_invalidation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  PERFORM realtime.send(
    jsonb_build_object(
      'table_name', TG_TABLE_NAME,
      'operation', TG_OP
    ),
    'directory_changed',
    'moz-saloes:public',
    false
  );
  RETURN NULL;
END;
$$;

REVOKE ALL ON FUNCTION public.broadcast_directory_invalidation() FROM PUBLIC, anon, authenticated;

DO $$
DECLARE
  table_name text;
BEGIN
  FOREACH table_name IN ARRAY ARRAY[
    'salons',
    'salon_images',
    'categories',
    'services',
    'salon_hours',
    'subscription_plans',
    'promotions',
    'promotion_salons',
    'reviews'
  ]
  LOOP
    IF to_regclass('public.' || table_name) IS NOT NULL THEN
      EXECUTE format(
        'DROP TRIGGER IF EXISTS broadcast_directory_invalidation_trigger ON public.%I',
        table_name
      );
      EXECUTE format(
        'CREATE TRIGGER broadcast_directory_invalidation_trigger
         AFTER INSERT OR UPDATE OR DELETE ON public.%I
         FOR EACH ROW
         EXECUTE FUNCTION public.broadcast_directory_invalidation()',
        table_name
      );
    END IF;
  END LOOP;
END
$$;
