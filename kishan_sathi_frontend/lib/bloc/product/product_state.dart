import 'package:equatable/equatable.dart';
import '../../features/product/data/models/product_model.dart';

abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class CategoriesLoaded extends ProductState {
  final List<Category> categories;

  const CategoriesLoaded(this.categories);

  @override
  List<Object> get props => [categories];
}

class ProductsLoaded extends ProductState {
  final List<Product> products;

  const ProductsLoaded(this.products);

  @override
  List<Object> get props => [products];
}

class MyProductsLoaded extends ProductState {
  final List<Product> myProducts;

  const MyProductsLoaded(this.myProducts);

  @override
  List<Object> get props => [myProducts];
}

class ProductCreated extends ProductState {
  final Product product;

  const ProductCreated(this.product);

  @override
  List<Object> get props => [product];
}

class ProductUpdated extends ProductState {
  final Product product;

  const ProductUpdated(this.product);

  @override
  List<Object> get props => [product];
}

class ProductDeleted extends ProductState {}

class ProductStatusChanged extends ProductState {
  final String message;

  const ProductStatusChanged(this.message);

  @override
  List<Object> get props => [message];
}

class ProductError extends ProductState {
  final String message;

  const ProductError(this.message);

  @override
  List<Object> get props => [message];
}
