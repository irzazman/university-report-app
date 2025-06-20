import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Replace with your actual Render API URL
  static const String _baseUrl = 'https://report-classifier-api.onrender.com';
  static const Duration _timeout = Duration(seconds: 15);

  static Future<String> getPredictedCategory(String description) async {
    try {
      final url = Uri.parse('$_baseUrl/predict');
      final requestBody = {
        'text': description.trim(), // Changed from 'description' to 'text'
        'language': 'en', // Added required language parameter
      };

      print('Making API request to: $url');
      print('Request body: ${json.encode(requestBody)}');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(requestBody),
          )
          .timeout(_timeout);

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Handle different possible response formats
        String? predictedCategory;

        if (data is Map<String, dynamic>) {
          // Try different possible field names
          predictedCategory =
              data['category'] as String? ??
              data['prediction'] as String? ??
              data['result'] as String? ??
              data['class'] as String?;
        } else if (data is String) {
          predictedCategory = data;
        }

        if (predictedCategory != null && predictedCategory.isNotEmpty) {
          final formatted = _formatCategoryName(predictedCategory);
          print('Formatted category: $formatted');
          return formatted;
        } else {
          print('No valid category found in response');
          return 'Other';
        }
      } else {
        print('API request failed with status: ${response.statusCode}');
        print('Error response: ${response.body}');

        // Try to parse error message
        try {
          final errorData = json.decode(response.body);
          final errorMessage =
              errorData['error'] ?? errorData['message'] ?? 'Unknown error';
          print('API Error: $errorMessage');
        } catch (e) {
          print('Could not parse error response');
        }

        return 'Other';
      }
    } catch (e) {
      print('Error calling prediction API: $e');

      // Check if it's a timeout or connection error
      if (e.toString().contains('TimeoutException')) {
        print('Request timed out - API might be slow to respond');
      } else if (e.toString().contains('SocketException')) {
        print('Network connection issue');
      }

      return 'Other';
    }
  }

  // Format the category name to match your predefined categories
  static String _formatCategoryName(String category) {
    // Convert to proper case and handle common variations
    final formatted = category.trim();

    // Map common variations to your standard categories
    final categoryMappings = {
      'electrical': 'Electrical',
      'electric': 'Electrical',
      'furniture': 'Furniture',
      'it': 'IT/Equipment',
      'equipment': 'IT/Equipment',
      'computer': 'IT/Equipment',
      'technology': 'IT/Equipment',
      'cleanliness': 'Cleanliness',
      'cleaning': 'Cleanliness',
      'hygiene': 'Cleanliness',
      'structural': 'Structural',
      'structure': 'Structural',
      'building': 'Structural',
      'aircon': 'Air Conditioning',
      'air conditioning': 'Air Conditioning',
      'ac': 'Air Conditioning',
      'hvac': 'Air Conditioning',
      'plumbing': 'Plumbing',
      'water': 'Plumbing',
      'pipe': 'Plumbing',
      'pipes': 'Plumbing',
      'internet': 'Internet/WiFi',
      'wifi': 'Internet/WiFi',
      'wi-fi': 'Internet/WiFi',
      'network': 'Internet/WiFi',
      'connectivity': 'Internet/WiFi',
      'safety': 'Safety',
      'security': 'Safety',
      'lighting': 'Lighting',
      'light': 'Lighting',
      'lights': 'Lighting',
      'garden': 'Garden/Landscape',
      'landscape': 'Garden/Landscape',
      'landscaping': 'Garden/Landscape',
      'plants': 'Garden/Landscape',
      'greenery': 'Garden/Landscape',
      'road': 'Road/Walkways',
      'roads': 'Road/Walkways',
      'walkway': 'Road/Walkways',
      'walkways': 'Road/Walkways',
      'path': 'Road/Walkways',
      'paths': 'Road/Walkways',
      'pathway': 'Road/Walkways',
      'signage': 'Signage',
      'sign': 'Signage',
      'signs': 'Signage',
      'other': 'Other',
    };

    final lowerCase = formatted.toLowerCase();
    final mapped = categoryMappings[lowerCase];

    if (mapped != null) {
      return mapped;
    }

    // If no exact match, try partial matches
    for (final entry in categoryMappings.entries) {
      if (lowerCase.contains(entry.key) || entry.key.contains(lowerCase)) {
        return entry.value;
      }
    }

    // Return the original formatted string if no mapping found
    return formatted;
  }

  // Test method to check API connectivity
  static Future<bool> testApiConnection() async {
    try {
      // Test with a simple prediction request instead of a health endpoint
      final url = Uri.parse('$_baseUrl/predict');
      final testBody = {'text': 'test connection', 'language': 'en'};

      print('Testing API connection to: $url');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(testBody),
          )
          .timeout(Duration(seconds: 5));

      print('Test API response status: ${response.statusCode}');

      // Return true if we get any valid response (200 or even other codes that indicate the server is responding)
      return response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 422;
    } catch (e) {
      print('API connection test failed: $e');
      return false;
    }
  }
}
