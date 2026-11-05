-- "Ask an Astrologer": users submit questions with a birth-chart snapshot,
-- astrologers answer them.
--
-- Writes go only through the security-definer functions below, so clients
-- cannot mark a question as paid or answered by themselves.

-- ------------------------------------------------------------ astrologers

create table public.astrologers (
  user_id      uuid primary key references auth.users (id) on delete cascade,
  display_name text not null,
  active       boolean not null default true,
  created_at   timestamptz not null default now()
);

alter table public.astrologers enable row level security;

create policy "Astrologers read own row"
  on public.astrologers for select
  to authenticated
  using ((select auth.uid()) = user_id);

create function public.is_astrologer()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.astrologers
    where user_id = (select auth.uid()) and active
  );
$$;

-- -------------------------------------------------------------- questions

create type public.question_status as enum
  ('awaiting_payment', 'open', 'answered', 'refunded');

create table public.questions (
  id                 uuid primary key default gen_random_uuid(),
  user_id            uuid not null references auth.users (id) on delete cascade,

  -- Snapshot of the birth details, so the question survives profile edits.
  person_name        text not null check (char_length(person_name) between 1 and 100),
  birth_local        timestamp not null,
  city_name          text not null,
  state              text not null,
  latitude           double precision not null check (latitude between -90 and 90),
  longitude          double precision not null check (longitude between -180 and 180),
  utc_offset_minutes integer not null,

  question           text not null check (char_length(question) between 10 and 1000),
  status             public.question_status not null default 'awaiting_payment',
  price_paise        integer not null default 0 check (price_paise >= 0),
  payment_ref        text,

  answer             text check (answer is null or char_length(answer) between 1 and 5000),
  answered_by        uuid references auth.users (id) on delete set null,
  answered_at        timestamptz,
  created_at         timestamptz not null default now()
);

create index questions_user_idx on public.questions (user_id, created_at desc);
create index questions_status_idx on public.questions (status, created_at);

alter table public.questions enable row level security;

create policy "Users read own questions"
  on public.questions for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "Astrologers read paid questions"
  on public.questions for select
  to authenticated
  using (status in ('open', 'answered') and (select public.is_astrologer()));

create policy "Users delete own unpaid questions"
  on public.questions for delete
  to authenticated
  using ((select auth.uid()) = user_id and status = 'awaiting_payment');

-- ------------------------------------------------------------- functions

-- Price of a paid question, in paise (₹99). Change here and re-deploy.
create function public.question_price_paise()
returns integer
language sql
immutable
as $$ select 9900 $$;

-- A user's first question is free and goes straight to the astrologer.
-- Later questions wait for payment (confirmed server-side, never by the app).
create function public.submit_question(
  p_person_name        text,
  p_birth_local        timestamp,
  p_city_name          text,
  p_state              text,
  p_latitude           double precision,
  p_longitude          double precision,
  p_utc_offset_minutes integer,
  p_question           text
)
returns public.questions
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid      uuid := auth.uid();
  is_first boolean;
  result   public.questions;
begin
  if uid is null then
    raise exception 'Not signed in';
  end if;

  -- Serialise per user so two simultaneous "first" questions can't both be free.
  perform pg_advisory_xact_lock(hashtext(uid::text));
  select not exists (select 1 from public.questions where user_id = uid)
    into is_first;

  insert into public.questions (
    user_id, person_name, birth_local, city_name, state,
    latitude, longitude, utc_offset_minutes, question, status, price_paise
  ) values (
    uid, trim(p_person_name), p_birth_local, p_city_name, p_state,
    p_latitude, p_longitude, p_utc_offset_minutes, trim(p_question),
    case when is_first then 'open' else 'awaiting_payment' end,
    case when is_first then 0 else public.question_price_paise() end
  )
  returning * into result;

  return result;
end;
$$;

create function public.answer_question(p_id uuid, p_answer text)
returns public.questions
language plpgsql
security definer
set search_path = ''
as $$
declare
  result public.questions;
begin
  if not public.is_astrologer() then
    raise exception 'Only astrologers can answer questions';
  end if;

  update public.questions
     set answer = trim(p_answer),
         answered_by = auth.uid(),
         answered_at = now(),
         status = 'answered'
   where id = p_id and status = 'open'
  returning * into result;

  if result.id is null then
    raise exception 'Question is not open';
  end if;
  return result;
end;
$$;

revoke execute on function public.is_astrologer() from public, anon;
revoke execute on function public.submit_question(text, timestamp, text, text, double precision, double precision, integer, text) from public, anon;
revoke execute on function public.answer_question(uuid, text) from public, anon;
grant execute on function public.is_astrologer() to authenticated;
grant execute on function public.submit_question(text, timestamp, text, text, double precision, double precision, integer, text) to authenticated;
grant execute on function public.answer_question(uuid, text) to authenticated;
