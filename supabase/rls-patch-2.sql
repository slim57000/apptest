-- ============================================================================
-- Correctif RLS : récursion infinie sur challenge_members
-- À exécuter UNE FOIS dans SQL Editor, après `schema.sql` et `rls-patch.sql`.
--
-- La policy SELECT d'origine sur challenge_members (voir schema.sql) se
-- référence elle-même dans sa propre condition EXISTS -- une policy sur
-- challenge_members qui interroge challenge_members -- ce qui déclenche
-- une récursion infinie côté Postgres ("infinite recursion detected in
-- policy for relation \"challenge_members\""). Symptôme observé : 500 sur
-- GET /rest/v1/challenge_members, qui cassait silencieusement la création
-- ET l'affichage des défis (myChallenges() / memberStatuses() en
-- dépendent tous les deux).
-- ============================================================================

drop policy if exists "Les membres d'un défi sont visibles par les autres membres"
  on challenge_members;

-- Fonction SECURITY DEFINER : la vérification d'appartenance s'exécute
-- dans un contexte séparé qui ne redéclenche pas la policy RLS de
-- challenge_members sur elle-même -- même pattern que join_challenge()
-- dans rls-patch.sql.
create or replace function public.is_challenge_member(p_challenge_id uuid)
returns boolean
language sql
security definer
set search_path = ''
stable
as $$
  select exists (
    select 1
    from public.challenge_members
    where challenge_id = p_challenge_id
      and user_id = auth.uid ()
  );
$$;

revoke all on function public.is_challenge_member(uuid) from public;
revoke all on function public.is_challenge_member(uuid) from anon;
grant execute on function public.is_challenge_member(uuid) to authenticated;

create policy "Les membres d'un défi sont visibles par les autres membres"
  on challenge_members for select
  to authenticated
  using (is_challenge_member(challenge_id));
