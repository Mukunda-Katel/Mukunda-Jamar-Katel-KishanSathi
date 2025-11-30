import '../models/product_model.dart';
import '../services/product_service.dart';

class ProductRepository {
  final ProductService _productService = ProductService();

  Future<List<Category>> getCategories() async {
    try {
      return await _productService.getCategories();
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }
  Future<List<Product>> getProducts({
    int? categoryId,
    String? status,
    bool? isOrganic,
    bool? availableOnly,
    String? search,
  }) async {
    try {
      return await _productService.getProducts(
        categoryId: categoryId,
        status: status,
        isOrganic: isOrganic,
        availableOnly: availableOnly,
        search: search,
      );
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  Future<List<Product>> getMyProducts(String token) async {
    try {
      return await _productService.getMyProducts(token);
    } catch (e) {
      throw Exception('Failed to fetch my products: $e');
    }
  }

  Future<Product> createProduct(String token, ProductCreateRequest request) async {
    try {
      return await _productService.createProduct(token, request);
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  Future<Product> updateProduct(
    String token,
    int productId,
    ProductCreateRequest request,
  ) async {
    try {
      return await _productService.updateProduct(token, productId, request);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  Future<void> deleteProduct(String token, int productId) async {
    try {
      await _productService.deleteProduct(token, productId);
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  Future<void> markAsSold(String token, int productId) async {
    try {
      await _productService.markAsSold(token, productId);
    } catch (e) {
      throw Exception('Failed to mark as sold: $e');
    }
  }

  Future<void> markAsAvailable(String token, int productId) async {
    try {
      await _productService.markAsAvailable(token, productId);
    } catch (e) {
      throw Exception('Failed to mark as available: $e');
    }
  }
}