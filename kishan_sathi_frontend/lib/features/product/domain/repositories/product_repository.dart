import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/product.dart';

/// Product Repository Interface (Contract)
/// Implementations should be in data layer
abstract class ProductRepository {
  /// Get all categories
  Future<Either<Failure, List<Category>>> getCategories();

  /// Get products with optional filters
  Future<Either<Failure, List<Product>>> getProducts({
    int? categoryId,
    String? status,
    bool? isOrganic,
    bool? availableOnly,
    String? search,
  });

  /// Get my products (farmer's products)
  Future<Either<Failure, List<Product>>> getMyProducts(String token);

  /// Create new product
  Future<Either<Failure, Product>> createProduct({
    required String token,
    required int categoryId,
    required String name,
    required String description,
    required double price,
    required double quantity,
    required String unit,
    required String status,
    required bool isOrganic,
    required DateTime? harvestDate,
    required String location,
    required String district,
    String? imagePath,
  });

  /// Update existing product
  Future<Either<Failure, Product>> updateProduct({
    required String token,
    required int productId,
    required int categoryId,
    required String name,
    required String description,
    required double price,
    required double quantity,
    required String unit,
    required String status,
    required bool isOrganic,
    required DateTime? harvestDate,
    required String location,
    required String district,
    String? imagePath,
  });

  /// Delete product
  Future<Either<Failure, void>> deleteProduct({
    required String token,
    required int productId,
  });

  /// Mark product as sold
  Future<Either<Failure, String>> markProductAsSold({
    required String token,
    required int productId,
  });

  /// Mark product as available
  Future<Either<Failure, String>> markProductAsAvailable({
    required String token,
    required int productId,
  });
}
