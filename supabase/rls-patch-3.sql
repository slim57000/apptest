-- ============================================================================
-- Correctif RLS : autorise la suppression d'un défi par son créateur
-- À exécuter UNE FOIS dans SQL Editor, après schema.sql, rls-patch.sql et
-- rls-patch-2.sql.
--
-- Aucune policy DELETE n'existait sur `challenges` : impossible de
-- supprimer un défi. Les lignes de challenge_members et
-- challenge_checkins correspondantes sont supprimées automatiquement
-- (ON DELETE CASCADE, voir schema.sql) une fois le défi supprimé.
-- ============================================================================

create policy "Le créateur peut supprimer son défi"
  on challenges for delete
  to authenticated
  using (created_by = auth.uid ());
