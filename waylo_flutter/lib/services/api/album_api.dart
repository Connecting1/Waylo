import 'api_service.dart';

class AlbumApi {
  // 앨범 정보 가져오기 (GET)
  static Future<Map<String, dynamic>> fetchAlbumInfo() async {
    String? userId = await ApiService.getUserId();
    if (userId == null) return {"error": "No User Logged In"};

    String endpoint = "/api/albums/$userId/";

    Map<String, dynamic> response = await ApiService.sendRequest(endpoint: endpoint);

    return await ApiService.sendRequest(endpoint: "/api/albums/$userId/");
  }

  // 앨범 정보 수정 (PATCH)
  static Future<Map<String, dynamic>> updateAlbumInfo({
    required String userId,
    String? backgroundColor,
    String? backgroundPattern,
  }) async {
    return await ApiService.sendRequest(
      endpoint: "/api/albums/$userId/update/",
      method: "PATCH",
      body: {
        "background_color": backgroundColor,
        "background_pattern": backgroundPattern,
      },
    );
  }
}
