-- Astrologer invites: when an invited email gets an account (new sign-up
-- or a guest account upgraded to email), it becomes an astrologer
-- automatically.
--
-- Invite someone (SQL editor; keep emails out of git):
--   insert into public.astrologer_invites (email, display_name)
--   values ('someone@example.com', 'Their Name');

create table public.astrologer_invites (
  email        text primary key check (email = lower(email)),
  display_name text not null,
  created_at   timestamptz not null default now()
);

-- No policies: only the dashboard / service role can read or change it.
alter table public.astrologer_invites enable row level security;

create function private.grant_invited_astrologer()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.email is not null then
    insert into public.astrologers (user_id, display_name)
    select new.id, i.display_name
      from public.astrologer_invites i
     where i.email = lower(new.email)
    on conflict (user_id) do nothing;
  end if;
  return new;
end;
$$;

revoke execute on function private.grant_invited_astrologer() from public, anon, authenticated;

create trigger grant_invited_astrologer
  after insert or update of email on auth.users
  for each row execute function private.grant_invited_astrologer();

-- An invite added after the person already signed up applies immediately.
create function private.apply_astrologer_invite()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.astrologers (user_id, display_name)
  select u.id, new.display_name
    from auth.users u
   where lower(u.email) = new.email
  on conflict (user_id) do nothing;
  return new;
end;
$$;

revoke execute on function private.apply_astrologer_invite() from public, anon, authenticated;

create trigger apply_astrologer_invite
  after insert on public.astrologer_invites
  for each row execute function private.apply_astrologer_invite();
