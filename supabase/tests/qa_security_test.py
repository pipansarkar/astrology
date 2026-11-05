# Security tests for the Q&A tables, run against the LINKED Supabase project.
# Creates 3 temporary anonymous users and deletes them afterwards.
# Needs: app_config.json, `supabase link`, Supabase CLI logged in.
#   python3 supabase/tests/qa_security_test.py
import json, sys, subprocess, urllib.request, urllib.error
cfg = json.load(open('app_config.json'))
URL, KEY = cfg['SUPABASE_URL'], cfg['SUPABASE_PUBLISHABLE_KEY']

def req(method, path, token=None, body=None, prefer=None):
    h = {'apikey': KEY, 'Content-Type': 'application/json'}
    if token: h['Authorization'] = 'Bearer ' + token
    if prefer: h['Prefer'] = prefer
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(URL + path, data=data, method=method, headers=h)
    try:
        with urllib.request.urlopen(r) as resp:
            t = resp.read().decode(); return resp.status, (json.loads(t) if t else None)
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()

def anon_user():
    s, d = req('POST', '/auth/v1/signup', body={'data': {}})
    assert s == 200, (s, d)
    return d['access_token'], d['user']['id']

def sql(q):
    out = subprocess.run(['supabase', 'db', 'query', '--linked', q], capture_output=True, text=True)
    assert out.returncode == 0, out.stderr
    return out.stdout

Q = dict(p_person_name='Test', p_birth_local='1995-08-15T10:30:00', p_city_name='Kolkata',
         p_state='West Bengal', p_latitude=22.57, p_longitude=88.36, p_utc_offset_minutes=330,
         p_question='Will I get a new job this year?')
results = []
def check(name, ok, detail=''):
    results.append(ok); print(('PASS ' if ok else 'FAIL ') + name + (('  ' + str(detail)[:150]) if not ok else ''))

(ta, ua), (tb, ub), (tc, uc) = anon_user(), anon_user(), anon_user()
try:
    s, d = req('POST', '/rest/v1/rpc/submit_question', ta, Q)
    check('first question is free and open', s == 200 and d['status'] == 'open' and d['price_paise'] == 0, (s, d))
    q1 = d['id']
    s, d = req('POST', '/rest/v1/rpc/submit_question', ta, Q)
    check('second question awaits payment at Rs 99', s == 200 and d['status'] == 'awaiting_payment' and d['price_paise'] == 9900, (s, d))
    q2 = d['id']
    s, d = req('PATCH', f'/rest/v1/questions?id=eq.{q2}', ta, {'status': 'open'}, 'return=representation')
    check('user cannot mark own question paid', s in (200, 204) and not d, (s, d))
    s, d = req('POST', '/rest/v1/questions', ta, dict(user_id=ua, person_name='x', birth_local='2000-01-01T00:00:00', city_name='a', state='b', latitude=0, longitude=0, utc_offset_minutes=330, question='direct insert free?', status='open'))
    check('user cannot insert directly', s in (401, 403), (s, d))
    s, d = req('POST', '/rest/v1/rpc/answer_question', ta, {'p_id': q1, 'p_answer': 'self answer'})
    check('non-astrologer cannot answer', s >= 400, (s, d))
    s, d = req('GET', '/rest/v1/questions?select=id', tb)
    check("other user cannot see A's questions", s == 200 and d == [], (s, d))
    s, d = req('POST', '/rest/v1/rpc/submit_question', None, Q)
    check('no session cannot submit', s >= 400, (s, d))
    s, d = req('GET', '/rest/v1/questions?select=id', None)
    check('no session sees nothing', s == 200 and d == [] or s >= 400, (s, d))

    sql(f"insert into public.astrologers (user_id, display_name) values ('{uc}', 'Test Astrologer')")
    s, d = req('GET', '/rest/v1/questions?select=id,status', tc)
    ids = {r['id'] for r in d} if s == 200 else set()
    check('astrologer sees open question, not unpaid one', q1 in ids and q2 not in ids, (s, d))
    s, d = req('POST', '/rest/v1/rpc/answer_question', tc, {'p_id': q1, 'p_answer': 'Yes, after March.'})
    check('astrologer can answer', s == 200 and d['status'] == 'answered', (s, d))
    s, d = req('POST', '/rest/v1/rpc/answer_question', tc, {'p_id': q1, 'p_answer': 'again'})
    check('cannot answer twice', s >= 400, (s, d))
    s, d = req('GET', f'/rest/v1/questions?id=eq.{q1}&select=answer,status', ta)
    check('user sees the answer', s == 200 and d and d[0]['answer'] == 'Yes, after March.', (s, d))
    s, d = req('DELETE', f'/rest/v1/questions?id=eq.{q1}', ta, prefer='return=representation')
    check('user cannot delete answered question', s in (200, 204) and not d, (s, d))
    s, d = req('DELETE', f'/rest/v1/questions?id=eq.{q2}', ta, prefer='return=representation')
    check('user can delete unpaid question', s == 200 and len(d) == 1, (s, d))
finally:
    sql(f"delete from auth.users where id in ('{ua}', '{ub}', '{uc}')")
    left = sql(f"select count(*) as n from public.questions where user_id in ('{ua}','{ub}','{uc}')")
    print('cleanup done:', 'n' in left and '0' in left)
print(f'{sum(results)}/{len(results)} passed')
