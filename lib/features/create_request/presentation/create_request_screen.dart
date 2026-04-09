import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../models/request_item.dart';
import '../providers/create_request_provider.dart';
import 'select_destination_screen.dart';
import 'widgets/address_autocomplete_field.dart';

class CreateRequestScreen extends ConsumerStatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  ConsumerState<CreateRequestScreen> createState() =>
      _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  final _budgetController = TextEditingController();
  final _notesController = TextEditingController();
  late double _deliveryLatitude;
  late double _deliveryLongitude;
  late String _deliveryAddress;

  @override
  void initState() {
    super.initState();
    _deliveryLatitude = 0.0;
    _deliveryLongitude = 0.0;
    _deliveryAddress = '';
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatAmount(double amount) {
    if (amount <= 0) return '₦0.00';
    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '₦$formatted';
  }

  void _openAddItemSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => _AddItemSheet(
            onAdd: (name, unit, description, price) {
              ref
                  .read(createRequestProvider.notifier)
                  .addItemWithDetails(
                    name: name,
                    unit: unit,
                    description: description,
                    price: price,
                  );
            },
          ),
    );
  }

  void _submit() {
    if (_deliveryLatitude == 0 || _deliveryLongitude == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a delivery address from the suggestions.'),
        ),
      );
      return;
    }
    final budget = double.tryParse(_budgetController.text.trim()) ?? 0.0;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) => SelectDestinationScreen(
              budget: budget,
              deliveryAddress: _deliveryAddress,
              deliveryLatitude: _deliveryLatitude,
              deliveryLongitude: _deliveryLongitude,
              deliveryNotes: _notesController.text.trim(),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createRequestProvider);
    final notifier = ref.read(createRequestProvider.notifier);

    // Auto-populate budget from items total
    ref.listen(createRequestProvider.select((s) => s.itemsTotal), (_, total) {
      setState(() {
        _budgetController.text = total > 0 ? total.toStringAsFixed(0) : '';
      });
    });

    final budgetAmount = double.tryParse(_budgetController.text.trim()) ?? 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2EF),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            _Header(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _MarketTypeSection(
                      selected: state.marketType,
                      onSelect: notifier.setMarketType,
                    ),
                    const SizedBox(height: 28),
                    _ShoppingListSection(
                      items: state.items,
                      onAddItem: _openAddItemSheet,
                      onRemove: notifier.removeItem,
                      onDecrement: notifier.decrementQuantity,
                      onIncrement: notifier.incrementQuantity,
                    ),
                    const SizedBox(height: 28),
                    _BudgetSection(
                      budgetController: _budgetController,
                      isFlexible: state.isFlexible,
                      onToggleFlexible: notifier.toggleFlexible,
                      onBudgetChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 28),
                    AddressAutocompleteField(
                      onAddressSelected: (address, lat, lng) {
                        setState(() {
                          _deliveryAddress = address;
                          _deliveryLatitude = lat;
                          _deliveryLongitude = lng;
                        });
                      },
                    ),
                    const SizedBox(height: 28),
                    _DeliveryNotesSection(controller: _notesController),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _BottomBar(
              estimatedTotal: _formatAmount(budgetAmount),
              isSubmitting: state.isSubmitting,
              onSubmit: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// HEADER
// ===========================================================================
class _Header extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const Expanded(
            child: Text(
              'New Order',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 38),
        ],
      ),
    );
  }
}

// ===========================================================================
// MARKET TYPE SECTION
// ===========================================================================
class _MarketTypeSection extends StatelessWidget {
  const _MarketTypeSection({required this.selected, required this.onSelect});

  final MarketType selected;
  final ValueChanged<MarketType> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Market Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF202123),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MarketTypeCard(
                label: 'Supermarket',
                icon: Icons.storefront_rounded,
                isSelected: selected == MarketType.supermarket,
                onTap: () => onSelect(MarketType.supermarket),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _MarketTypeCard(
                label: 'Local Market',
                icon: Icons.shopping_bag_outlined,
                isSelected: selected == MarketType.openMarket,
                onTap: () => onSelect(MarketType.openMarket),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MarketTypeCard extends StatelessWidget {
  const _MarketTypeCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 100,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFFE8EAE7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 32,
                    color:
                        isSelected
                            ? AppColors.primary
                            : const Color(0xFF9A9C97),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color:
                          isSelected
                              ? const Color(0xFF202123)
                              : const Color(0xFF9A9C97),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// SHOPPING LIST SECTION
// ===========================================================================
class _ShoppingListSection extends StatelessWidget {
  const _ShoppingListSection({
    required this.items,
    required this.onAddItem,
    required this.onRemove,
    required this.onDecrement,
    required this.onIncrement,
  });

  final List<RequestItem> items;
  final VoidCallback onAddItem;
  final ValueChanged<String> onRemove;
  final ValueChanged<String> onDecrement;
  final ValueChanged<String> onIncrement;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Shopping List',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF202123),
              ),
            ),
            const Spacer(),
            if (items.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD7EDDB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${items.length} ITEM${items.length == 1 ? '' : 'S'}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (items.isEmpty)
          Container(
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Text(
              'No items added yet',
              style: TextStyle(fontSize: 13, color: Color(0xFFB0B2AD)),
            ),
          )
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ItemCard(
                item: item,
                onRemove: () => onRemove(item.id),
                onDecrement: () => onDecrement(item.id),
                onIncrement: () => onIncrement(item.id),
              ),
            ),
          ),
        const SizedBox(height: 10),
        _AddItemButton(onTap: onAddItem),
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.onRemove,
    required this.onDecrement,
    required this.onIncrement,
  });

  final RequestItem item;
  final VoidCallback onRemove;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202123),
                  ),
                ),
                if (item.unit.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.unit,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9A9C97),
                    ),
                  ),
                ],
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFB0B2AD),
                    ),
                  ),
                ],
                if (item.price > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '₦${item.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2EF),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StepperBtn(icon: Icons.remove, onTap: onDecrement),
                SizedBox(
                  width: 28,
                  child: Text(
                    '${item.quantity}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF202123),
                    ),
                  ),
                ),
                _StepperBtn(icon: Icons.add, onTap: onIncrement),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 18,
              color: Color(0xFFB0B2AD),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperBtn extends StatelessWidget {
  const _StepperBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Icon(icon, size: 18, color: const Color(0xFF5A5C56)),
      ),
    );
  }
}

class _AddItemButton extends StatelessWidget {
  const _AddItemButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 52,
        child: CustomPaint(
          painter: _DashedBorderPainter(),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Add Item',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5A5C56),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFFB0B2AD)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    const radius = Radius.circular(14);

    final path =
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.width, size.height),
            radius,
          ),
        );

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ===========================================================================
// ADD ITEM BOTTOM SHEET
// ===========================================================================
class _AddItemSheet extends StatefulWidget {
  const _AddItemSheet({required this.onAdd});
  final void Function(
    String name,
    String unit,
    String description,
    double price,
  )
  onAdd;

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _nameCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _nameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _unitCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _nameFocus.requestFocus();
      return;
    }
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
    widget.onAdd(name, _unitCtrl.text.trim(), _descCtrl.text.trim(), price);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDE0DB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Add Item',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF202123),
            ),
          ),
          const SizedBox(height: 20),
          _SheetField(
            controller: _nameCtrl,
            focusNode: _nameFocus,
            label: 'Item name',
            hint: 'e.g., Fresh Plum Tomatoes',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          _SheetField(
            controller: _unitCtrl,
            label: 'Unit',
            hint: 'e.g., 1 Small Basket, 5kg Bag',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          _SheetField(
            controller: _descCtrl,
            label: 'Description (optional)',
            hint: 'e.g., Must be ripe, no bruises',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          _SheetField(
            controller: _priceCtrl,
            label: 'Amount (₦)',
            hint: 'e.g., 2500',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: GestureDetector(
              onTap: _submit,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(27),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Add to List',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    required this.label,
    required this.hint,
    this.focusNode,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9A9C97),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF4F5F3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFFB0B2AD),
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF202123),
            ),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// BUDGET SECTION
// ===========================================================================
class _BudgetSection extends StatelessWidget {
  const _BudgetSection({
    required this.budgetController,
    required this.isFlexible,
    required this.onToggleFlexible,
    required this.onBudgetChanged,
  });

  final TextEditingController budgetController;
  final bool isFlexible;
  final ValueChanged<bool> onToggleFlexible;
  final ValueChanged<String> onBudgetChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estimated Budget',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF202123),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFDEE0DC),
                  borderRadius: BorderRadius.circular(27),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 20),
                    const Text(
                      '₦',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF202123),
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: budgetController,
                        onChanged: onBudgetChanged,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textAlignVertical: TextAlignVertical.center,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '0.00',
                          hintStyle: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF9A9C97),
                          ),
                          contentPadding: EdgeInsets.only(right: 16),
                          isCollapsed: true,
                        ),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF202123),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Flexible',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF202123),
                  ),
                ),
                Switch.adaptive(
                  value: isFlexible,
                  onChanged: onToggleFlexible,
                  activeColor: Colors.white,
                  activeTrackColor: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ===========================================================================
// DELIVERY NOTES SECTION
// ===========================================================================
class _DeliveryNotesSection extends StatelessWidget {
  const _DeliveryNotesSection({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delivery Notes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF202123),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: controller,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'e.g., Call me before buying the meat...',
              hintStyle: TextStyle(color: Color(0xFFB0B2AD), fontSize: 14),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
            style: const TextStyle(fontSize: 14, color: Color(0xFF202123)),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// BOTTOM BAR
// ===========================================================================
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.estimatedTotal,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final String estimatedTotal;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2EF),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ESTIMATED TOTAL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF9A9C97),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                estimatedTotal,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: isSubmitting ? null : onSubmit,
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(27),
                ),
                alignment: Alignment.center,
                child:
                    isSubmitting
                        ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                        : const Text(
                          'Select Market/Store',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
