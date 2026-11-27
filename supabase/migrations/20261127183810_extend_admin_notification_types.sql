-- Allow the administrator inbox to store appointment lifecycle notifications.
alter table public.admin_notifications
  drop constraint if exists admin_notifications_notification_type_check;

alter table public.admin_notifications
  add constraint admin_notifications_notification_type_check
  check (notification_type = any (array[
    'user_registered'::text,
    'salon_registered'::text,
    'service_added'::text,
    'appointment_new'::text,
    'appointment_accepted'::text,
    'appointment_rejected'::text
  ]));
