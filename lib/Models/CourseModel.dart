import 'package:hive/hive.dart';

part 'CourseModel.g.dart'; // سيتم إنشاء هذا الملف تلقائيًا بواسطة Hive

@HiveType(typeId: 0) // تأكد من تعيين typeId فريد لكل نموذج
class CourseModel {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String subject;

  @HiveField(3)
  final String overview;

  @HiveField(4)
  final String? photo;

  @HiveField(5)
  final String createdAt;

  @HiveField(6)
  final bool isSynced; // إضافة هذا الحقل

  CourseModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.overview,
    this.photo,
    required this.createdAt,
    this.isSynced = false, // القيمة الافتراضية
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) => CourseModel(
    id: json['id'] as int,
    title: json['title'] as String,
    subject: json['subject'] as String,
    overview: json['overview'] as String,
    photo: json['photo'] as String?,
    createdAt: json['createdAt'] as String,
    isSynced: json['isSynced'] ?? false, // إضافة هذا الحقل
  );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'overview': overview,
      'photo': photo,
      'createdAt': createdAt,
      'isSynced': isSynced, // إضافة هذا الحقل
    };
  }

  // دالة copyWith لتسهيل تحديث الحقول
  CourseModel copyWith({
    int? id,
    String? title,
    String? subject,
    String? overview,
    String? photo,
    String? createdAt,
    bool? isSynced,
  }) {
    return CourseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      overview: overview ?? this.overview,
      photo: photo ?? this.photo,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}