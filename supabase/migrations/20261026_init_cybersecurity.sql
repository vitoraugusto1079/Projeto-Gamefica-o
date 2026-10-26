-- =============================================================================
-- PHP Defense — Migrations do Banco de Dados PostgreSQL & Supabase
-- =============================================================================
-- IMPORTANTE:
-- As verificações e cálculos abaixo garantem consistência transacional e
-- pontuação idempotente, mas não substituem uma simulação autoritativa no
-- servidor (em protótipos de jogos offline em Flutter, as entradas de física
-- e tiro rodam no cliente). Nunca exponha a chave service_role no aplicativo.
-- =============================================================================

-- 1. TABELA: profiles (perfis de jogadores)
create table if not exists public.profiles (
  id uuid references auth.users(id) on delete cascade primary key,
  nickname text unique not null check (char_length(trim(nickname)) between 3 and 20),
  matches_played int not null default 0,
  wins int not null default 0,
  best_score int not null default 0,
  best_wave int not null default 0,
  total_kills int not null default 0,
  best_tower_kinds int not null default 0,
  max_tower_level int not null default 0,
  bosses_defeated int not null default 0,
  flawless_wins int not null default 0,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. TABELA: matches (partidas registradas)
create table if not exists public.matches (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  map_id text not null,
  victory boolean,
  waves_completed int,
  kills int,
  integrity int,
  score int,
  tower_kinds int,
  max_tower_level int,
  boss_defeated boolean,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  finished_at timestamp with time zone
);

-- 3. TABELA: achievements (definições de conquistas)
create table if not exists public.achievements (
  id text primary key,
  title text not null,
  description text not null,
  target int not null
);

-- 4. TABELA: user_achievements (conquistas conquistadas pelos usuários)
create table if not exists public.user_achievements (
  user_id uuid references public.profiles(id) on delete cascade not null,
  achievement_id text references public.achievements(id) on delete cascade not null,
  unlocked_at timestamp with time zone default timezone('utc'::text, now()) not null,
  primary key (user_id, achievement_id)
);

-- Inserção das 6 conquistas iniciais do jogo
insert into public.achievements (id, title, description, target) values
  ('first_block', 'Primeiro bloqueio', 'Elimine o primeiro inimigo.', 1),
  ('server_protected', 'Servidor protegido', 'Vença uma partida.', 1),
  ('flawless_defense', 'Defesa impecável', 'Vença com 100 de integridade.', 1),
  ('security_specialist', 'Especialista em segurança', 'Construa os cinco tipos de torre em uma mesma partida.', 5),
  ('threat_hunter', 'Caçador de ameaças', 'Derrote o chefe HYDRA AI.', 1),
  ('max_defense', 'Defesa máxima', 'Melhore uma torre até o nível 3.', 3)
on conflict (id) do update set
  title = excluded.title,
  description = excluded.description,
  target = excluded.target;

-- =============================================================================
-- SEGURANÇA E POLÍTICAS DE RLS (Row Level Security)
-- =============================================================================

alter table public.profiles enable row level security;
alter table public.matches enable row level security;
alter table public.achievements enable row level security;
alter table public.user_achievements enable row level security;

-- Profiles: leitura pública (necessária para exibir o ranking global);
-- atualização restrita ao próprio usuário autenticado.
drop policy if exists "Perfis são visíveis publicamente" on public.profiles;
create policy "Perfis são visíveis publicamente" on public.profiles
  for select using (true);

drop policy if exists "Usuários podem atualizar o próprio perfil" on public.profiles;
create policy "Usuários podem atualizar o próprio perfil" on public.profiles
  for update using (auth.uid() = id);

-- Matches: usuários só visualizam suas próprias partidas;
-- nenhuma atualização direta via client é permitida (feita apenas pela função RPC).
drop policy if exists "Usuários visualizam apenas suas partidas" on public.matches;
create policy "Usuários visualizam apenas suas partidas" on public.matches
  for select using (auth.uid() = user_id);

-- Achievements: leitura pública das definições.
drop policy if exists "Conquistas são visíveis publicamente" on public.achievements;
create policy "Conquistas são visíveis publicamente" on public.achievements
  for select using (true);

-- User Achievements: visualização pública de conquistas desbloqueadas.
drop policy if exists "Conquistas de usuários são visíveis" on public.user_achievements;
create policy "Conquistas de usuários são visíveis" on public.user_achievements
  for select using (true);

-- =============================================================================
-- TRIGGER: Criação automática de perfil ao cadastrar novo usuário
-- =============================================================================

create or replace function public.handle_new_user()
returns trigger as $$
declare
  raw_nick text;
  final_nick text;
begin
  raw_nick := coalesce(new.raw_user_meta_data->>'nickname', split_part(new.email, '@', 1));
  -- Garante tamanho válido
  final_nick := substring(trim(raw_nick) from 1 for 20);
  if char_length(final_nick) < 3 then
    final_nick := 'Defensor_' || substring(new.id::text from 1 for 6);
  end if;

  -- Resolve conflito de apelidos adicionando sufixo se necessário
  while exists (select 1 from public.profiles where nickname = final_nick) loop
    final_nick := substring(final_nick from 1 for 14) || '_' || floor(random() * 9000 + 1000)::text;
  end loop;

  insert into public.profiles (id, nickname)
  values (new.id, final_nick);

  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- =============================================================================
-- FUNÇÃO RPC: start_match (registra o início da partida)
-- =============================================================================

create or replace function public.start_match(p_map_id text)
returns uuid as $$
declare
  v_match_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Autenticação necessária para iniciar partida.';
  end if;

  insert into public.matches (user_id, map_id)
  values (auth.uid(), p_map_id)
  returning id into v_match_id;

  return v_match_id;
end;
$$ language plpgsql security definer;

-- =============================================================================
-- FUNÇÃO RPC: finish_match (transacional, calcula pontuação e concede conquistas)
-- =============================================================================

create or replace function public.finish_match(
  p_match_id uuid,
  p_victory boolean,
  p_waves_completed int,
  p_kills int,
  p_integrity int,
  p_tower_kinds int,
  p_max_tower_level int,
  p_boss_defeated boolean
)
returns json as $$
declare
  v_user_id uuid;
  v_already_finished boolean;
  v_calculated_score int;
  v_new_achievements text[] := array[]::text[];
  v_p record;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Autenticação necessária.';
  end if;

  -- 1. Verifica a partida
  select finished_at is not null, score into v_already_finished, v_calculated_score
  from public.matches
  where id = p_match_id and user_id = v_user_id;

  if not found then
    raise exception 'Partida não encontrada para este usuário.';
  end if;

  if v_already_finished then
    return json_build_object(
      'already_finished', true,
      'score', v_calculated_score,
      'new_achievements', array_to_json(v_new_achievements)
    );
  end if;

  -- 2. Cálculo estrito de pontuação no servidor:
  --    pontos = ondas × 1000 + abates × 10 + integridade × 25 + (vitória ? 5000 : 0)
  v_calculated_score := (greatest(0, p_waves_completed) * 1000)
                      + (greatest(0, p_kills) * 10)
                      + (greatest(0, least(100, p_integrity)) * 25)
                      + (case when p_victory then 5000 else 0 end);

  -- 3. Atualiza o registro da partida
  update public.matches
  set
    victory = p_victory,
    waves_completed = p_waves_completed,
    kills = p_kills,
    integrity = p_integrity,
    score = v_calculated_score,
    tower_kinds = p_tower_kinds,
    max_tower_level = p_max_tower_level,
    boss_defeated = p_boss_defeated,
    finished_at = timezone('utc'::text, now())
  where id = p_match_id;

  -- 4. Atualiza os dados agregados do perfil do jogador
  update public.profiles
  set
    matches_played = matches_played + 1,
    wins = wins + (case when p_victory then 1 else 0 end),
    best_score = greatest(best_score, v_calculated_score),
    best_wave = greatest(best_wave, p_waves_completed),
    total_kills = total_kills + greatest(0, p_kills),
    best_tower_kinds = greatest(best_tower_kinds, p_tower_kinds),
    max_tower_level = greatest(max_tower_level, p_max_tower_level),
    bosses_defeated = bosses_defeated + (case when p_boss_defeated then 1 else 0 end),
    flawless_wins = flawless_wins + (case when p_victory and p_integrity >= 100 then 1 else 0 end),
    updated_at = timezone('utc'::text, now())
  where id = v_user_id
  returning * into v_p;

  -- 5. Avaliação e concessão de conquistas
  -- Conquista 1: Primeiro bloqueio
  if v_p.total_kills >= 1 and not exists (select 1 from public.user_achievements where user_id = v_user_id and achievement_id = 'first_block') then
    insert into public.user_achievements (user_id, achievement_id) values (v_user_id, 'first_block');
    v_new_achievements := array_append(v_new_achievements, 'first_block');
  end if;

  -- Conquista 2: Servidor protegido
  if v_p.wins >= 1 and not exists (select 1 from public.user_achievements where user_id = v_user_id and achievement_id = 'server_protected') then
    insert into public.user_achievements (user_id, achievement_id) values (v_user_id, 'server_protected');
    v_new_achievements := array_append(v_new_achievements, 'server_protected');
  end if;

  -- Conquista 3: Defesa impecável (100 HP)
  if v_p.flawless_wins >= 1 and not exists (select 1 from public.user_achievements where user_id = v_user_id and achievement_id = 'flawless_defense') then
    insert into public.user_achievements (user_id, achievement_id) values (v_user_id, 'flawless_defense');
    v_new_achievements := array_append(v_new_achievements, 'flawless_defense');
  end if;

  -- Conquista 4: Especialista em segurança (5 torres na mesma partida)
  if v_p.best_tower_kinds >= 5 and not exists (select 1 from public.user_achievements where user_id = v_user_id and achievement_id = 'security_specialist') then
    insert into public.user_achievements (user_id, achievement_id) values (v_user_id, 'security_specialist');
    v_new_achievements := array_append(v_new_achievements, 'security_specialist');
  end if;

  -- Conquista 5: Caçador de ameaças (chefe HYDRA AI derrotado)
  if v_p.bosses_defeated >= 1 and not exists (select 1 from public.user_achievements where user_id = v_user_id and achievement_id = 'threat_hunter') then
    insert into public.user_achievements (user_id, achievement_id) values (v_user_id, 'threat_hunter');
    v_new_achievements := array_append(v_new_achievements, 'threat_hunter');
  end if;

  -- Conquista 6: Defesa máxima (torre nível 3)
  if v_p.max_tower_level >= 3 and not exists (select 1 from public.user_achievements where user_id = v_user_id and achievement_id = 'max_defense') then
    insert into public.user_achievements (user_id, achievement_id) values (v_user_id, 'max_defense');
    v_new_achievements := array_append(v_new_achievements, 'max_defense');
  end if;

  return json_build_object(
    'already_finished', false,
    'score', v_calculated_score,
    'new_achievements', array_to_json(v_new_achievements)
  );
end;
$$ language plpgsql security definer;

-- =============================================================================
-- FUNÇÃO RPC: get_leaderboard (ranking público sem e-mail)
-- =============================================================================

create or replace function public.get_leaderboard(p_limit int default 50)
returns table (
  rank bigint,
  nickname text,
  best_score int,
  wins int,
  best_wave int,
  is_me boolean
) as $$
begin
  return query
  select
    row_number() over (order by p.best_score desc, p.wins desc, p.best_wave desc) as rank,
    p.nickname,
    p.best_score,
    p.wins,
    p.best_wave,
    (auth.uid() is not null and p.id = auth.uid()) as is_me
  from public.profiles p
  where p.matches_played > 0 or p.best_score > 0
  order by p.best_score desc, p.wins desc, p.best_wave desc
  limit least(greatest(1, p_limit), 100);
end;
$$ language plpgsql security definer;
