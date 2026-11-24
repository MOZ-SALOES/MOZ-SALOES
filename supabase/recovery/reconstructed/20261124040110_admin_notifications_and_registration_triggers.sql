/*
RECUPERACAO DOCUMENTAL — NAO E O SQL ORIGINAL.
Versao registada no Supabase: 20261124040110
Nome registado: admin_notifications_and_registration_triggers

Estado actual verificado:
- public.admin_notifications existe com recipient_id, notification_type,
  title, message, actor_id, entity_type, entity_id, metadata, read_at,
  created_at.
- private.create_admin_notification() cria notificacoes para perfis admin
  quando sao inseridos novos profiles, salons e services.
- Triggers AFTER INSERT:
  public.profiles -> notify_admin_new_profile
  public.salons -> notify_admin_new_salon
  public.services -> notify_admin_new_service
- Politicas de leitura/actualizacao/eliminacao limitam as notificacoes ao
  administrador destinatario validado por private.is_admin().

A definicao actual da funcao e os triggers foram inspeccionados directamente
na base de dados. O texto original da migracao nao foi recuperado.

Este arquivo e documental e nao deve ser aplicado novamente.
*/