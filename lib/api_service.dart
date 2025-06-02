import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://report-classifier-api.onrender.com';

  static Future<String?> getPredictedCategory(String description) async {
    final url = Uri.parse('$baseUrl/predict');
    try {
      print(
        'Request body: ${jsonEncode({'text': description, 'language': 'en'})}',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': description, 'language': 'en'}),
      );

      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Predicted label: ${data['category']}');
        return data['category'];
      } else {
        print('Failed to predict category: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }
}
