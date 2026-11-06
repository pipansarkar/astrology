-- Trust features: public astrologer profiles and user ratings of answers.

alter table public.astrologers
  add column bio text not null default ''
    check (char_length(bio) <= 1000),
  add column languages text not null default 'Bengali, Hindi, English'
    check (char_length(languages) <= 200),
  add column experience_years smallint
    check (experience_years between 0 and 80);

alter table public.questions
  add column rating smallint check (rating between 1 and 5),
  add column feedback text check (feedback is null or char_length(feedback) <= 500),
  add column rated_at timestamptz;

-- Public profile card: no user ids or emails are exposed.
create function public.list_astrologers()
returns table (
  display_name     text,
  bio              text,
  languages        text,
  experience_years smallint,
  answered         bigint,
  rating_avg       numeric,
  rating_count     bigint
)
language sql
stable
security definer
set search_path = ''
as $$
  select a.display_name, a.bio, a.languages, a.experience_years,
         count(q.id) filter (where q.status = 'answered'),
         round(avg(q.rating), 1),
         count(q.rating)
    from public.astrologers a
    left join public.questions q on q.answered_by = a.user_id
   where a.active
   group by a.user_id
   order by count(q.id) desc;
$$;

create function public.update_my_astrologer_profile(
  p_display_name     text,
  p_bio              text,
  p_languages        text,
  p_experience_years smallint
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.astrologers
     set display_name = trim(p_display_name),
         bio = trim(coalesce(p_bio, '')),
         languages = trim(coalesce(p_languages, '')),
         experience_years = p_experience_years
   where user_id = auth.uid();
  if not found then
    raise exception 'Not an astrologer';
  end if;
end;
$$;

-- A user rates their own answered question, once.
create function public.rate_question(p_id uuid, p_rating smallint, p_feedback text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.questions
     set rating = p_rating,
         feedback = nullif(trim(coalesce(p_feedback, '')), ''),
         rated_at = now()
   where id = p_id
     and user_id = auth.uid()
     and status = 'answered'
     and rating is null;
  if not found then
    raise exception 'Cannot rate this question';
  end if;
end;
$$;

revoke execute on function public.list_astrologers() from public;
grant execute on function public.list_astrologers() to anon, authenticated;
revoke execute on function public.update_my_astrologer_profile(text, text, text, smallint) from public, anon;
grant execute on function public.update_my_astrologer_profile(text, text, text, smallint) to authenticated;
revoke execute on function public.rate_question(uuid, smallint, text) from public, anon;
grant execute on function public.rate_question(uuid, smallint, text) to authenticated;
