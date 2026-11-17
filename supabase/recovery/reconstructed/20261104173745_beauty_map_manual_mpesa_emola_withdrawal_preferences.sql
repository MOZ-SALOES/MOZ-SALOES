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
20261104173745 | beauty_map_manual_mpesa_emola_withdrawal_preferences

OBJECTO ACTUAL:
private.withdrawal_requests

Campos observados:
- amount_mzn, fee_mzn, net_amount_mzn
- method: MPESA, EMOLA ou BANK
- destination_phone, destination_account, destination_name
- provider, provider_reference
- status: requested, processing, paid, failed, cancelled,
  reconciliation_required
- requested_by, processed_at, created_at

Indice observado:
withdrawal_requests_method_status_idx (method, status, created_at DESC)

A tabela estava com RLS activo e politica withdrawal_requests_admin_only.
Nao foram recuperados os comandos originais nem o fluxo operacional completo.
A presenca dos metodos no CHECK constraint nao prova que integracao de
pagamento ou levantamento esteja activa. Nao executar pagamentos a partir
deste registo.
*/