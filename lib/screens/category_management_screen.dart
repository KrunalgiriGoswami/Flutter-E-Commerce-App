import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/category_service.dart';
import '../models/category.dart';

class CategoryManagementScreen extends StatefulWidget {
  @override
  _CategoryManagementScreenState createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _imageUrl = '';
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
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
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load categories: $e')));
    }
  }

  void _addCategory() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final authService = Provider.of<AuthService>(context, listen: false);
      try {
        await CategoryService().addCategory(
          authService.token!,
          _name,
          _imageUrl,
        );
        _formKey.currentState!.reset();
        setState(() {
          _name = '';
          _imageUrl = '';
        });
        _loadCategories();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Category added successfully')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add category: $e')));
      }
    }
  }

  void _editCategory(Category category) async {
    _name = category.name;
    _imageUrl = category.imageUrl ?? '';
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Edit Category'),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: _name,
                    decoration: InputDecoration(labelText: 'Category Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Please enter a category name';
                      return null;
                    },
                    onSaved: (value) => _name = value!,
                  ),
                  TextFormField(
                    initialValue: _imageUrl,
                    decoration: InputDecoration(labelText: 'Image URL'),
                    validator: (value) {
                      if (value != null && value.isEmpty)
                        return 'Please enter a valid URL or leave blank';
                      return null;
                    },
                    onSaved: (value) => _imageUrl = value!,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final authService = Provider.of<AuthService>(
                      context,
                      listen: false,
                    );
                    try {
                      await CategoryService().updateCategory(
                        authService.token!,
                        category.id,
                        _name,
                        _imageUrl,
                      );
                      Navigator.pop(context);
                      _loadCategories();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Category updated successfully'),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to update category: $e'),
                        ),
                      );
                    }
                  }
                },
                child: Text('Save'),
              ),
            ],
          ),
    );
  }

  void _deleteCategory(int id) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      await CategoryService().deleteCategory(authService.token!, id);
      _loadCategories();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Category deleted successfully')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete category: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage Categories')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Category Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a category name';
                      }
                      return null;
                    },
                    onSaved: (value) => _name = value!,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Image URL'),
                    validator: (value) {
                      if (value != null && value.isEmpty)
                        return 'Please enter a valid URL or leave blank';
                      return null;
                    },
                    onSaved: (value) => _imageUrl = value!,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _addCategory,
                    child: Text('Add Category'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return ListTile(
                    leading:
                        category.imageUrl != null
                            ? Image.network(
                              category.imageUrl!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.contain,
                              errorBuilder:
                                  (context, error, stackTrace) =>
                                      Icon(Icons.error),
                            )
                            : Icon(Icons.category),
                    title: Text(category.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => _editCategory(category),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _deleteCategory(category.id),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
