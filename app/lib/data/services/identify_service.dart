import 'dart:io';
import 'package:dio/dio.dart' hide MultipartFile;
import 'package:dio/dio.dart' as dio;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/api_constants.dart';
import '../models/plant.dart';

class IdentifyService {
  static final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 120),
    ),
  );

  /// Pings the backend health endpoint to wake up the Render free-tier instance.
  static Future<void> warmUp() async {
    try {
      await _dio.get(ApiConstants.backendBaseUrl);
    } catch (_) {}
  }

  /// Sends images to the LeafLens FastAPI backend and returns a [PlantModel].
  /// Throws [IdentifyException] on low confidence or server errors.
  static Future<PlantModel> identify(List<File> images, String mode) async {
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;

    final formData = FormData();
    for (final file in images) {
      formData.files.add(MapEntry(
        'files',
        await dio.MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      ));
    }
    formData.fields.add(MapEntry('organ', mode));

    try {
      final response = await _dio.post(
        '${ApiConstants.backendBaseUrl}/identify',
        data: formData,
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      final data = response.data as Map<String, dynamic>;

      if (data.containsKey('error')) {
        throw IdentifyException(
          code: data['error'] as String,
          message: data['message'] as String? ??
              data['detail'] as String? ??
              'Identification failed',
        );
      }

      return PlantModel.fromJson(data);
    } on DioException catch (e) {
      if (e.response != null) {
        final body = e.response!.data;
        throw IdentifyException(
          code: 'network_error',
          message: body is Map
              ? (body['detail'] ?? e.message ?? 'Server error')
              : 'Server error',
        );
      }
      throw IdentifyException(
        code: 'connection_error',
        message: 'Could not connect to server. Check your internet connection.',
      );
    }
  }
}

class IdentifyException implements Exception {
  final String code;
  final String message;
  const IdentifyException({required this.code, required this.message});

  @override
  String toString() => message;
}
