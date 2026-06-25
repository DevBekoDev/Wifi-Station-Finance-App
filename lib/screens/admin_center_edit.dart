import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const _kCurrency = '₺';

/// Shared theme tokens — keep in sync with the rest of the app.
class _T {
  static const bg = Color(0xFFF4FBF6);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFE8F5EC);
  static const border = Color(0xFFD5E8DA);
  static const border2 = Color(0xFFBED8C6);

  static const emerald = Color(0xFF0B6E63);
  static const emeraldD = Color(0xFFE4F4F1);

  static const amber = Color(0xFFE28A12);
  static const amberD = Color(0xFFFFF1DD);

  static const rose = Color(0xFFD85C63);
  static const roseD = Color(0xFFFFEBED);

  static const blue = Color(0xFF4B7BEC);
  static const blueD = Color(0xFFEAF1FF);

  static const violet = Color(0xFF8B7CF6);
  static const violetD = Color(0xFFF1EEFF);

  static const textPrimary = Color.fromARGB(255, 20, 44, 35);
  static const textSecondary = Color(0xFF567567);
  static const textMuted = Color(0xFF86A093);
}

// Stock thresholds — single source of truth so list, badges, and dialogs agree.
const int _kLowStockThreshold = 10;

enum _StockLevel { out, low, healthy }

_StockLevel _stockLevel(int stock) {
  if (stock == 0) return _StockLevel.out;
  if (stock < _kLowStockThreshold) return _StockLevel.low;
  return _StockLevel.healthy;
}

Color _stockColor(_StockLevel level) {
  switch (level) {
    case _StockLevel.out:
      return _T.rose;
    case _StockLevel.low:
      return _T.amber;
    case _StockLevel.healthy:
      return _T.emerald;
  }
}

Color _stockColorD(_StockLevel level) {
  switch (level) {
    case _StockLevel.out:
      return _T.roseD;
    case _StockLevel.low:
      return _T.amberD;
    case _StockLevel.healthy:
      return _T.emeraldD;
  }
}

String _stockLabel(_StockLevel level) {
  switch (level) {
    case _StockLevel.out:
      return 'Out of stock';
    case _StockLevel.low:
      return 'Low stock';
    case _StockLevel.healthy:
      return 'In stock';
  }
}

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
  bool _isDirty = false;
  Map<String, dynamic>? _centerData;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _managerNameController = TextEditingController();
  final TextEditingController _managerEmailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCenterData();
    for (final c in [
      _nameController,
      _locationController,
      _managerNameController,
      _managerEmailController,
    ]) {
      c.addListener(_markDirty);
    }
  }

  void _markDirty() {
    if (!_isDirty && !_isLoading) {
      setState(() => _isDirty = true);
    }
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
        setState(() => _isLoading = false);
        if (!mounted) return;
        _showSnack('Center not found', tone: _SnackTone.error);
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      _showSnack('Couldn\'t load this center. $e', tone: _SnackTone.error);
    }
  }

  Future<void> _saveCenter() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    HapticFeedback.lightImpact();

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

      if (!mounted) return;
      _showSnack('Center updated', tone: _SnackTone.success);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Couldn\'t save changes. $e', tone: _SnackTone.error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String message, {_SnackTone tone = _SnackTone.neutral}) {
    final colors = switch (tone) {
      _SnackTone.success => (_T.emerald, Icons.check_circle_rounded),
      _SnackTone.error => (_T.rose, Icons.error_rounded),
      _SnackTone.neutral => (_T.textPrimary, Icons.info_rounded),
    };
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.$1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
        content: Row(
          children: [
            Icon(colors.$2, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkStockDialog() {
    showDialog(
      context: context,
      builder: (context) => _BulkStockDialog(centerId: widget.centerId),
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

      if (!mounted) return;
      _showSnack('${cardData['name']} added', tone: _SnackTone.success);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Couldn\'t add the card. $e', tone: _SnackTone.error);
    }
  }

  Future<void> _confirmDeleteCard(String cardId, String cardName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _ConfirmDialog(
        title: 'Delete $cardName?',
        message:
            'This removes the card and its stock count permanently. This can\'t be undone.',
        confirmLabel: 'Delete',
        destructive: true,
      ),
    );
    if (confirmed == true) {
      _deleteCard(cardId, cardName);
    }
  }

  Future<void> _deleteCard(String cardId, String cardName) async {
    try {
      await FirebaseFirestore.instance
          .collection('centers')
          .doc(widget.centerId)
          .collection('cards')
          .doc(cardId)
          .delete();

      if (!mounted) return;
      _showSnack('$cardName deleted', tone: _SnackTone.neutral);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Couldn\'t delete the card. $e', tone: _SnackTone.error);
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
    } catch (e) {
      if (!mounted) return;
      _showSnack('Couldn\'t update stock. $e', tone: _SnackTone.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: _T.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _T.textPrimary,
        title: const Text(
          'Edit center',
          style: TextStyle(
            color: _T.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _SaveButton(
                isSaving: _isSaving,
                isDirty: _isDirty,
                onPressed: _saveCenter,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const _LoadingState()
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionCard(
                      title: 'Center information',
                      icon: Icons.storefront_rounded,
                      accent: _T.emerald,
                      accentD: _T.emeraldD,
                      children: [
                        _StyledField(
                          controller: _nameController,
                          label: 'Center name',
                          hint: 'e.g. Tokat Bus Terminal',
                          icon: Icons.badge_outlined,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Center name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _StyledField(
                          controller: _locationController,
                          label: 'Location',
                          hint: 'e.g. Gaziosmanpaşa Bulvarı No:12',
                          icon: Icons.place_outlined,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Location is required';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Manager information',
                      icon: Icons.person_rounded,
                      accent: _T.blue,
                      accentD: _T.blueD,
                      children: [
                        _StyledField(
                          controller: _managerNameController,
                          label: 'Manager name',
                          hint: 'Full name',
                          icon: Icons.person_outline_rounded,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Manager name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _StyledField(
                          controller: _managerEmailController,
                          label: 'Manager email',
                          hint: 'name@example.com',
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
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
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'WiFi cards',
                      icon: Icons.wifi_rounded,
                      accent: _T.violet,
                      accentD: _T.violetD,
                      trailing: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('centers')
                            .doc(widget.centerId)
                            .collection('cards')
                            .snapshots(),
                        builder: (context, snapshot) {
                          final count = snapshot.data?.docs.length ?? 0;
                          if (count == 0) return const SizedBox.shrink();
                          return _CountPill(count: count);
                        },
                      ),
                      children: [
                        const Text(
                          'Manage the WiFi cards sold at this center and keep stock levels accurate.',
                          style: TextStyle(
                            color: _T.textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _ActionButton(
                                label: 'Add card',
                                icon: Icons.add_rounded,
                                filled: true,
                                onPressed: _addCard,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ActionButton(
                                label: 'Bulk update',
                                icon: Icons.tune_rounded,
                                filled: false,
                                onPressed: _showBulkStockDialog,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('centers')
                              .doc(widget.centerId)
                              .collection('cards')
                              .orderBy('createdAt', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: _T.emerald,
                                    ),
                                  ),
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              return _InlineError(
                                message: 'Couldn\'t load cards: ${snapshot.error}',
                              );
                            }

                            final cards = snapshot.data?.docs ?? [];

                            if (cards.isEmpty) {
                              return const _EmptyCardsState();
                            }

                            return Column(
                              children: [
                                for (int i = 0; i < cards.length; i++) ...[
                                  if (i > 0) const SizedBox(height: 10),
                                  _CardTile(
                                    key: ValueKey(cards[i].id),
                                    doc: cards[i],
                                    onIncrement: (id, stock) =>
                                        _updateStock(id, stock + 1),
                                    onDecrement: (id, stock) =>
                                        _updateStock(id, stock - 1),
                                    onDelete: _confirmDeleteCard,
                                  ),
                                ],
                              ],
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
}

enum _SnackTone { success, error, neutral }

// ---------------------------------------------------------------------------
// Shared small widgets
// ---------------------------------------------------------------------------

class _SaveButton extends StatelessWidget {
  final bool isSaving;
  final bool isDirty;
  final VoidCallback onPressed;

  const _SaveButton({
    required this.isSaving,
    required this.isDirty,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isDirty || isSaving ? 1 : 0.55,
      child: TextButton(
        onPressed: isSaving ? null : onPressed,
        style: TextButton.styleFrom(
          backgroundColor: _T.emerald,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _T.emerald,
          disabledForegroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: isSaving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 2.6, color: _T.emerald),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final Color accentD;
  final List<Widget> children;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.accentD,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.border),
        boxShadow: [
          BoxShadow(
            color: _T.textPrimary.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accentD,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _T.textPrimary,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  final int count;
  const _CountPill({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: _T.surface2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _T.border2),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _T.textSecondary,
        ),
      ),
    );
  }
}

class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _StyledField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        color: _T.textPrimary,
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: _T.textMuted, fontSize: 13.5),
        labelStyle: const TextStyle(color: _T.textSecondary, fontSize: 13.5),
        floatingLabelStyle: const TextStyle(
          color: _T.emerald,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, size: 19, color: _T.textMuted),
        filled: true,
        fillColor: _T.bg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: _T.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: _T.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: _T.emerald, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: _T.rose),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: _T.rose, width: 1.6),
        ),
        errorStyle: const TextStyle(color: _T.rose, fontSize: 12),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    if (filled) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _T.emerald,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        child: child,
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: _T.emerald,
        backgroundColor: _T.emeraldD,
        side: const BorderSide(color: _T.border2),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
        ),
      ),
      child: child,
    );
  }
}

class _EmptyCardsState extends StatelessWidget {
  const _EmptyCardsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: _T.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _T.border, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _T.surface2,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sim_card_outlined,
                color: _T.textMuted, size: 22),
          ),
          const SizedBox(height: 10),
          const Text(
            'No cards yet',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _T.textPrimary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Add a WiFi card to start tracking stock for this center.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _T.textMuted, fontSize: 12.5, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _T.roseD,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _T.rose.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: _T.rose, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: _T.rose, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card tile (one WiFi card row)
// ---------------------------------------------------------------------------

class _CardTile extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final void Function(String id, int stock) onIncrement;
  final void Function(String id, int stock) onDecrement;
  final void Function(String id, String name) onDelete;

  const _CardTile({
    super.key,
    required this.doc,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final name = (data['name'] as String?)?.trim().isNotEmpty == true
        ? data['name'] as String
        : 'Unknown card';
    final price = data['price'] ?? 0;
    final stock = (data['stock'] ?? 0) as int;
    final level = _stockLevel(stock);
    final color = _stockColor(level);
    final colorD = _stockColorD(level);

    return Dismissible(
      key: ValueKey('dismiss-${doc.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete(doc.id, name);
        return false; // tile stays; deletion (if confirmed) updates via stream
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: _T.roseD,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: _T.rose),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _T.border),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: colorD,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.wifi_rounded, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _T.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        '$_kCurrency$price',
                        style: const TextStyle(
                          color: _T.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorD,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_stockLabel(level)} · $stock',
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _Stepper(
              stock: stock,
              onIncrement: () => onIncrement(doc.id, stock),
              onDecrement: () => onDecrement(doc.id, stock),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int stock;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _Stepper({
    required this.stock,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _T.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _T.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove_rounded,
            onPressed: stock > 0 ? onDecrement : null,
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 26),
            alignment: Alignment.center,
            child: Text(
              '$stock',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: _T.textPrimary,
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add_rounded,
            onPressed: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _StepperButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(
            icon,
            size: 16,
            color: enabled ? _T.emerald : _T.textMuted.withOpacity(0.4),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add card dialog
// ---------------------------------------------------------------------------

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
    return _StyledDialog(
      icon: Icons.wifi_rounded,
      accent: _T.violet,
      accentD: _T.violetD,
      title: 'Add WiFi card',
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StyledField(
              controller: _nameController,
              label: 'Card name',
              hint: 'e.g. 5 GB',
              icon: Icons.sell_outlined,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Card name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _StyledField(
              controller: _priceController,
              label: 'Price ($_kCurrency)',
              hint: '0.00',
              icon: Icons.payments_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
            const SizedBox(height: 12),
            _StyledField(
              controller: _stockController,
              label: 'Initial stock',
              hint: 'Number of cards in stock',
              icon: Icons.inventory_2_outlined,
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
        _DialogTextAction(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        _DialogFilledAction(
          label: 'Add card',
          color: _T.emerald,
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
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bulk stock dialog
// ---------------------------------------------------------------------------

class _BulkStockDialog extends StatefulWidget {
  final String centerId;
  const _BulkStockDialog({required this.centerId});

  @override
  State<_BulkStockDialog> createState() => _BulkStockDialogState();
}

class _BulkStockDialogState extends State<_BulkStockDialog> {
  final Map<String, TextEditingController> _controllers = {};
  List<QueryDocumentSnapshot>? _cards;
  bool _isSaving = false;

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
      final snapshot = await FirebaseFirestore.instance
          .collection('centers')
          .doc(widget.centerId)
          .collection('cards')
          .orderBy('createdAt', descending: true)
          .get();

      if (!mounted) return;
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading cards: $e')),
      );
    }
  }

  Future<void> _updateAllStocks() async {
    setState(() => _isSaving = true);
    try {
      final batch = FirebaseFirestore.instance.batch();

      for (final card in _cards!) {
        final newStock = int.tryParse(_controllers[card.id]?.text ?? '0') ?? 0;
        final cardRef = FirebaseFirestore.instance
            .collection('centers')
            .doc(widget.centerId)
            .collection('cards')
            .doc(card.id);

        batch.update(cardRef, {'stock': newStock < 0 ? 0 : newStock});
      }

      await batch.commit();

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All stock levels updated')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating stocks: $e')),
      );
    }
  }

  void _bump(String cardId, int delta) {
    final controller = _controllers[cardId];
    if (controller == null) return;
    final current = int.tryParse(controller.text) ?? 0;
    final next = (current + delta).clamp(0, 999999);
    controller.text = '$next';
  }

  @override
  Widget build(BuildContext context) {
    return _StyledDialog(
      icon: Icons.tune_rounded,
      accent: _T.emerald,
      accentD: _T.emeraldD,
      title: 'Bulk stock update',
      subtitle: 'Adjust quantities, then apply all changes at once.',
      content: _cards == null
          ? const SizedBox(
              height: 100,
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: _T.emerald,
                  ),
                ),
              ),
            )
          : _cards!.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No cards available to update yet.',
                    style: TextStyle(color: _T.textMuted, fontSize: 13),
                  ),
                )
              : SizedBox(
                  width: double.maxFinite,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 360),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _cards!.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 20,
                        color: _T.border,
                      ),
                      itemBuilder: (context, index) {
                        final card = _cards![index];
                        final data = card.data() as Map<String, dynamic>;
                        final controller = _controllers[card.id]!;

                        return Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['name'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                      color: _T.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$_kCurrency${data['price'] ?? 0}',
                                    style: const TextStyle(
                                      color: _T.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            _StepperButton(
                              icon: Icons.remove_rounded,
                              onPressed: () => setState(() => _bump(card.id, -1)),
                            ),
                            SizedBox(
                              width: 52,
                              child: TextFormField(
                                controller: controller,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: _T.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  filled: true,
                                  fillColor: _T.bg,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: _T.border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: _T.border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: _T.emerald, width: 1.4),
                                  ),
                                ),
                              ),
                            ),
                            _StepperButton(
                              icon: Icons.add_rounded,
                              onPressed: () => setState(() => _bump(card.id, 1)),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
      actions: [
        _DialogTextAction(
          label: 'Cancel',
          onPressed: _isSaving ? null : () => Navigator.pop(context),
        ),
        if (_cards != null && _cards!.isNotEmpty)
          _DialogFilledAction(
            label: 'Update all',
            color: _T.emerald,
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _updateAllStocks,
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Confirm dialog (used for delete)
// ---------------------------------------------------------------------------

class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final bool destructive;

  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? _T.rose : _T.emerald;
    final colorD = destructive ? _T.roseD : _T.emeraldD;

    return _StyledDialog(
      icon: destructive ? Icons.delete_outline_rounded : Icons.help_outline_rounded,
      accent: color,
      accentD: colorD,
      title: title,
      content: Text(
        message,
        style: const TextStyle(color: _T.textSecondary, fontSize: 13.5, height: 1.45),
      ),
      actions: [
        _DialogTextAction(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context, false),
        ),
        _DialogFilledAction(
          label: confirmLabel,
          color: color,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Dialog shell + actions
// ---------------------------------------------------------------------------

class _StyledDialog extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final Color accentD;
  final String title;
  final String? subtitle;
  final Widget content;
  final List<Widget> actions;

  const _StyledDialog({
    required this.icon,
    required this.accent,
    required this.accentD,
    required this.title,
    required this.content,
    required this.actions,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _T.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accentD,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: accent, size: 19),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: _T.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: const TextStyle(color: _T.textMuted, fontSize: 12.5),
                ),
              ],
              const SizedBox(height: 18),
              content,
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions
                    .expand((a) => [a, const SizedBox(width: 8)])
                    .toList()
                  ..removeLast(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogTextAction extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _DialogTextAction({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: _T.textSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
    );
  }
}

class _DialogFilledAction extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _DialogFilledAction({
    required this.label,
    required this.color,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: color.withOpacity(0.6),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      child: isLoading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
    );
  }
}