/*
===============================================================================
RECUPERACAO DE HISTORICO — BEAUTY MAP MOZ / MOZ-SALOES
ESTADO: RECONSTRUCAO DOCUMENTAL A PARTIR DO CATALOGO ACTUAL DO SUPABASE
NAO E A FONTE SQL ORIGINAL.
NAO EXECUTAR EM PRODUCAO. NAO COPIAR PARA supabase/migrations/.
NAO USAR PARA db push, migration repair ou reconstruir uma base vazia.

Project ref: wmcypueuaszizekaljok
Origem da evidencia: catalogo PostgreSQL consultado em 2026-11-17.
Limite: o catalogo mostra o estado actual, nao a sequencia historica de DDL,
nem permite provar quais comandos existiam em cada migracao original.
Este ficheiro e um registo de recuperacao/auditoria, nao uma migracao executavel.
===============================================================================
*/

/*
MIGRACAO HISTORICA REGISTADA:
20261104173116 | beauty_map_security_hardening

EVIDENCIA ACTUAL:
- RLS activo nas tabelas publicas e privadas inspeccionadas.
- Politicas de proprietario em salons, services, salon_images e salon_hours.
- Leitura publica limitada a saloes activos e conteudos publicados/activos.
- Politicas administrativas baseadas em public.admin_users.
- Funcoes observadas: public.handle_new_user(), public.set_updated_at(),
  public.rls_auto_enable(), private.is_admin().
- Trigger de criacao de perfil utilizador: public.handle_new_user()
  (a definicao da funcao foi observada; o trigger auth.users nao foi exportado
  nesta consulta, pelo que a sua existencia deve ser confirmada separadamente).

ATENCAO:
As politicas abaixo sao apenas descritas no catalogo actual; nao se afirma que
todas tenham sido criadas nesta migracao especifica. O estado actual inclui
alteracoes posteriores.
*/