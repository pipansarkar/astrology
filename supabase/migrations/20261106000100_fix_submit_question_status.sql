-- Cast the CASE result to the enum type.

create or replace function public.submit_question(
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
    (case when is_first then 'open' else 'awaiting_payment' end)::public.question_status,
    case when is_first then 0 else public.question_price_paise() end
  )
  returning * into result;

  return result;
end;
$$;
