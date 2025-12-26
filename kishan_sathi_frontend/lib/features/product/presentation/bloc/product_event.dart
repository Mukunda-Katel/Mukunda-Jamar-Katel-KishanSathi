import 'package:equatable/equatable.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

class LoadCategories extends ProductEvent {}

class LoadProducts extends ProductEvent {
  final int? categoryId;
  final String? status;
  final bool? isOrganic;
  final bool? availableOnly;
  final String? search;

  const LoadProducts({
    this.categoryId,
    this.status,
    this.isOrganic,
    this.availableOnly,
    this.search,
  });

  @override
  List<Object?> get props => [categoryId, status, isOrganic, availableOnly, search];
}

class LoadMyProducts extends ProductEvent {
  final String token;

  const LoadMyProducts(this.token);

  @override
  List<Object> get props => [token];
}

class CreateProduct extends ProductEvent {
  final String token;
  final Map<String, dynamic> productData;

  const CreateProduct(this.token, this.productData);

  @override
  List<Object> get props => [token, productData];
}

class UpdateProduct extends ProductEvent {
  final String token;
  final int productId;
  final Map<String, dynamic> productData;

  const UpdateProduct(this.token, this.productId, this.productData);

  @override
  List<Object> get props => [token, productId, productData];
}

class DeleteProduct extends ProductEvent {
  final String token;
  final int productId;

  const DeleteProduct(this.token, this.productId);

  @override
  List<Object> get props => [token, productId];
}

class MarkProductAsSold extends ProductEvent {
  final String token;
  final int productId;

  const MarkProductAsSold(this.token, this.productId);

  @override
  List<Object> get props => [token, productId];
}

class MarkProductAsAvailable extends ProductEvent {
  final String token;
  final int productId;

  const MarkProductAsAvailable(this.token, this.productId);

  @override
  List<Object> get props => [token, productId];
}
