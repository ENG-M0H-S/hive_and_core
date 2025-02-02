import 'dart:io';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import '../APIServices/DynamicApiServices.dart';
import '../Config/constants.dart';
import '../Helpers/DbHelper.dart';
import '../Helpers/NetworkHelper.dart';
import '../Models/CourseModel.dart';

class CourseController extends GetxController {
  final ApiService _apiService = ApiService();
  var courseList = <CourseModel>[].obs;
  CourseModel? courseDetail;
  RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    getCourseList();
    syncCourses(); // مزامنة البيانات عند بدء التطبيق
  }

  // جلب قائمة الكورسات
  Future<void> getCourseList() async {
    try {
      isLoading(true);

      final DatabaseHelper dbHelper = DatabaseHelper();
      final isConnected = await NetworkHelper.isNetworkAvailable();

      if (isConnected) {
        // الاتصال بالإنترنت متاح - جلب البيانات من API
        final response = await _apiService.get(baseAPIURLV1 + teachersAPI);
        if (response.statusCode == 200) {
          final apiCourses = (response.data as List)
              .map((json) => CourseModel.fromJson(json))
              .toList();

          // تحديث التخزين المحلي بالبيانات الجديدة من API
          for (final course in apiCourses) {
            await dbHelper.insertCourse(course);
          }

          courseList.value = apiCourses;
        } else {
          Get.snackbar("Error", "Failed to fetch courses from API",
              snackPosition: SnackPosition.BOTTOM);
        }
      } else {
        // لا يوجد اتصال بالإنترنت - جلب البيانات من التخزين المحلي
        final localCourses = await dbHelper.getCourses();
        courseList.value = localCourses;
        Get.snackbar("Info", "No internet connection. Showing local data.",
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch courses: $e",
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading(false);
    }
  }

  // إضافة كورس
  Future<void> addCourse({
    required String title,
    required String overview,
    required String subject,
    File? photo,
  }) async {
    try {
      isLoading(true);

      final DatabaseHelper dbHelper = DatabaseHelper();
      final isConnected = await NetworkHelper.isNetworkAvailable();

      if (isConnected) {
        // الاتصال بالإنترنت متاح - إرسال البيانات إلى API
        var data;
        dio.Options options =
        dio.Options(headers: {'Content-Type': 'application/json'});

        if (photo != null) {
          data = dio.FormData.fromMap({
            "subject": subject,
            "title": title,
            "overview": overview,
            "photo": dio.MultipartFile.fromFileSync(
              photo.path,
              filename: photo.path.split(Platform.pathSeparator).last,
            ),
          });
          options = dio.Options(headers: {'Content-Type': 'multipart/form-data'});
        } else {
          data = dio.FormData.fromMap({
            "subject": subject,
            "title": title,
            "overview": overview,
          });
        }

        final response = await _apiService.post(
            baseAPIURLV1 + teachersAPI + addAPI,
            data: data,
            options: options);

        if (response.statusCode == 201) {
          Get.snackbar('Success', 'Course added successfully');
        } else {
          Get.snackbar('Error', response.data['error']);
        }
      } else {
        // لا يوجد اتصال بالإنترنت - حفظ البيانات محليًا
        final newCourse = CourseModel(
          id: DateTime.now().millisecondsSinceEpoch, // ID مؤقت
          title: title,
          subject: subject,
          overview: overview,
          createdAt: DateTime.now().toIso8601String(),
          isSynced: false, // لم تتم مزامنتها بعد
        );

        await dbHelper.insertCourse(newCourse);
        Get.snackbar('Info', 'Course saved locally. Sync with API when online.',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to add course: $e');
    } finally {
      isLoading(false);
    }

    getCourseList();
  }

  // مزامنة الكورسات غير المتزامنة مع الخادم
  Future<void> syncCourses() async {
    try {
      final isConnected = await NetworkHelper.isNetworkAvailable();
      if (!isConnected) return; // لا توجد اتصال بالإنترنت

      final DatabaseHelper dbHelper = DatabaseHelper();
      final List<CourseModel> localCourses = await dbHelper.getCourses();

      for (final course in localCourses) {
        if (!course.isSynced) {
          // إذا لم تتم مزامنة الدورة
          await addCourse(
            title: course.title,
            overview: course.overview,
            subject: course.subject,
            photo: null, // يمكنك تعديل هذا إذا كان لديك ملفات
          );

          // تحديث حالة المزامنة في التخزين المحلي
          await dbHelper.updateCourse(course.copyWith(isSynced: true));
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to sync courses: $e",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // تحديث كورس
  Future<int> updateCourse(CourseModel course) async {
    try {
      final DatabaseHelper dbHelper = DatabaseHelper();
      final isConnected = await NetworkHelper.isNetworkAvailable();

      if (isConnected) {
        // الاتصال بالإنترنت متاح - تحديث البيانات في API
        var data;
        dio.Options options =
        dio.Options(headers: {'Content-Type': 'application/json'});

        if (course.photo != null) {
          data = dio.FormData.fromMap({
            "subject": course.subject,
            "title": course.title,
            "overview": course.overview,
            "photo": dio.MultipartFile.fromFileSync(
              course.photo!,
              filename: course.photo!.split(Platform.pathSeparator).last,
            ),
          });
          options = dio.Options(headers: {'Content-Type': 'multipart/form-data'});
        } else {
          data = dio.FormData.fromMap({
            "subject": course.subject,
            "title": course.title,
            "overview": course.overview,
          });
        }

        final response = await _apiService.put(
            '${baseAPIURLV1 + teachersAPI}${course.id}/',
            data: data,
            options: options);

        if (response.statusCode == 200) {
          Get.snackbar('Success', 'Course updated successfully');
          return course.id;
        } else {
          Get.snackbar('Error', response.data['error']);
          return -1;
        }
      } else {
        // لا يوجد اتصال بالإنترنت - تحديث البيانات محليًا
        await dbHelper.updateCourse(course);
        Get.snackbar('Info', 'Course updated locally. Sync with API when online.',
            snackPosition: SnackPosition.BOTTOM);
        return course.id;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update course: $e');
      return -1;
    }
  }

  // حذف كورس
  Future<int> deleteCourse(int id) async {
    try {
      final DatabaseHelper dbHelper = DatabaseHelper();
      final isConnected = await NetworkHelper.isNetworkAvailable();

      if (isConnected) {
        // الاتصال بالإنترنت متاح - حذف البيانات من API
        final response = await _apiService.delete('${baseAPIURLV1 + teachersAPI}$id/');
        if (response.statusCode == 204) {
          Get.snackbar('Success', 'Course deleted successfully');
          return id;
        } else {
          Get.snackbar('Error', response.data['error']);
          return -1;
        }
      } else {
        // لا يوجد اتصال بالإنترنت - حذف البيانات محليًا
        await dbHelper.deleteCourse(id);
        Get.snackbar('Info', 'Course deleted locally. Sync with API when online.',
            snackPosition: SnackPosition.BOTTOM);
        return id;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete course: $e');
      return -1;
    }
  }

  // مسح جميع البيانات المحلية
  Future<void> clearBox() async {
    try {
      final DatabaseHelper dbHelper = DatabaseHelper();
      await dbHelper.clearBox();
    } catch (e) {
      Get.snackbar('Error', 'Failed to clear local data: $e');
    }
  }
}