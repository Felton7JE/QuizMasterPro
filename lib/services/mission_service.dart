import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/mission_model.dart';
import '../config/api_config.dart';

class MissionService {
  final http.Client _client = http.Client();

  Future<List<MissionModel>> getActiveMissions(String token, int userId) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/missions/active?userId=$userId'),
      headers: ApiConfig.getHeaders(token: token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => MissionModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load missions');
    }
  }

  Future<Map<String, dynamic>> claimReward(String token, int missionId, int userId) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/missions/$missionId/claim?userId=$userId'),
      headers: ApiConfig.getHeaders(token: token),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to claim reward');
    }
  }

  void dispose() {
    _client.close();
  }
}
