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
20261104173626 | beauty_map_payment_backend_privileges

EVIDENCIA ACTUAL:
- Tabelas financeiras expostas publicamente possuem RLS activo.
- Dados internos de carteira/configuracao encontram-se no schema private.
- private.is_admin() e SECURITY DEFINER, com search_path vazio.
- Politicas de acesso a private.platform_settings, private.platform_wallet_ledger
  e private.withdrawal_requests usam private.is_admin().
- public.listing_payments tem politicas separadas para proprietario e admin.

LIMITE IMPORTANTE:
O catalogo consultado nao devolveu a totalidade dos GRANT/REVOKE historicos
nem os privilegios originais apos cada migracao. Este documento nao deve ser
usado para conceder privilegios. A auditoria de grants deve ser exportada
separadamente antes de qualquer restauracao.
*/