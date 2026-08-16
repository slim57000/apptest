-- Schéma Supabase pour les défis entre amis d'Habitude+.
-- À exécuter dans l'éditeur SQL du projet Supabase (Dashboard > SQL Editor).
-- Voir le README ("Configurer les défis entre amis") pour la procédure
-- complète, y compris l'activation de l'authentification anonyme.

-- --- Profils utilisateurs -----------------------------------------------
-- Un profil par utilisateur authentifié (anonyme), juste un pseudo affiché
-- aux autres membres d'un défi commun.
create table if not exists profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 40),
  created_at timestamptz not null default now()
);

alter table profiles enable row level security;

create policy "Les profils sont lisibles par tout utilisateur connecté"
  on profiles for select
  to authenticated
  using (true);

create policy "Un utilisateur ne peut créer/modifier que son propre profil"
  on profiles for insert
  to authenticated
  with check (auth.uid () = id);

create policy "Un utilisateur ne peut mettre à jour que son propre profil"
  on profiles for update
  to authenticated
  using (auth.uid () = id);

-- --- Défis -----------------------------------------------------------
create table if not exists challenges (
  id uuid primary key default gen_random_uuid (),
  name text not null check (char_length(name) between 1 and 60),
  emoji text not null default '🔥',
  invite_code text not null unique,
  created_by uuid not null references profiles (id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table challenges enable row level security;

-- Lecture ouverte à tout utilisateur connecté : nécessaire pour retrouver
-- un défi par son code d'invitation avant même d'en être membre. Le nom
-- d'un défi n'est pas une donnée sensible.
create policy "Les défis sont lisibles par tout utilisateur connecté"
  on challenges for select
  to authenticated
  using (true);

create policy "Un utilisateur connecté peut créer un défi"
  on challenges for insert
  to authenticated
  with check (auth.uid () = created_by);

-- --- Membres d'un défi ---------------------------------------------------
create table if not exists challenge_members (
  challenge_id uuid not null references challenges (id) on delete cascade,
  user_id uuid not null references profiles (id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (challenge_id, user_id)
);

alter table challenge_members enable row level security;

create policy "Les membres d'un défi sont visibles par les autres membres"
  on challenge_members for select
  to authenticated
  using (
    exists (
      select 1
      from challenge_members m
      where m.challenge_id = challenge_members.challenge_id
        and m.user_id = auth.uid ()
    )
  );

create policy "Un utilisateur peut rejoindre un défi en son nom propre"
  on challenge_members for insert
  to authenticated
  with check (auth.uid () = user_id);

-- --- Check-ins quotidiens ------------------------------------------------
-- Un "j'ai réussi aujourd'hui" par membre et par jour pour un défi donné.
create table if not exists challenge_checkins (
  challenge_id uuid not null references challenges (id) on delete cascade,
  user_id uuid not null references profiles (id) on delete cascade,
  day date not null,
  created_at timestamptz not null default now(),
  primary key (challenge_id, user_id, day)
);

alter table challenge_checkins enable row level security;

create policy "Les check-ins d'un défi sont visibles par les membres du défi"
  on challenge_checkins for select
  to authenticated
  using (
    exists (
      select 1
      from challenge_members m
      where m.challenge_id = challenge_checkins.challenge_id
        and m.user_id = auth.uid ()
    )
  );

create policy "Un membre peut cocher son propre check-in du jour"
  on challenge_checkins for insert
  to authenticated
  with check (
    auth.uid () = user_id
    and exists (
      select 1
      from challenge_members m
      where m.challenge_id = challenge_checkins.challenge_id
        and m.user_id = auth.uid ()
    )
  );
