-- Store the country of the birth place (world cities are now supported).

alter table public.birth_profiles
  add column country text not null default 'India'
  check (char_length(country) between 1 and 100);

alter table public.questions
  add column country text not null default 'India'
  check (char_length(country) between 1 and 100);

drop function public.submit_question(text, timestamp, text, text, double precision, double precision, integer, text);

create function public.submit_question(
  p_person_name        text,
  p_birth_local        timestamp,
  p_city_name          text,
  p_state              text,
  p_latitude           double precision,
  p_longitude          double precision,
  p_utc_offset_minutes integer,
  p_question           text,
  p_country            text default 'India'
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
    latitude, longitude, utc_offset_minutes, question, status, price_paise,
    country
  ) values (
    uid, trim(p_person_name), p_birth_local, p_city_name, p_state,
    p_latitude, p_longitude, p_utc_offset_minutes, trim(p_question),
    (case when is_first then 'open' else 'awaiting_payment' end)::public.question_status,
    case when is_first then 0 else public.question_price_paise() end,
    coalesce(nullif(trim(p_country), ''), 'India')
  )
  returning * into result;

  return result;
end;
$$;

revoke execute on function public.submit_question(text, timestamp, text, text, double precision, double precision, integer, text, text) from public, anon;
grant execute on function public.submit_question(text, timestamp, text, text, double precision, double precision, integer, text, text) to authenticated;
