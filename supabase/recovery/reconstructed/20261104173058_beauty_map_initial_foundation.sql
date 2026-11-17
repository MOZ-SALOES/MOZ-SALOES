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
20261104173058 | beauty_map_initial_foundation

OBJECTOS ACTUAIS RELACIONADOS (inventario observado):
- public.profiles
- public.location_regions
- public.categories
- public.salons
- public.services
- public.salon_images
- public.salon_hours
- public.salon_reviews
- public.salon_comments
- public.salon_favorites
- public.salon_reports

O estado actual confirma 10 categorias e 11 registos de localizacao.
As tabelas publicas listadas estavam com RLS activo no momento da consulta.

Nao foi possivel recuperar o DDL original, ordem de criacao, comentarios,
seeds exactos, nem a definicao original de constraints e indices desta versao.
Para uma recuperacao executavel, obter backup/dump oficial e comparar com
pg_dump --schema-only numa instancia isolada.
*/