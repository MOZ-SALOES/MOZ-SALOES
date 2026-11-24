/*
RECUPERACAO DOCUMENTAL — NAO E O SQL ORIGINAL.
Versao registada no Supabase: 20261122141630
Nome registado: add_independent_beauty_providers

O ficheiro original nao foi encontrado no GitHub e o historico de migracoes
do Supabase fornece apenas version/name, nao o texto SQL.

Reconstrucao documental baseada no esquema actual:
- public.salons.provider_type TEXT NOT NULL DEFAULT 'salon'
- public.salons.service_mode TEXT NOT NULL DEFAULT 'at_location'
- public.salons.service_address TEXT
- public.salons.service_areas TEXT
- public.salons.experience_years INTEGER
- public.salons.specialties TEXT[] NOT NULL DEFAULT '{}'
- public.salons.certificates TEXT
- public.salons.languages TEXT[] NOT NULL DEFAULT '{}'

Este arquivo e um registo de recuperacao, nao uma migracao executavel.
Nao aplicar novamente em producao.
*/