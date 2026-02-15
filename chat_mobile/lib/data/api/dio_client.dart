// lib/data/api/dio_client.dart

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response, FormData;
import 'api_endpoints.dart';
import 'api_interceptors.dart';
import '../../core/shared/environment.dart';

class DioClient extends GetxService {
  late Dio _publicDio;
  late Dio _privateDio;
  late Dio _uploadDio;

  Dio get publicDio => _publicDio;
  Dio get privateDio => _privateDio;
  Dio get uploadDio => _uploadDio;

  Future<DioClient> init() async {
    final baseOptions = BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: Duration(seconds: AppEnvironment.apiTimeout),
      receiveTimeout: Duration(seconds: AppEnvironment.apiTimeout),
      headers: const {
        'Accept': 'application/json',
      },
    );

    // PUBLIC (sans token)
    _publicDio = Dio(baseOptions);
    _publicDio.interceptors.addAll([
      LoggingInterceptor(),
      ErrorInterceptor(),
    ]);

    // PRIVATE (avec token)
    _privateDio = Dio(baseOptions);
    _privateDio.interceptors.addAll([
      AuthInterceptor(), 
      LoggingInterceptor(),
      ErrorInterceptor(),
    ]);

    //  UPLOAD (avec token)
    _uploadDio = Dio(
      baseOptions.copyWith(
        connectTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 5),
        headers: const {
          'Content-Type': 'multipart/form-data',
          'Accept': 'application/json',
        },
      ),
    );

    _uploadDio.interceptors.addAll([
      AuthInterceptor(), 
      LoggingInterceptor(),
      ErrorInterceptor(),
    ]);

    print(' DioClient initialized');
    print(' BaseURL: ${ApiEndpoints.baseUrl}');
    print(' Environment: ${AppEnvironment.name}');

    return this;
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) =>
      _privateDio.get(path, queryParameters: queryParameters);

  //  CORRECTION: Suppression du paramètre inutile Map<String, int> map
  Future<Response> post(String path, {dynamic data}) =>
      _privateDio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _privateDio.put(path, data: data);

  Future<Response> patch(String path, {dynamic data}) =>
      _privateDio.patch(path, data: data);

  Future<Response> delete(String path, {dynamic data}) =>
      _privateDio.delete(path, data: data);

  // ======================
  // PUBLIC REQUESTS
  // ======================
  Future<Response> getPublic(String path,
          {Map<String, dynamic>? queryParameters}) =>
      _publicDio.get(path, queryParameters: queryParameters);

  Future<Response> postPublic(String path, {dynamic data}) =>
      _publicDio.post(path, data: data);

 
  Future<Response> upload(
    String path, {
    required FormData formData,
    ProgressCallback? onSendProgress,
  }) =>
      _uploadDio.post(path,
          data: formData, onSendProgress: onSendProgress);

  Future<Response> download(
    String urlPath,
    String savePath, {
    ProgressCallback? onReceiveProgress,
  }) =>
      _privateDio.download(urlPath, savePath,
          onReceiveProgress: onReceiveProgress);

  // ======================
  // UTILS
  // ======================
  void updateBaseUrl(String newBaseUrl) {
    _publicDio.options.baseUrl = newBaseUrl;
    _privateDio.options.baseUrl = newBaseUrl;
    _uploadDio.options.baseUrl = newBaseUrl;
    print(' BaseURL updated: $newBaseUrl');
  }
}