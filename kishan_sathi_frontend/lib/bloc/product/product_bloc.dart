import 'package:flutter_bloc/flutter_bloc.dart';
import 'product_event.dart';
import 'product_state.dart';
import '../../repositories/product_repository.dart';
import '../../models/product_model.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository productRepository;

  ProductBloc({required this.productRepository}) : super(ProductInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<LoadProducts>(_onLoadProducts);
    on<LoadMyProducts>(_onLoadMyProducts);
    on<CreateProduct>(_onCreateProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<DeleteProduct>(_onDeleteProduct);
    on<MarkProductAsSold>(_onMarkProductAsSold);
    on<MarkProductAsAvailable>(_onMarkProductAsAvailable);
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    try {
      final categories = await productRepository.getCategories();
      emit(CategoriesLoaded(categories));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    try {
      final products = await productRepository.getProducts(
        categoryId: event.categoryId,
        status: event.status,
        isOrganic: event.isOrganic,
        availableOnly: event.availableOnly,
        search: event.search,
      );
      emit(ProductsLoaded(products));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onLoadMyProducts(
    LoadMyProducts event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    try {
      final products = await productRepository.getMyProducts(event.token);
      emit(MyProductsLoaded(products));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onCreateProduct(
    CreateProduct event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    try {
      final request = ProductCreateRequest(
        categoryId: event.productData['category_id'],
        name: event.productData['name'],
        description: event.productData['description'],
        price: event.productData['price'],
        quantity: event.productData['quantity'],
        unit: event.productData['unit'],
        status: event.productData['status'] ?? 'available',
        isOrganic: event.productData['is_organic'] ?? false,
        harvestDate: event.productData['harvest_date'],
        location: event.productData['location'],
        district: event.productData['district'],
        imagePath: event.productData['image_path'],
      );

      final product = await productRepository.createProduct(event.token, request);
      emit(ProductCreated(product));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onUpdateProduct(
    UpdateProduct event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    try {
      final request = ProductCreateRequest(
        categoryId: event.productData['category_id'],
        name: event.productData['name'],
        description: event.productData['description'],
        price: event.productData['price'],
        quantity: event.productData['quantity'],
        unit: event.productData['unit'],
        status: event.productData['status'] ?? 'available',
        isOrganic: event.productData['is_organic'] ?? false,
        harvestDate: event.productData['harvest_date'],
        location: event.productData['location'],
        district: event.productData['district'],
        imagePath: event.productData['image_path'],
      );

      final product = await productRepository.updateProduct(
        event.token,
        event.productId,
        request,
      );
      emit(ProductUpdated(product));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onDeleteProduct(
    DeleteProduct event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    try {
      await productRepository.deleteProduct(event.token, event.productId);
      emit(ProductDeleted());
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onMarkProductAsSold(
    MarkProductAsSold event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    try {
      await productRepository.markAsSold(event.token, event.productId);
      emit(const ProductStatusChanged('Product marked as sold'));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onMarkProductAsAvailable(
    MarkProductAsAvailable event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    try {
      await productRepository.markAsAvailable(event.token, event.productId);
      emit(const ProductStatusChanged('Product marked as available'));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }
}
