import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';
import '../services/category_service.dart';
import '../models/product.dart';
import '../models/category.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  ProductFormScreen({this.product});

  @override
  _ProductFormScreenState createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _description = '';
  double _price = 0.0;
  int _categoryId = 1; // Default to first category
  String _imageUrl = '';
  List<Category> _categories = []; // Store full category list

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _name = widget.product!.name;
      _description = widget.product!.description;
      _price = widget.product!.price;
      _categoryId = widget.product!.categoryId;
      _imageUrl = widget.product!.imageUrl ?? '';
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      final categories = await CategoryService().fetchCategories(
        authService.token!,
      );
      setState(() {
        _categories = categories;
        if (widget.product != null &&
            !categories.any((cat) => cat.id == _categoryId)) {
          _categoryId =
              categories.isNotEmpty
                  ? categories[0].id
                  : 1; // Fallback if category not found
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load categories: $e')));
    }
  }

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final authService = Provider.of<AuthService>(context, listen: false);
      final product = Product(
        id: widget.product?.id,
        name: _name,
        description: _description,
        price: _price,
        categoryId: _categoryId,
        imageUrl: _imageUrl.isNotEmpty ? _imageUrl : null,
      );
      try {
        if (widget.product == null) {
          await ProductService().addProduct(authService.token!, product);
        } else {
          await ProductService().updateProduct(authService.token!, product);
        }
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save product: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _name,
                decoration: InputDecoration(labelText: 'Product Name'),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please enter a name';
                  return null;
                },
                onSaved: (value) => _name = value!,
              ),
              TextFormField(
                initialValue: _description,
                decoration: InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please enter a description';
                  return null;
                },
                onSaved: (value) => _description = value!,
              ),
              TextFormField(
                initialValue: _price.toString(),
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please enter a price';
                  if (double.tryParse(value) == null)
                    return 'Please enter a valid number';
                  return null;
                },
                onSaved: (value) => _price = double.parse(value!),
              ),
              DropdownButtonFormField<int>(
                value: _categoryId,
                decoration: InputDecoration(labelText: 'Category'),
                items:
                    _categories.map((category) {
                      return DropdownMenuItem<int>(
                        value: category.id,
                        child: Text(category.name),
                      );
                    }).toList(),
                validator: (value) {
                  if (value == null) return 'Please select a category';
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _categoryId = value!;
                  });
                },
              ),
              TextFormField(
                initialValue: _imageUrl,
                decoration: InputDecoration(labelText: 'Image URL'),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final urlRegExp = RegExp(
                      r'^(https?:\/\/)?([\w-]+(\.[\w-]+)+)([\w.,@?^=%&:/~+#-]*[\w@?^=%&/~+#-])?$',
                    );
                    if (!urlRegExp.hasMatch(value))
                      return 'Please enter a valid URL';
                  }
                  return null;
                },
                onSaved: (value) => _imageUrl = value!,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProduct,
                child: Text(
                  widget.product == null ? 'Add Product' : 'Update Product',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
