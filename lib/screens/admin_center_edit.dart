import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const _kCurrency = '₺';

class AdminCenterEditScreen extends StatefulWidget {
  final String centerId;

  const AdminCenterEditScreen({super.key, required this.centerId});

  @override
  State<AdminCenterEditScreen> createState() => _AdminCenterEditScreenState();
}

class _AdminCenterEditScreenState extends State<AdminCenterEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _centerData;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _managerNameController = TextEditingController();
  final TextEditingController _managerEmailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCenterData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _managerNameController.dispose();
    _managerEmailController.dispose();
    super.dispose();
  }

  Future<void> _loadCenterData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('centers')
          .doc(widget.centerId)
          .get();

      if (doc.exists) {
        setState(() {
          _centerData = doc.data()!;
          _nameController.text = _centerData!['name'] ?? '';
          _locationController.text = _centerData!['location'] ?? '';
          _managerNameController.text = _centerData!['managerName'] ?? '';
          _managerEmailController.text = _centerData!['managerEmail'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Center not found')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading center: $e')),
      );
    }
  }

  Future<void> _saveCenter() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('centers')
          .doc(widget.centerId)
          .update({
        'name': _nameController.text.trim(),
        'location': _locationController.text.trim(),
        'managerName': _managerNameController.text.trim(),
        'managerEmail': _managerEmailController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Center updated successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating center: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showBulkStockDialog() {
    showDialog(
      context: context,
      builder: (context) => const _BulkStockDialog(),
    );
  }

  void _addCard() {
    showDialog(
      context: context,
      builder: (context) => const _AddCardDialog(),
    ).then((result) {
      if (result != null && result is Map<String, dynamic>) {
        _saveCard(result);
      }
    });
  }

  Future<void> _saveCard(Map<String, dynamic> cardData) async {
    try {
      await FirebaseFirestore.instance
          .collection('centers')
          .doc(widget.centerId)
          .collection('cards')
          .add({
        ...cardData,
        'stock': cardData['stock'] ?? 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Card added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding card: $e')),
      );
    }
  }

  Future<void> _deleteCard(String cardId) async {
    try {
      await FirebaseFirestore.instance
          .collection('centers')
          .doc(widget.centerId)
          .collection('cards')
          .doc(cardId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Card deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting card: $e')),
      );
    }
  }

  Future<void> _updateStock(String cardId, int newStock) async {
    if (newStock < 0) return;

    try {
      await FirebaseFirestore.instance
          .collection('centers')
          .doc(widget.centerId)
          .collection('cards')
          .doc(cardId)
          .update({'stock': newStock});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stock updated to $newStock')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating stock: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Center'),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveCenter,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      title: 'Center Information',
                      icon: Icons.storefront,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Center Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Center name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'Location',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Location is required';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Manager Information',
                      icon: Icons.person,
                      children: [
                        TextFormField(
                          controller: _managerNameController,
                          decoration: const InputDecoration(
                            labelText: 'Manager Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Manager name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _managerEmailController,
                          decoration: const InputDecoration(
                            labelText: 'Manager Email',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Manager email is required';
                            }
                            final emailRegex = RegExp(
                              r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$',
                            );
                            if (!emailRegex.hasMatch(value.trim())) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'WiFi Cards Management',
                      icon: Icons.wifi,
                      children: [
                        const Text(
                          'Manage WiFi cards available at this center and track inventory stock levels.',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _addCard,
                          icon: const Icon(Icons.add),
                          label: const Text('Add WiFi Card'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _showBulkStockDialog,
                          icon: const Icon(Icons.inventory),
                          label: const Text('Bulk Stock Update'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // TODO: Add list of existing cards
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('centers')
                              .doc(widget.centerId)
                              .collection('cards')
                              .orderBy('createdAt', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            }

                            final cards = snapshot.data?.docs ?? [];

                            if (cards.isEmpty) {
                              return const Text(
                                'No cards configured yet',
                                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                              );
                            }

                            return Column(
                              children: cards.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final stock = data['stock'] ?? 0;
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text(data['name'] ?? 'Unknown'),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('$_kCurrency${data['price'] ?? 0}'),
                                        Text(
                                          'Stock: $stock',
                                          style: TextStyle(
                                            color: stock == 0
                                                ? Colors.red
                                                : stock < 10
                                                    ? Colors.orange
                                                    : Colors.green,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.add_circle, color: Colors.green),
                                          tooltip: 'Add to Stock',
                                          onPressed: () => _updateStock(doc.id, stock + 1),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle, color: Colors.orange),
                                          tooltip: 'Remove from Stock',
                                          onPressed: stock > 0 ? () => _updateStock(doc.id, stock - 1) : null,
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          tooltip: 'Delete Card',
                                          onPressed: () => _deleteCard(doc.id),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _AddCardDialog extends StatefulWidget {
  const _AddCardDialog();

  @override
  State<_AddCardDialog> createState() => _AddCardDialogState();
}

class _AddCardDialogState extends State<_AddCardDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController(text: '0');

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add WiFi Card'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Card Name (e.g., 5 GB)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Card name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: 'Price ($_kCurrency)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Price is required';
                }
                final price = double.tryParse(value.trim());
                if (price == null || price <= 0) {
                  return 'Enter a valid price';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stockController,
              decoration: const InputDecoration(
                labelText: 'Initial Stock',
                border: OutlineInputBorder(),
                hintText: 'Number of cards in stock',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Stock is required';
                }
                final stock = int.tryParse(value.trim());
                if (stock == null || stock < 0) {
                  return 'Enter a valid stock quantity';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final cardData = {
                'name': _nameController.text.trim(),
                'price': double.parse(_priceController.text.trim()),
                'stock': int.parse(_stockController.text.trim()),
              };
              Navigator.pop(context, cardData);
            }
          },
          child: const Text('Add Card'),
        ),
      ],
    );
  }
}

class _BulkStockDialog extends StatefulWidget {
  const _BulkStockDialog();

  @override
  State<_BulkStockDialog> createState() => _BulkStockDialogState();
}

class _BulkStockDialogState extends State<_BulkStockDialog> {
  final Map<String, TextEditingController> _controllers = {};
  List<QueryDocumentSnapshot>? _cards;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCards() async {
    try {
      final centerId = (context.findAncestorStateOfType<_AdminCenterEditScreenState>()!).widget.centerId;
      final snapshot = await FirebaseFirestore.instance
          .collection('centers')
          .doc(centerId)
          .collection('cards')
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _cards = snapshot.docs;
        for (final card in _cards!) {
          final data = card.data() as Map<String, dynamic>;
          _controllers[card.id] = TextEditingController(
            text: (data['stock'] ?? 0).toString(),
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading cards: $e')),
      );
    }
  }

  Future<void> _updateAllStocks() async {
    final centerId = (context.findAncestorStateOfType<_AdminCenterEditScreenState>()!).widget.centerId;

    try {
      final batch = FirebaseFirestore.instance.batch();

      for (final card in _cards!) {
        final newStock = int.tryParse(_controllers[card.id]?.text ?? '0') ?? 0;
        final cardRef = FirebaseFirestore.instance
            .collection('centers')
            .doc(centerId)
            .collection('cards')
            .doc(card.id);

        batch.update(cardRef, {'stock': newStock});
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All stock levels updated successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating stocks: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bulk Stock Update'),
      content: _cards == null
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : _cards!.isEmpty
              ? const Text('No cards available to update stock.')
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _cards!.length,
                    itemBuilder: (context, index) {
                      final card = _cards![index];
                      final data = card.data() as Map<String, dynamic>;
                      final controller = _controllers[card.id]!;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['name'] ?? 'Unknown',
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    '$_kCurrency${data['price'] ?? 0}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 80,
                              child: TextFormField(
                                controller: controller,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (_cards != null && _cards!.isNotEmpty)
          ElevatedButton(
            onPressed: _updateAllStocks,
            child: const Text('Update All'),
          ),
      ],
    );
  }
}
