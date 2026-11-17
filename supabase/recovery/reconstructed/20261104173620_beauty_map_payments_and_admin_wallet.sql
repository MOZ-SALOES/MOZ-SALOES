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
20261104173620 | beauty_map_payments_and_admin_wallet

OBJECTOS FINANCEIROS ACTUAIS:
- public.listing_plans
- public.listing_payments
- public.listing_promotions
- public.platform_settings
- public.admin_users
- private.admin_accounts
- private.platform_settings
- private.platform_wallet_ledger

Observacoes actuais:
- listing_payments guarda valor em MZN, metodo, fornecedor, referencia,
  estado e data de pagamento.
- platform_wallet_ledger regista entradas/saidas da carteira da plataforma.
- private.platform_settings e private.platform_wallet_ledger estao protegidas
  por politicas administrativas.
- public.platform_settings inclui configuracoes publicas/administrativas.

Nao foram recuperados os INSERT originais dos planos, nem a definicao original
de comissoes, taxas, triggers financeiros ou RPCs desta versao. Os dados e
definicoes actuais podem ter sido alterados depois da migracao.
*/