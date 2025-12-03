import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/product/product_bloc.dart';
import '../../bloc/product/product_event.dart';
import '../../bloc/product/product_state.dart';
import '../../repositories/product_repository.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();
  final _districtController = TextEditingController();

  // Create ProductBloc as instance variable
  late final ProductBloc _productBloc;

  int? _selectedCategoryId;
  String _selectedUnit = 'kg';
  bool _isOrganic = false;
  DateTime? _harvestDate;
  File? _imageFile;
  List<Map<String, dynamic>> _categories = [];
  bool _isLoadingCategories = true;

  final List<Map<String, String>> _units = [
    {'value': 'kg', 'label': 'Kilogram'},
    {'value': 'g', 'label': 'Gram'},
    {'value': 'l', 'label': 'Liter'},
    {'value': 'ml', 'label': 'Milliliter'},
    {'value': 'piece', 'label': 'Piece'},
    {'value': 'dozen', 'label': 'Dozen'},
    {'value': 'bag', 'label': 'Bag'},
    {'value': 'quintal', 'label': 'Quintal'},
    {'value': 'ton', 'label': 'Ton'},
  ];

  @override
  void initState() {
    super.initState();
    // Initialize ProductBloc
    _productBloc = ProductBloc(productRepository: ProductRepository());
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await ProductRepository().getCategories();
      setState(() {
        _categories = categories.map((c) => {'id': c.id, 'name': c.name}).toList();
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load categories: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _selectHarvestDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryGreen,
              onPrimary: Colors.white,
              onSurface: AppTheme.darkGreen,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _harvestDate = picked;
      });
    }
  }

  void _submitProduct() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication required')),
      );
      return;
    }

    final productData = {
      'category_id': _selectedCategoryId!,  
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': double.parse(_priceController.text.trim()),
      'quantity': double.parse(_quantityController.text.trim()),
      'unit': _selectedUnit,
      'status': 'available',
      'is_organic': _isOrganic,
      'harvest_date': _harvestDate != null
          ? DateFormat('yyyy-MM-dd').format(_harvestDate!)
          : null,
      'location': _locationController.text.trim(),
      'district': _districtController.text.trim(),
      'image_path': _imageFile?.path,
    };

    print('Product data being sent: $productData');
    _productBloc.add(CreateProduct(authState.token, productData));
  }

  @override
  void dispose() {
    _productBloc.close();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _productBloc,
      child: BlocListener<ProductBloc, ProductState>(
        listener: (context, state) {
          if (state is ProductCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Product added successfully!'),
                backgroundColor: AppTheme.primaryGreen,
                duration: Duration(seconds: 2),
              ),
            );
            // Delay navigation to show the success message
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (context.mounted) {
                Navigator.pop(context, true); // Return true to indicate success
              }
            });
          } else if (state is ProductError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: AppTheme.errorRed,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            title: const Text('Add New Product'),
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: BlocBuilder<ProductBloc, ProductState>(
            builder: (context, state) {
              final isLoading = state is ProductLoading;

              return Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Image Picker
                          _buildImagePicker(),
                          const SizedBox(height: 24),

                          // Product Name
                          _buildTextField(
                            controller: _nameController,
                            label: 'Product Name',
                            hint: 'e.g., Fresh Tomatoes',
                            icon: Icons.shopping_basket,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter product name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Category Dropdown
                          _buildCategoryDropdown(),
                          const SizedBox(height: 16),

                          // Description
                          _buildTextField(
                            controller: _descriptionController,
                            label: 'Description',
                            hint: 'Describe your product...',
                            icon: Icons.description,
                            maxLines: 4,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter description';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Price and Quantity Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _priceController,
                                  label: 'Price (Rs.)',
                                  hint: '0.00',
                                  icon: Icons.currency_rupee,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Invalid';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: _quantityController,
                                  label: 'Quantity',
                                  hint: '0',
                                  icon: Icons.inventory,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Invalid';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Unit Dropdown
                          _buildUnitDropdown(),
                          const SizedBox(height: 16),

                          // Location
                          _buildTextField(
                            controller: _locationController,
                            label: 'Location',
                            hint: 'Farm location or village',
                            icon: Icons.location_on,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter location';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // District
                          _buildTextField(
                            controller: _districtController,
                            label: 'District',
                            hint: 'e.g., Kathmandu',
                            icon: Icons.map,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter district';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Harvest Date
                          _buildHarvestDatePicker(),
                          const SizedBox(height: 16),

                          // Organic Switch
                          _buildOrganicSwitch(),
                          const SizedBox(height: 32),

                          // Submit Button
                          ElevatedButton(
                            onPressed: isLoading ? null : _submitProduct,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              isLoading ? 'Adding Product...' : 'Add Product',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  if (isLoading)
                    Container(
                      color: Colors.black26,
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: _imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  _imageFile!,
                  fit: BoxFit.cover,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to add product image',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primaryGreen),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
        ),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: _isLoadingCategories
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          : DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedCategoryId,
                hint: const Row(
                  children: [
                    Icon(Icons.category, color: AppTheme.primaryGreen),
                    SizedBox(width: 12),
                    Text('Select Category'),
                  ],
                ),
                isExpanded: true,
                items: _categories.map((category) {
                  return DropdownMenuItem<int>(
                    value: category['id'] as int,
                    child: Text(category['name'] as String),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                    print('Selected category ID: $value'); // Debug log
                  });
                },
              ),
            ),
    );
  }

  Widget _buildUnitDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedUnit,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryGreen),
          items: _units.map((unit) {
            return DropdownMenuItem<String>(
              value: unit['value'],
              child: Row(
                children: [
                  const Icon(Icons.straighten, color: AppTheme.primaryGreen),
                  const SizedBox(width: 12),
                  Text(unit['label']!),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedUnit = value;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildHarvestDatePicker() {
    return GestureDetector(
      onTap: _selectHarvestDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppTheme.primaryGreen),
            const SizedBox(width: 12),
            Text(
              _harvestDate != null
                  ? 'Harvest Date: ${DateFormat('MMM dd, yyyy').format(_harvestDate!)}'
                  : 'Select Harvest Date (Optional)',
              style: TextStyle(
                color: _harvestDate != null ? Colors.black : Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganicSwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.eco, color: AppTheme.primaryGreen),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Organic Product',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Switch(
            value: _isOrganic,
            onChanged: (value) {
              setState(() {
                _isOrganic = value;
              });
            },
            activeColor: AppTheme.primaryGreen,
          ),
        ],
      ),
    );
  }
}
