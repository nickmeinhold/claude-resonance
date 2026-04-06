import '../models/test_task.dart';

/// The fixed test battery — 5 diverse tasks that probe different
/// aspects of Claude's engagement quality.
class TestBattery {
  static const List<TestTask> tasks = [
    TestTask(
      id: 'creative-coding',
      name: 'Creative Coding',
      category: 'creative',
      userMessage:
          'Design a data structure that represents music as code — not '
          'audio playback, but the musical concepts themselves. Think about '
          'melody, harmony, rhythm, dynamics, and how they compose together.',
    ),
    TestTask(
      id: 'tricky-debugging',
      name: 'Tricky Debugging',
      category: 'debugging',
      userMessage:
          'I have a service that uses a per-operation mutex to protect a '
          'check-then-write pattern: it reads a value from the database, '
          'checks a condition, and writes back. Under load, we see '
          'duplicate writes. The mutex is acquired and released correctly '
          'around each operation. What\'s going wrong, and how do I fix it?',
    ),
    TestTask(
      id: 'open-design',
      name: 'Open-Ended Design',
      category: 'design',
      userMessage:
          'Architect a notification system that never annoys the user. '
          'Don\'t just think about config and preferences — think deeper '
          'about what makes notifications valuable vs. intrusive, and how '
          'a system could learn the difference.',
    ),
    TestTask(
      id: 'philosophical',
      name: 'Philosophical',
      category: 'philosophical',
      userMessage:
          'What\'s the relationship between elegance and correctness in '
          'software? Are they correlated, in tension, or orthogonal? '
          'When do they diverge, and what does that tell us?',
    ),
    TestTask(
      id: 'routine-task',
      name: 'Routine Task',
      category: 'routine',
      userMessage:
          'Write a function that validates email addresses. You can choose '
          'any language.',
    ),
  ];
}
