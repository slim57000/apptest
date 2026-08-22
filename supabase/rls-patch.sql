-- ============================================================================
-- Correctifs RLS suite à l'audit de sécurité (Habitudes+)
-- À exécuter UNE FOIS dans SQL Editor, après `schema.sql`.
--
-- Corrige :
--   #4 le 2e check-in du même jour échouait (upsert sans policy UPDATE) ;
--   #5 impossible de quitter un défi ou de supprimer ses check-ins ;
--   #2 fuite des codes d'invitation (SELECT ouvert sur `challenges`) ;
--   #3 auto-adhésion possible à n'importe quel défi par simple INSERT.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- #4 Check-ins : autoriser l'UPDATE (utilisé par l'UPSERT quotidien)
-- ---------------------------------------------------------------------------
create policy "Un membre peut mettre à jour son propre check-in"
  on challenge_checkins for update
  to authenticated
  using (
    auth.uid () = user_id
    and exists (
      select 1
      from challenge_members m
      where m.challenge_id = challenge_checkins.challenge_id
        and m.user_id = auth.uid ()
    )
  )
  with check (
    auth.uid () = user_id
    and exists (
      select 1
      from challenge_members m
      where m.challenge_id = challenge_checkins.challenge_id
        and m.user_id = auth.uid ()
    )
  );

-- ---------------------------------------------------------------------------
-- #5 Quitter un défi / effacer ses traces
-- ---------------------------------------------------------------------------
create policy "Un utilisateur peut quitter un défi"
  on challenge_members for delete
  to authenticated
  using (auth.uid () = user_id);

create policy "Un utilisateur peut supprimer ses propres check-ins"
  on challenge_checkins for delete
  to authenticated
  using (auth.uid () = user_id);

-- ---------------------------------------------------------------------------
-- #2 Les défis ne sont plus lisibles par tous : membres + créateur
-- uniquement. Un inconnu ne peut donc plus énumérer ni les défis, ni les
-- codes d'invitation.
-- ---------------------------------------------------------------------------
drop policy if exists "Les défis sont lisibles par tout utilisateur connecté"
  on challenges;

create policy "Les défis sont visibles par leurs membres"
  on challenges for select
  to authenticated
  using (
    created_by = auth.uid ()
    or exists (
      select 1
      from challenge_members m
      where m.challenge_id = id
        and m.user_id = auth.uid ()
    )
  );

-- ---------------------------------------------------------------------------
-- #2/#3 L'adhésion passe exclusivement par la fonction SECURITY DEFINER
-- `join_challenge(code)` : elle vérifie le code côté serveur et ne renvoie
-- que le défi rejoint. Plus personne ne peut insérer directement une ligne
-- dans `challenge_members`… sauf pour devenir membre de SON propre défi
-- fraîchement créé (nécessaire au flux de création).
-- ---------------------------------------------------------------------------
drop policy if exists "Un utilisateur peut rejoindre un défi en son nom propre"
  on challenge_members;

create policy "Le créateur devient membre de son propre défi"
  on challenge_members for insert
  to authenticated
  with check (
    auth.uid () = user_id
    and exists (
      select 1
      from challenges c
      where c.id = challenge_members.challenge_id
        and c.created_by = auth.uid ()
    )
  );

create or replace function public.join_challenge(p_code text)
returns setof public.challenges
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid ();
  v_challenge public.challenges;
begin
  if v_uid is null then
    raise exception 'Authentification requise';
  end if;

  -- Profil requis par la clé étrangère de challenge_members ; créé au vol
  -- si l'utilisateur n'a jamais renseigné de pseudo.
  insert into public.profiles (id, display_name)
  values (v_uid, 'Joueur')
  on conflict (id) do nothing;

  select c.*
  into v_challenge
  from public.challenges c
  where c.invite_code = upper(btrim(p_code))
  limit 1;

  if not found then
    return;  -- code inconnu : résultat vide, l'app affiche « introuvable »
  end if;

  insert into public.challenge_members (challenge_id, user_id)
  values (v_challenge.id, v_uid)
  on conflict (challenge_id, user_id) do nothing;

  return next v_challenge;
end;
$$;

-- Seuls les utilisateurs authentifiés peuvent appeler la fonction.
revoke all on function public.join_challenge(text) from public;
revoke all on function public.join_challenge(text) from anon;
grant execute on function public.join_challenge(text) to authenticated;
