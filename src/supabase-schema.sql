-- ============================================================
-- PROFILIA v3 — Schéma Supabase complet
-- ============================================================

create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  name text not null,
  profile_type text not null default 'Étudiant',
  is_admin boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.conversations (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  title text not null default 'Nouvelle conversation',
  message_count integer default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.messages (
  id uuid default gen_random_uuid() primary key,
  conversation_id uuid references public.conversations(id) on delete cascade not null,
  role text not null check (role in ('user', 'assistant')),
  content text not null,
  created_at timestamptz default now()
);

-- Index
create index if not exists idx_conversations_user_id on public.conversations(user_id);
create index if not exists idx_conversations_updated_at on public.conversations(updated_at desc);
create index if not exists idx_messages_conversation_id on public.messages(conversation_id);
create index if not exists idx_messages_created_at on public.messages(created_at);

-- RLS
alter table public.profiles enable row level security;
alter table public.conversations enable row level security;
alter table public.messages enable row level security;

create policy "profiles_select" on public.profiles for select using (auth.uid() = id);
create policy "profiles_insert" on public.profiles for insert with check (auth.uid() = id);
create policy "profiles_update" on public.profiles for update using (auth.uid() = id);
create policy "profiles_delete" on public.profiles for delete using (auth.uid() = id);

create policy "conversations_select" on public.conversations for select using (auth.uid() = user_id);
create policy "conversations_insert" on public.conversations for insert with check (auth.uid() = user_id);
create policy "conversations_update" on public.conversations for update using (auth.uid() = user_id);
create policy "conversations_delete" on public.conversations for delete using (auth.uid() = user_id);

create policy "messages_select" on public.messages for select using (
  auth.uid() = (select user_id from public.conversations where id = conversation_id)
);
create policy "messages_insert" on public.messages for insert with check (
  auth.uid() = (select user_id from public.conversations where id = conversation_id)
);

-- Trigger: créer profil à l'inscription
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, name, profile_type)
  values (new.id, coalesce(new.raw_user_meta_data->>'name', 'Utilisateur'), coalesce(new.raw_user_meta_data->>'profile_type', 'Étudiant'));
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Trigger: updated_at
create or replace function public.set_updated_at()
returns trigger as $$ begin new.updated_at = now(); return new; end; $$ language plpgsql;

create trigger set_profiles_updated_at before update on public.profiles for each row execute procedure public.set_updated_at();
create trigger set_conversations_updated_at before update on public.conversations for each row execute procedure public.set_updated_at();

-- Trigger: compter les messages
create or replace function public.increment_message_count()
returns trigger as $$
begin
  update public.conversations set message_count = message_count + 1, updated_at = now() where id = new.conversation_id;
  return new;
end;
$$ language plpgsql security definer;

create trigger on_message_created after insert on public.messages for each row execute procedure public.increment_message_count();
