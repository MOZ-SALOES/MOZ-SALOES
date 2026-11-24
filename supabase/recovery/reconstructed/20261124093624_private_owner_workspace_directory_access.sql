/*
RECUPERACAO DOCUMENTAL — NAO E O SQL ORIGINAL.
Versao registada no Supabase: 20261124093624
Nome registado: private_owner_workspace_directory_access

Politicas actualmente verificadas:
- salons_owner_read_self: proprietario le apenas saloes cujo owner_id
  corresponde a auth.uid(); administrador tambem pode consultar.
- salons_owner_update / salons_owner_insert / salons_owner_delete:
  operacoes limitadas ao proprietario do registo ou administrador.
- services_owner_manage: gestao limitada aos servicos dos saloes do
  proprietario autenticado ou administrador.
- salon_images_owner_manage: gestao limitada as imagens dos saloes do
  proprietario autenticado ou administrador.
- appointments_owner_read / appointments_owner_decide: acesso e decisao
  limitados ao proprietario do salao associado.

A descricao acima reflecte politicas actualmente existentes, nao prova que
sejam a reproducao literal do SQL original da migracao.

Arquivo de recuperacao documental. Nao aplicar em producao.
*/