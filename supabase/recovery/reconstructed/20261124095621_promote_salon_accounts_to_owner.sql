/*
RECUPERACAO DOCUMENTAL — NAO E O SQL ORIGINAL.
Versao registada no Supabase: 20261124095621
Nome registado: promote_salon_accounts_to_owner

Funcao actual verificada:
private.mark_profile_as_owner_after_salon_insert()
- apos INSERT em public.salons, actualiza public.profiles.role para 'owner'
  quando profiles.id = salons.owner_id e a role anterior era 'customer'.

Trigger actual:
public.salons.salons_mark_owner_profile
AFTER INSERT EXECUTE FUNCTION
private.mark_profile_as_owner_after_salon_insert()

Existe tambem o trigger set_profile_owner_role_trigger, associado a
set_profile_owner_role(). O texto original da migracao nao foi recuperado.

Arquivo de recuperacao documental. Nao aplicar em producao.
*/