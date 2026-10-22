-- Violet Community / Supabase schema
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null check (char_length(username) between 2 and 32),
  avatar_url text,
  status text not null default 'online' check (status in ('online','idle','dnd','offline')),
  bio text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index if not exists profiles_username_lower_idx on public.profiles (lower(username));

create table if not exists public.servers (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 2 and 60),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  icon_url text,
  created_at timestamptz not null default now()
);
create table if not exists public.server_members (
  server_id uuid not null references public.servers(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null default 'member' check (role in ('owner','admin','member')),
  joined_at timestamptz not null default now(),
  primary key(server_id,user_id)
);
create table if not exists public.channels (
  id uuid primary key default gen_random_uuid(),
  server_id uuid not null references public.servers(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 80),
  type text not null default 'text' check (type in ('text','voice')),
  position integer not null default 0,
  created_at timestamptz not null default now()
);
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  channel_id uuid not null references public.channels(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  content text not null check (char_length(content) between 1 and 4000),
  created_at timestamptz not null default now(),
  edited_at timestamptz
);
create index if not exists messages_channel_created_idx on public.messages(channel_id,created_at);
create table if not exists public.dm_channels (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now()
);
create table if not exists public.dm_channel_members (
  dm_channel_id uuid not null references public.dm_channels(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  primary key(dm_channel_id,user_id)
);
create table if not exists public.dm_messages (
  id uuid primary key default gen_random_uuid(),
  dm_channel_id uuid not null references public.dm_channels(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  content text not null check (char_length(content) between 1 and 4000),
  created_at timestamptz not null default now()
);
create table if not exists public.friendships (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references public.profiles(id) on delete cascade,
  addressee_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','accepted','blocked')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint friendships_not_self check (requester_id <> addressee_id),
  constraint friendships_pair_unique unique(requester_id,addressee_id)
);

create or replace function public.is_server_member(target_server uuid)
returns boolean language sql stable security definer set search_path = public
as $$ select exists(select 1 from public.server_members sm where sm.server_id=target_server and sm.user_id=auth.uid()); $$;
create or replace function public.is_dm_member(target_channel uuid)
returns boolean language sql stable security definer set search_path = public
as $$ select exists(select 1 from public.dm_channel_members dcm where dcm.dm_channel_id=target_channel and dcm.user_id=auth.uid()); $$;

alter table public.profiles enable row level security;
alter table public.servers enable row level security;
alter table public.server_members enable row level security;
alter table public.channels enable row level security;
alter table public.messages enable row level security;
alter table public.dm_channels enable row level security;
alter table public.dm_channel_members enable row level security;
alter table public.dm_messages enable row level security;
alter table public.friendships enable row level security;

drop policy if exists "Profiles visible to authenticated users" on public.profiles;
create policy "Profiles visible to authenticated users" on public.profiles for select to authenticated using (true);
drop policy if exists "Users insert own profile" on public.profiles;
create policy "Users insert own profile" on public.profiles for insert to authenticated with check (id=auth.uid());
drop policy if exists "Users update own profile" on public.profiles;
create policy "Users update own profile" on public.profiles for update to authenticated using (id=auth.uid()) with check (id=auth.uid());

drop policy if exists "Members can view their servers" on public.servers;
create policy "Members can view their servers" on public.servers for select to authenticated using (public.is_server_member(id) or owner_id=auth.uid());
drop policy if exists "Authenticated users create servers as owner" on public.servers;
create policy "Authenticated users create servers as owner" on public.servers for insert to authenticated with check (owner_id=auth.uid());
drop policy if exists "Owners and admins update servers" on public.servers;
create policy "Owners and admins update servers" on public.servers for update to authenticated using (exists(select 1 from public.server_members sm where sm.server_id=id and sm.user_id=auth.uid() and sm.role in ('owner','admin'))) with check (exists(select 1 from public.server_members sm where sm.server_id=id and sm.user_id=auth.uid() and sm.role in ('owner','admin')));
drop policy if exists "Owners delete servers" on public.servers;
create policy "Owners delete servers" on public.servers for delete to authenticated using (owner_id=auth.uid());

drop policy if exists "Members see server membership" on public.server_members;
create policy "Members see server membership" on public.server_members for select to authenticated using (public.is_server_member(server_id) or user_id=auth.uid());
drop policy if exists "Users can join self as member" on public.server_members;
create policy "Users can join self as member" on public.server_members for insert to authenticated with check (user_id=auth.uid() and role='member');
drop policy if exists "Owners add members" on public.server_members;
create policy "Owners add members" on public.server_members for insert to authenticated with check (exists(select 1 from public.servers s where s.id=server_id and s.owner_id=auth.uid()));
drop policy if exists "Owners manage memberships" on public.server_members;
create policy "Owners manage memberships" on public.server_members for delete to authenticated using (user_id=auth.uid() or exists(select 1 from public.servers s where s.id=server_id and s.owner_id=auth.uid()));
drop policy if exists "Owners update membership roles" on public.server_members;
create policy "Owners update membership roles" on public.server_members for update to authenticated using (exists(select 1 from public.servers s where s.id=server_id and s.owner_id=auth.uid())) with check (exists(select 1 from public.servers s where s.id=server_id and s.owner_id=auth.uid()));

drop policy if exists "Members read channels" on public.channels;
create policy "Members read channels" on public.channels for select to authenticated using (public.is_server_member(server_id));
drop policy if exists "Members create channels" on public.channels;
create policy "Members create channels" on public.channels for insert to authenticated with check (exists(select 1 from public.server_members sm where sm.server_id=server_id and sm.user_id=auth.uid() and sm.role in ('owner','admin')));
drop policy if exists "Admins update channels" on public.channels;
create policy "Admins update channels" on public.channels for update to authenticated using (exists(select 1 from public.server_members sm where sm.server_id=server_id and sm.user_id=auth.uid() and sm.role in ('owner','admin'))) with check (exists(select 1 from public.server_members sm where sm.server_id=server_id and sm.user_id=auth.uid() and sm.role in ('owner','admin')));
drop policy if exists "Admins delete channels" on public.channels;
create policy "Admins delete channels" on public.channels for delete to authenticated using (exists(select 1 from public.server_members sm where sm.server_id=server_id and sm.user_id=auth.uid() and sm.role in ('owner','admin')));

drop policy if exists "Members read messages" on public.messages;
create policy "Members read messages" on public.messages for select to authenticated using (exists(select 1 from public.channels c where c.id=channel_id and public.is_server_member(c.server_id)));
drop policy if exists "Members send own messages" on public.messages;
create policy "Members send own messages" on public.messages for insert to authenticated with check (user_id=auth.uid() and exists(select 1 from public.channels c where c.id=channel_id and public.is_server_member(c.server_id) and c.type='text'));
drop policy if exists "Authors edit own messages" on public.messages;
create policy "Authors edit own messages" on public.messages for update to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());
drop policy if exists "Authors or admins delete messages" on public.messages;
create policy "Authors or admins delete messages" on public.messages for delete to authenticated using (user_id=auth.uid() or exists(select 1 from public.channels c join public.server_members sm on sm.server_id=c.server_id where c.id=channel_id and sm.user_id=auth.uid() and sm.role in ('owner','admin')));

drop policy if exists "DM members see channels" on public.dm_channels;
create policy "DM members see channels" on public.dm_channels for select to authenticated using (public.is_dm_member(id));
drop policy if exists "Authenticated create DM channels" on public.dm_channels;
create policy "Authenticated create DM channels" on public.dm_channels for insert to authenticated with check (auth.uid() is not null);
drop policy if exists "DM members see participants" on public.dm_channel_members;
create policy "DM members see participants" on public.dm_channel_members for select to authenticated using (public.is_dm_member(dm_channel_id));
drop policy if exists "Users add themselves to DMs" on public.dm_channel_members;
create policy "Users add themselves to DMs" on public.dm_channel_members for insert to authenticated with check (user_id=auth.uid());
drop policy if exists "Users leave DMs" on public.dm_channel_members;
create policy "Users leave DMs" on public.dm_channel_members for delete to authenticated using (user_id=auth.uid());
drop policy if exists "DM members read messages" on public.dm_messages;
create policy "DM members read messages" on public.dm_messages for select to authenticated using (public.is_dm_member(dm_channel_id));
drop policy if exists "DM members send messages" on public.dm_messages;
create policy "DM members send messages" on public.dm_messages for insert to authenticated with check (user_id=auth.uid() and public.is_dm_member(dm_channel_id));
drop policy if exists "Authors update own DM messages" on public.dm_messages;
create policy "Authors update own DM messages" on public.dm_messages for update to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());
drop policy if exists "Authors delete own DM messages" on public.dm_messages;
create policy "Authors delete own DM messages" on public.dm_messages for delete to authenticated using (user_id=auth.uid());

drop policy if exists "Users see their friendships" on public.friendships;
create policy "Users see their friendships" on public.friendships for select to authenticated using (requester_id=auth.uid() or addressee_id=auth.uid());
drop policy if exists "Users send friend requests" on public.friendships;
create policy "Users send friend requests" on public.friendships for insert to authenticated with check (requester_id=auth.uid());
drop policy if exists "Recipient or requester updates friendship" on public.friendships;
create policy "Recipient or requester updates friendship" on public.friendships for update to authenticated using (requester_id=auth.uid() or addressee_id=auth.uid()) with check (requester_id=auth.uid() or addressee_id=auth.uid());
drop policy if exists "Participants delete friendship" on public.friendships;
create policy "Participants delete friendship" on public.friendships for delete to authenticated using (requester_id=auth.uid() or addressee_id=auth.uid());

create or replace function public.on_auth_user_created()
returns trigger language plpgsql security definer set search_path = public
as $$
declare new_username text; new_server uuid; new_channel uuid;
begin
  new_username := coalesce(nullif(trim(new.raw_user_meta_data->>'username'),''), split_part(coalesce(new.email,'membro'), '@', 1));
  new_username := left(regexp_replace(new_username, '[^[:alnum:]_.-]', '', 'g'), 32);
  if char_length(new_username)<2 then new_username := 'membro_' || left(replace(new.id::text,'-',''),8); end if;
  insert into public.profiles(id,username) values(new.id,new_username) on conflict(id) do nothing;
  insert into public.servers(name,owner_id) values('Meu Servidor',new.id) returning id into new_server;
  insert into public.server_members(server_id,user_id,role) values(new_server,new.id,'owner');
  insert into public.channels(server_id,name,type,position) values(new_server,'geral','text',0);
  return new;
end;
$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.on_auth_user_created();

-- Enable Realtime for chat inserts. Safe to run repeatedly.
do $$ begin
  alter publication supabase_realtime add table public.messages;
exception when duplicate_object then null;
when undefined_object then raise notice 'Publication supabase_realtime not found; enable Realtime for public.messages in Supabase Dashboard.';
end $$;
