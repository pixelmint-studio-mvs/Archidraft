class Lesson {
  final String id;
  final String moduleId;
  final String title;
  final String content;
  final int lessonOrder;
  final String? estimatedDuration;
  final String status;
  final String? certificateId;
  final String? verificationToken;
  final String? certificateObjectKey;

  const Lesson({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.content,
    required this.lessonOrder,
    this.estimatedDuration,
    this.status = 'NOT_STARTED',
    this.certificateId,
    this.verificationToken,
    this.certificateObjectKey,
  });

  bool get isCompleted => status == 'COMPLETED';
  bool get hasCertificate => certificateId != null && certificateId!.isNotEmpty;
  String get publicVerificationUrl => 'https://www.draughtsmanstudio.com/verify?id=${certificateId ?? ''}${verificationToken != null ? '&token=$verificationToken' : ''}';

  factory Lesson.fromMap(Map<String, dynamic> data) {
    return Lesson(
      id: data['id'] as String? ?? '',
      moduleId: data['module_id'] as String? ?? '',
      title: data['title'] as String? ?? 'Untitled',
      content: data['content'] as String? ?? '',
      lessonOrder: data['lesson_order'] as int? ?? 0,
      estimatedDuration: data['estimated_duration'] as String?,
      status: data['status'] as String? ?? 'NOT_STARTED',
      certificateId: data['certificate_id'] as String?,
      verificationToken: data['verification_token'] as String?,
      certificateObjectKey: data['certificate_object_key'] as String?,
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
      'certificate_id': certificateId,
      'verification_token': verificationToken,
      'certificate_object_key': certificateObjectKey,
    };
  }
}
