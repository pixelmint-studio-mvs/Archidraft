class Lesson {
  final String id;
  final String moduleId;
  final String title;
  final String content;
  final int lessonOrder;
  final String? estimatedDuration;
  final String status;

  const Lesson({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.content,
    required this.lessonOrder,
    this.estimatedDuration,
    this.status = 'NOT_STARTED',
  });

  factory Lesson.fromMap(Map<String, dynamic> data) {
    return Lesson(
      id: data['id'] as String? ?? '',
      moduleId: data['module_id'] as String? ?? '',
      title: data['title'] as String? ?? 'Untitled',
      content: data['content'] as String? ?? '',
      lessonOrder: data['lesson_order'] as int? ?? 0,
      estimatedDuration: data['estimated_duration'] as String?,
      status: data['status'] as String? ?? 'NOT_STARTED',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'module_id': moduleId,
      'title': title,
      'content': content,
      'lesson_order': lessonOrder,
      'estimated_duration': estimatedDuration,
      'status': status,
    };
  }
}
