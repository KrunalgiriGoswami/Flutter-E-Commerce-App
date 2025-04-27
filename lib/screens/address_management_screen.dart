import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/address.dart';
import '../providers/address_provider.dart';

class AddressManagementScreen extends StatelessWidget {
  const AddressManagementScreen({Key? key}) : super(key: key);

  void _showAddressForm(BuildContext context, {Address? address}) {
    final nameController = TextEditingController(text: address?.name ?? '');
    final streetController = TextEditingController(text: address?.street ?? '');
    final cityController = TextEditingController(text: address?.city ?? '');
    final stateController = TextEditingController(text: address?.state ?? '');
    final postalCodeController = TextEditingController(
      text: address?.postalCode ?? '',
    );
    final phoneNumberController = TextEditingController(
      text: address?.phoneNumber ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(address == null ? 'Add Address' : 'Edit Address'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Full Name'),
                ),
                TextField(
                  controller: streetController,
                  decoration: InputDecoration(labelText: 'Street Address'),
                ),
                TextField(
                  controller: cityController,
                  decoration: InputDecoration(labelText: 'City'),
                ),
                TextField(
                  controller: stateController,
                  decoration: InputDecoration(labelText: 'State'),
                ),
                TextField(
                  controller: postalCodeController,
                  decoration: InputDecoration(labelText: 'Postal Code'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: phoneNumberController,
                  decoration: InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newAddress = Address(
                  id: address?.id ?? Uuid().v4(),
                  name: nameController.text,
                  street: streetController.text,
                  city: cityController.text,
                  state: stateController.text,
                  postalCode: postalCodeController.text,
                  phoneNumber: phoneNumberController.text,
                );
                final addressProvider = Provider.of<AddressProvider>(
                  context,
                  listen: false,
                );
                if (address == null) {
                  addressProvider.addAddress(newAddress);
                } else {
                  addressProvider.updateAddress(address.id, newAddress);
                }
                Navigator.pop(context);
              },
              child: Text(address == null ? 'Add' : 'Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('Manage Addresses'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AddressProvider>(
        builder: (context, addressProvider, child) {
          return addressProvider.addresses.isEmpty
              ? Center(child: Text('No addresses added yet.'))
              : ListView.builder(
                padding: EdgeInsets.all(16.0),
                itemCount: addressProvider.addresses.length,
                itemBuilder: (context, index) {
                  final address = addressProvider.addresses[index];
                  final isSelected =
                      addressProvider.selectedShippingAddress?.id == address.id;
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  address.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Selected',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${address.street}, ${address.city}, ${address.state} - ${address.postalCode}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Phone: ${address.phoneNumber}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  color: Colors.blue.shade600,
                                ),
                                onPressed:
                                    () => _showAddressForm(
                                      context,
                                      address: address,
                                    ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () {
                                  addressProvider.deleteAddress(address.id);
                                },
                              ),
                              if (!isSelected)
                                TextButton(
                                  onPressed: () {
                                    addressProvider.selectShippingAddress(
                                      address.id,
                                    );
                                  },
                                  child: Text(
                                    'Select for Shipping',
                                    style: TextStyle(
                                      color: Colors.blue.shade600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade600,
        onPressed: () => _showAddressForm(context),
        child: Icon(Icons.add),
      ),
    );
  }
}
