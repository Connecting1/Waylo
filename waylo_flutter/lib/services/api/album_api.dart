import 'api_service.dart';

class AlbumApi {
  // 앨범 정보 가져오기 (GET)
  static Future<Map<String, dynamic>> fetchAlbumInfo() async {
    String? userId = await ApiService.getUserId();
    if (userId == null) return {"error": "No User Logged In"};
    return await ApiService.sendRequest(endpoint: "/api/albums/$userId/");
  }
}
