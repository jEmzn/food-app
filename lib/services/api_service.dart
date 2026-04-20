// ตัวอย่าง lib/services/food_api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// import '../models/food.dart';

// TODO: 
class FoodApiService {

  final String baseUrl =
      "http://192.168.1.7:3000/search";

  Future<List<String>> fetchSearchFoods(String word) async {
    const maxResults = 3;
    final endpoint = "?query=$word";
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['suggestions'] == null ||
          data['suggestions']['suggestion'] == null) {
        debugPrint('Suggestions Data NULL!!!!');
        debugPrint(data.toString());
        return [];
      }
      var suggestionsData = data['suggestions']['suggestion'];
      if (suggestionsData is String) {
        debugPrint('Suggestions Data String!!!!');
        return [suggestionsData];
      }

      debugPrint('Suggestions Data Completed!!!!');
      return List<String>.from(suggestionsData);
    } else {
      throw Exception('Failed to load foods: ${response.statusCode}');
    }
  }
}
