import '../models/birth_details.dart';
import '../models/question.dart';
import 'supabase_config.dart';

/// Q&A data access. Security lives in the database
/// (supabase/migrations/20261106000000_questions.sql): users can only read
/// their own questions, and status changes happen in server functions.
class QuestionRepository {
  static const _table = 'questions';

  Future<List<Question>> myQuestions() async {
    final user = await requireSession();
    final rows = await supabase
        .from(_table)
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    return rows.map(Question.fromRow).toList();
  }

  /// True when the user's next question is the free one.
  Future<bool> nextQuestionIsFree() async {
    final user = await requireSession();
    final rows = await supabase
        .from(_table)
        .select('id')
        .eq('user_id', user.id)
        .limit(1);
    return rows.isEmpty;
  }

  Future<Question> submit(BirthDetails d, String question) async {
    await requireSession();
    final row = await supabase.rpc(
      'submit_question',
      params: {
        'p_person_name': d.name,
        'p_birth_local': d.localDateTime.toIso8601String(),
        'p_city_name': d.city.name,
        'p_state': d.city.state,
        'p_latitude': d.city.latitude,
        'p_longitude': d.city.longitude,
        'p_utc_offset_minutes': d.city.utcOffsetMinutes,
        'p_question': question,
      },
    );
    return Question.fromRow(row as Map<String, dynamic>);
  }

  Future<void> deleteUnpaid(String id) =>
      supabase.from(_table).delete().eq('id', id);

  // ------------------------------------------------------------ astrologer

  Future<bool> isAstrologer() async {
    if (currentUser == null || currentUser!.isAnonymous) return false;
    final result = await supabase.rpc('is_astrologer');
    return result == true;
  }

  /// Open questions, oldest first (answer in order).
  Future<List<Question>> openQuestions() async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('status', 'open')
        .order('created_at');
    return rows.map(Question.fromRow).toList();
  }

  Future<List<Question>> answeredByMe() async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('answered_by', currentUser!.id)
        .order('answered_at', ascending: false)
        .limit(50);
    return rows.map(Question.fromRow).toList();
  }

  Future<void> answer(String id, String answer) =>
      supabase.rpc('answer_question', params: {'p_id': id, 'p_answer': answer});
}
