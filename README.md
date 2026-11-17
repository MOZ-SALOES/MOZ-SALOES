# MOZ-SALOES — BEAUTY MAP MOZ

Repositório do directório digital de salões de Moçambique.

## Estado da recuperação do histórico Supabase

O repositório foi confirmado inicialmente vazio. O projecto Supabase
`wmcypueuaszizekaljok` apresenta seis versões no histórico de migrações,
mas as cinco fontes SQL originais de 04-11-2026 não estavam disponíveis
no GitHub nem foram recuperadas como ficheiros-fonte.

Por segurança, foram adicionados cinco **registos documentais de reconstrução**
em `supabase/recovery/reconstructed/`. Foram preparados a partir do catálogo
actual da base de dados, não do conteúdo original das migrações.

**Estes ficheiros NÃO são migrações executáveis.**
- Não os mover para `supabase/migrations/`.
- Não executar com `supabase db push`.
- Não usar `migration repair` para os marcar como aplicados.
- Não assumir que representam exactamente o estado histórico de cada versão.

Para reconstruir um histórico executável é necessário obter os SQL originais
de um backup/commit antigo ou produzir um dump oficial da estrutura actual,
validá-lo numa base isolada e criar uma nova linha de migrações controlada.

## Migrações registadas no Supabase

| Versão | Nome |
|---|---|
| 20261104173058 | beauty_map_initial_foundation |
| 20261104173116 | beauty_map_security_hardening |
| 20261104173620 | beauty_map_payments_and_admin_wallet |
| 20261104173626 | beauty_map_payment_backend_privileges |
| 20261104173745 | beauty_map_manual_mpesa_emola_withdrawal_preferences |
| 20261117131448 | protect_salon_system_fields |

A última versão acima é a migração de protecção dos campos internos dos salões.
