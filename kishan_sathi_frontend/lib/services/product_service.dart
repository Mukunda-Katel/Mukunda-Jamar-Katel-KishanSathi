import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/product_model.dart';

class ProductService {
  final String baseUrl = ApiConfig.baseUrl;

  // Get all categories
  Future<List<Category>> getCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/farmer/categories/'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Category.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }

  // Get all products
  Future<List<Product>> getProducts({
    int? categoryId,
    String? status,
    bool? isOrganic,
    bool? availableOnly,
    String? search,
  }) async {
    var uri = Uri.parse('$baseUrl/farmer/products/');
    
    Map<String, String> queryParams = {};
    if (categoryId != null) queryParams['category'] = categoryId.toString();
    if (status != null) queryParams['status'] = status;
    if (isOrganic != null) queryParams['is_organic'] = isOrganic.toString();
    if (availableOnly != null) queryParams['available_only'] = availableOnly.toString();
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    uri = uri.replace(queryParameters: queryParams);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> results = data['results'] ?? data;
      return results.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  // Get farmer's own products
  Future<List<Product>> getMyProducts(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/farmer/products/my_products/'),
      headers: {
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> results = data['results'] ?? data;
      return results.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load my products');
    }
  }

  // Create product
  Future<Product> createProduct(String token, ProductCreateRequest request) async {
    var uri = Uri.parse('$baseUrl/farmer/products/');
    var multipartRequest = http.MultipartRequest('POST', uri);

    // Add headers
    multipartRequest.headers['Authorization'] = 'Token $token';

    // Add fields
    final jsonData = request.toJson();
    print('ProductCreateRequest.toJson(): $jsonData');
    multipartRequest.fields.addAll(
      jsonData.map((key, value) => MapEntry(key, value.toString())),
    );

    print('Multipart fields: ${multipartRequest.fields}');

    // Add image if provided
    if (request.imagePath != null && request.imagePath!.isNotEmpty) {
      var file = await http.MultipartFile.fromPath('image', request.imagePath!);
      multipartRequest.files.add(file);
      print('Image file added: ${request.imagePath}');
    }

    print('Sending POST to: $uri');
    var streamedResponse = await multipartRequest.send();
    var response = await http.Response.fromStream(streamedResponse);

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 201) {
      return Product.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create product: ${response.body}');
    }
  }

  // Update product
  Future<Product> updateProduct(
    String token,
    int productId,
    ProductCreateRequest request,
  ) async {
    var uri = Uri.parse('$baseUrl/farmer/products/$productId/');
    var multipartRequest = http.MultipartRequest('PUT', uri);

    multipartRequest.headers['Authorization'] = 'Token $token';
    multipartRequest.fields.addAll(
      request.toJson().map((key, value) => MapEntry(key, value.toString())),
    );

    if (request.imagePath != null && request.imagePath!.isNotEmpty) {
      var file = await http.MultipartFile.fromPath('image', request.imagePath!);
      multipartRequest.files.add(file);
    }

    var streamedResponse = await multipartRequest.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return Product.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update product');
    }
  }

  // Delete product
  Future<void> deleteProduct(String token, int productId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/farmer/products/$productId/'),
      headers: {
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete product');
    }
  }

  // Mark product as sold
  Future<void> markAsSold(String token, int productId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/farmer/products/$productId/mark_sold/'),
      headers: {
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark product as sold');
    }
  }

  // Mark product as available
  Future<void> markAsAvailable(String token, int productId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/farmer/products/$productId/mark_available/'),
      headers: {
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark product as available');
    }
  }
}
