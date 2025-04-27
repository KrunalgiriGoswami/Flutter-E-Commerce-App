import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/address.dart';

class AddressProvider with ChangeNotifier {
  List<Address> _addresses = [];
  Address? _selectedShippingAddress;

  List<Address> get addresses => _addresses;
  Address? get selectedShippingAddress => _selectedShippingAddress;

  AddressProvider() {
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final addressesJson = prefs.getString('addresses');
    if (addressesJson != null) {
      final List<dynamic> addressesList = jsonDecode(addressesJson);
      _addresses = addressesList.map((json) => Address.fromJson(json)).toList();
    }

    final selectedAddressJson = prefs.getString('selectedShippingAddress');
    if (selectedAddressJson != null) {
      _selectedShippingAddress = Address.fromJson(
        jsonDecode(selectedAddressJson),
      );
    }

    notifyListeners();
  }

  Future<void> _saveAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final addressesJson = jsonEncode(
      _addresses.map((address) => address.toJson()).toList(),
    );
    await prefs.setString('addresses', addressesJson);

    if (_selectedShippingAddress != null) {
      final selectedAddressJson = jsonEncode(
        _selectedShippingAddress!.toJson(),
      );
      await prefs.setString('selectedShippingAddress', selectedAddressJson);
    } else {
      await prefs.remove('selectedShippingAddress');
    }
  }

  void addAddress(Address address) {
    _addresses.add(address);
    _saveAddresses();
    notifyListeners();
  }

  void updateAddress(String id, Address updatedAddress) {
    final index = _addresses.indexWhere((address) => address.id == id);
    if (index != -1) {
      _addresses[index] = updatedAddress;
      if (_selectedShippingAddress?.id == id) {
        _selectedShippingAddress = updatedAddress;
      }
      _saveAddresses();
      notifyListeners();
    }
  }

  void deleteAddress(String id) {
    _addresses.removeWhere((address) => address.id == id);
    if (_selectedShippingAddress?.id == id) {
      _selectedShippingAddress = null;
    }
    _saveAddresses();
    notifyListeners();
  }

  void selectShippingAddress(String id) {
    final address = _addresses.firstWhere((address) => address.id == id);
    _selectedShippingAddress = address;
    _saveAddresses();
    notifyListeners();
  }
}
