-- Push notifications through Firebase Cloud Messaging.
--
-- * The app registers its FCM token with register_device().
-- * Triggers call the `push` Edge Function (via pg_net) when a question
--   becomes open (notify astrologers) or answered (notify the user).
-- * pg_cron sends the daily horoscope reminder at 07:00 IST.
--
-- The function URL and shared secret live in Supabase Vault, not in git:
--   select vault.create_secret('https://<ref>.supabase.co/functions/v1/push', 'push_function_url');
--   select vault.create_secret('<random secret>', 'push_secret');
-- and the same secret is set on the function: supabase secrets set PUSH_SECRET=...

create extension if not exists pg_net with schema extensions;
create extension if not exists pg_cron;

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

-- ---------------------------------------------------------- device tokens

create table public.device_tokens (
  token      text primary key check (char_length(token) between 20 and 4096),
  user_id    uuid not null references auth.users (id) on delete cascade,
  platform   text not null default 'android',
  updated_at timestamptz not null default now()
);

create index device_tokens_user_idx on public.device_tokens (user_id);

-- No policies: clients use the functions below; the Edge Function uses the
-- service role.
alter table public.device_tokens enable row level security;

-- A token belongs to whoever is signed in on that device now.
create function public.register_device(p_token text, p_platform text default 'android')
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Not signed in';
  end if;
  insert into public.device_tokens (token, user_id, platform)
  values (p_token, auth.uid(), coalesce(p_platform, 'android'))
  on conflict (token) do update
    set user_id = excluded.user_id,
        platform = excluded.platform,
        updated_at = now();
end;
$$;

create function public.unregister_device(p_token text)
returns void
language sql
security definer
set search_path = ''
as $$
  delete from public.device_tokens
  where token = p_token and user_id = (select auth.uid());
$$;

revoke execute on function public.register_device(text, text) from public, anon;
revoke execute on function public.unregister_device(text) from public, anon;
grant execute on function public.register_device(text, text) to authenticated;
grant execute on function public.unregister_device(text) to authenticated;

-- ------------------------------------------------------------ dispatching

create function private.send_push(payload jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  fn_url text;
  secret text;
begin
  select decrypted_secret into fn_url
    from vault.decrypted_secrets where name = 'push_function_url';
  select decrypted_secret into secret
    from vault.decrypted_secrets where name = 'push_secret';
  if fn_url is null or secret is null then
    return; -- push not configured yet
  end if;
  perform net.http_post(
    url := fn_url,
    body := payload,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-push-secret', secret
    )
  );
end;
$$;

revoke execute on function private.send_push(jsonb) from public, anon, authenticated;

create function private.questions_push()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status = 'open'
     and (tg_op = 'INSERT' or old.status is distinct from 'open') then
    perform private.send_push(
      jsonb_build_object('type', 'question_open', 'question_id', new.id));
  elsif tg_op = 'UPDATE' and new.status = 'answered'
        and old.status is distinct from 'answered' then
    perform private.send_push(
      jsonb_build_object('type', 'question_answered', 'question_id', new.id));
  end if;
  return null;
end;
$$;

create trigger questions_push
  after insert or update of status on public.questions
  for each row execute function private.questions_push();

-- 01:30 UTC = 07:00 IST
select cron.schedule(
  'daily-horoscope-push',
  '30 1 * * *',
  $$select private.send_push('{"type": "daily_horoscope"}'::jsonb)$$
);
