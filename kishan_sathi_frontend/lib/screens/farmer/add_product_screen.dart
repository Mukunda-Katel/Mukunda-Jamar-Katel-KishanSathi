import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/product/presentation/bloc/product_bloc.dart';
import '../../features/product/presentation/bloc/product_event.dart';
import '../../features/product/presentation/bloc/product_state.dart';
import '../../features/product/data/repositories/product_repository_impl.dart';

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
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;

    final isTinyScreen = screenWidth < 360;
    final isSmallScreen = screenWidth < 600;
    final isNarrowFields = screenWidth < 420;

    final horizontalPadding = isTinyScreen ? 12.0 : (isSmallScreen ? 16.0 : 20.0);
    final fieldSpacing = isTinyScreen ? 12.0 : 16.0;
    final sectionSpacing = isTinyScreen ? 20.0 : 24.0;
    final submitTopSpacing = isTinyScreen ? 28.0 : 32.0;
    final submitBottomSpacing = isTinyScreen ? 16.0 : 20.0;

    final fieldRadius = isTinyScreen ? 10.0 : 12.0;
    final fieldPadding = isTinyScreen ? 14.0 : 16.0;
    final imageHeight = isTinyScreen ? 170.0 : (isSmallScreen ? 190.0 : 210.0);
    final imageIconSize = isTinyScreen ? 52.0 : 64.0;
    final imageHintSize = isTinyScreen ? 13.0 : 14.0;
    final imageLabelSpacing = isTinyScreen ? 6.0 : 8.0;
    final fieldIconSize = isTinyScreen ? 20.0 : 24.0;
    final fieldLabelSize = isTinyScreen ? 14.0 : 16.0;
    final submitFontSize = isTinyScreen ? 16.0 : 18.0;

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
                    padding: EdgeInsets.all(horizontalPadding),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Image Picker
                          _buildImagePicker(
                            height: imageHeight,
                            borderRadius: fieldRadius + 4,
                            iconSize: imageIconSize,
                            hintFontSize: imageHintSize,
                            labelSpacing: imageLabelSpacing,
                          ),
                          SizedBox(height: sectionSpacing),

                          // Product Name
                          _buildTextField(
                            controller: _nameController,
                            label: 'Product Name',
                            hint: 'e.g., Fresh Tomatoes',
                            icon: Icons.shopping_basket,
                            borderRadius: fieldRadius,
                            iconSize: fieldIconSize,
                            textSize: fieldLabelSize,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter product name';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: fieldSpacing),

                          // Category Dropdown
                          _buildCategoryDropdown(
                            horizontalPadding: fieldPadding,
                            borderRadius: fieldRadius,
                            iconSize: fieldIconSize,
                            textSize: fieldLabelSize,
                          ),
                          SizedBox(height: fieldSpacing),

                          // Description
                          _buildTextField(
                            controller: _descriptionController,
                            label: 'Description',
                            hint: 'Describe your product...',
                            icon: Icons.description,
                            maxLines: 4,
                            borderRadius: fieldRadius,
                            iconSize: fieldIconSize,
                            textSize: fieldLabelSize,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter description';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: fieldSpacing),

                          // Price and Quantity Row
                          isNarrowFields
                              ? Column(
                                  children: [
                                    _buildTextField(
                                      controller: _priceController,
                                      label: 'Price (Rs.)',
                                      hint: '0.00',
                                      icon: Icons.currency_rupee,
                                      keyboardType: TextInputType.number,
                                      borderRadius: fieldRadius,
                                      iconSize: fieldIconSize,
                                      textSize: fieldLabelSize,
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
                                    SizedBox(height: fieldSpacing),
                                    _buildTextField(
                                      controller: _quantityController,
                                      label: 'Quantity',
                                      hint: '0',
                                      icon: Icons.inventory,
                                      keyboardType: TextInputType.number,
                                      borderRadius: fieldRadius,
                                      iconSize: fieldIconSize,
                                      textSize: fieldLabelSize,
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
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        controller: _priceController,
                                        label: 'Price (Rs.)',
                                        hint: '0.00',
                                        icon: Icons.currency_rupee,
                                        keyboardType: TextInputType.number,
                                        borderRadius: fieldRadius,
                                        iconSize: fieldIconSize,
                                        textSize: fieldLabelSize,
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
                                    SizedBox(width: isTinyScreen ? 10 : 12),
                                    Expanded(
                                      child: _buildTextField(
                                        controller: _quantityController,
                                        label: 'Quantity',
                                        hint: '0',
                                        icon: Icons.inventory,
                                        keyboardType: TextInputType.number,
                                        borderRadius: fieldRadius,
                                        iconSize: fieldIconSize,
                                        textSize: fieldLabelSize,
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
                          SizedBox(height: fieldSpacing),

                          // Unit Dropdown
                          _buildUnitDropdown(
                            horizontalPadding: fieldPadding,
                            borderRadius: fieldRadius,
                            iconSize: fieldIconSize,
                            textSize: fieldLabelSize,
                          ),
                          SizedBox(height: fieldSpacing),

                          // Location
                          _buildTextField(
                            controller: _locationController,
                            label: 'Location',
                            hint: 'Farm location or village',
                            icon: Icons.location_on,
                            borderRadius: fieldRadius,
                            iconSize: fieldIconSize,
                            textSize: fieldLabelSize,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter location';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: fieldSpacing),

                          // District
                          _buildTextField(
                            controller: _districtController,
                            label: 'District',
                            hint: 'e.g., Kathmandu',
                            icon: Icons.map,
                            borderRadius: fieldRadius,
                            iconSize: fieldIconSize,
                            textSize: fieldLabelSize,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter district';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: fieldSpacing),

                          // Harvest Date
                          _buildHarvestDatePicker(
                            padding: fieldPadding,
                            borderRadius: fieldRadius,
                            iconSize: fieldIconSize,
                            textSize: fieldLabelSize,
                          ),
                          SizedBox(height: fieldSpacing),

                          // Organic Switch
                          _buildOrganicSwitch(
                            padding: fieldPadding,
                            borderRadius: fieldRadius,
                            iconSize: fieldIconSize,
                            textSize: fieldLabelSize,
                          ),
                          SizedBox(height: submitTopSpacing),

                          // Submit Button
                          ElevatedButton(
                            onPressed: isLoading ? null : _submitProduct,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: isTinyScreen ? 14 : 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(fieldRadius),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              isLoading ? 'Adding Product...' : 'Add Product',
                              style: TextStyle(
                                fontSize: submitFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: submitBottomSpacing),
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

  Widget _buildImagePicker({
    required double height,
    required double borderRadius,
    required double iconSize,
    required double hintFontSize,
    required double labelSpacing,
  }) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: _imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: Image.file(
                  _imageFile!,
                  fit: BoxFit.cover,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: iconSize,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: labelSpacing),
                  Text(
                    'Tap to add product image',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: hintFontSize,
                    ),
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
    double borderRadius = 12,
    double iconSize = 24,
    double textSize = 16,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(fontSize: textSize),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(fontSize: textSize),
        hintStyle: TextStyle(fontSize: textSize - 1),
        prefixIcon: Icon(icon, color: AppTheme.primaryGreen, size: iconSize),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
        ),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildCategoryDropdown({
    required double horizontalPadding,
    required double borderRadius,
    required double iconSize,
    required double textSize,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
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
                hint: Row(
                  children: [
                    Icon(Icons.category, color: AppTheme.primaryGreen, size: iconSize),
                    SizedBox(width: textSize < 15 ? 10 : 12),
                    Text(
                      'Select Category',
                      style: TextStyle(fontSize: textSize),
                    ),
                  ],
                ),
                isExpanded: true,
                items: _categories.map((category) {
                  return DropdownMenuItem<int>(
                    value: category['id'] as int,
                    child: Text(
                      category['name'] as String,
                      style: TextStyle(fontSize: textSize),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
              ),
            ),
    );
  }

  Widget _buildUnitDropdown({
    required double horizontalPadding,
    required double borderRadius,
    required double iconSize,
    required double textSize,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedUnit,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryGreen, size: iconSize),
          items: _units.map((unit) {
            return DropdownMenuItem<String>(
              value: unit['value'],
              child: Row(
                children: [
                  Icon(Icons.straighten, color: AppTheme.primaryGreen, size: iconSize),
                  SizedBox(width: textSize < 15 ? 10 : 12),
                  Text(
                    unit['label']!,
                    style: TextStyle(fontSize: textSize),
                  ),
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

  Widget _buildHarvestDatePicker({
    required double padding,
    required double borderRadius,
    required double iconSize,
    required double textSize,
  }) {
    return GestureDetector(
      onTap: _selectHarvestDate,
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: AppTheme.primaryGreen, size: iconSize),
            SizedBox(width: textSize < 15 ? 10 : 12),
            Expanded(
              child: Text(
                _harvestDate != null
                    ? 'Harvest Date: ${DateFormat('MMM dd, yyyy').format(_harvestDate!)}'
                    : 'Select Harvest Date (Optional)',
                style: TextStyle(
                  color: _harvestDate != null ? Colors.black : Colors.grey[600],
                  fontSize: textSize,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganicSwitch({
    required double padding,
    required double borderRadius,
    required double iconSize,
    required double textSize,
  }) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.eco, color: AppTheme.primaryGreen, size: iconSize),
          SizedBox(width: textSize < 15 ? 10 : 12),
          Expanded(
            child: Text(
              'Organic Product',
              style: TextStyle(fontSize: textSize, fontWeight: FontWeight.w500),
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
