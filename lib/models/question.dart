import '../data/cities.dart';
import 'birth_details.dart';

enum QuestionStatus { awaitingPayment, open, answered, refunded }

QuestionStatus _status(String s) => switch (s) {
  'awaiting_payment' => QuestionStatus.awaitingPayment,
  'open' => QuestionStatus.open,
  'answered' => QuestionStatus.answered,
  'refunded' => QuestionStatus.refunded,
  _ => throw FormatException('Unknown status $s'),
};

class Question {
  Question({
    required this.id,
    required this.details,
    required this.question,
    required this.status,
    required this.pricePaise,
    required this.answer,
    required this.answeredAt,
    required this.createdAt,
  });

  final String id;

  /// Snapshot of the birth details the question was asked about.
  final BirthDetails details;
  final String question;
  final QuestionStatus status;
  final int pricePaise;
  final String? answer;
  final DateTime? answeredAt;
  final DateTime createdAt;

  factory Question.fromRow(Map<String, dynamic> r) => Question(
    id: r['id'] as String,
    details: BirthDetails(
      name: r['person_name'] as String,
      localDateTime: DateTime.parse(r['birth_local'] as String),
      city: City(
        r['city_name'] as String,
        r['state'] as String,
        (r['latitude'] as num).toDouble(),
        (r['longitude'] as num).toDouble(),
        country: (r['country'] as String?) ?? 'India',
        utcOffsetMinutes: r['utc_offset_minutes'] as int,
      ),
    ),
    question: r['question'] as String,
    status: _status(r['status'] as String),
    pricePaise: r['price_paise'] as int,
    answer: r['answer'] as String?,
    answeredAt: r['answered_at'] == null
        ? null
        : DateTime.parse(r['answered_at'] as String),
    createdAt: DateTime.parse(r['created_at'] as String),
  );
}
