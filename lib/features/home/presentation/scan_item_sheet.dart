import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../models/home_models.dart';
import '../providers/home_provider.dart';
import '../../shared/data/swift_shopper_repository.dart';

// ---------------------------------------------------------------------------
// Entry point — call this to open the sheet
// ---------------------------------------------------------------------------
Future<bool> showScanItemSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String orderId,
  required ActiveJobItem item,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ScanItemSheet(orderId: orderId, item: item),
  );
  return result == true;
}

// ---------------------------------------------------------------------------
// Bottom sheet widget
// ---------------------------------------------------------------------------
class _ScanItemSheet extends ConsumerStatefulWidget {
  const _ScanItemSheet({required this.orderId, required this.item});

  final String orderId;
  final ActiveJobItem item;

  @override
  ConsumerState<_ScanItemSheet> createState() => _ScanItemSheetState();
}

class _ScanItemSheetState extends ConsumerState<_ScanItemSheet> {
  final _priceController = TextEditingController();
  File? _photo;
  bool _saving = false;
  String? _error;

  // 0=Pending, 1=Found, 2=Unavailable
  int _status = 1;

  @override
  void initState() {
    super.initState();
    _status = widget.item.status == 2 ? 2 : 1;
    final existing = widget.item.foundPrice ?? widget.item.estimatedPrice;
    if (existing > 0) {
      _priceController.text = existing.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1080,
    );
    if (xfile != null) {
      setState(() => _photo = File(xfile.path));
    }
  }

  Future<void> _save() async {
    final priceText = _priceController.text.trim();
    if (_status == 1 && priceText.isEmpty) {
      setState(() => _error = 'Please enter the actual price');
      return;
    }

    final foundPrice =
        priceText.isNotEmpty ? double.tryParse(priceText) : null;

    if (_status == 1 && foundPrice == null) {
      setState(() => _error = 'Enter a valid price');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repo = ref.read(swiftShopperRepositoryProvider);

      // Upload photo first if one was taken
      String? photoUrl = widget.item.photoUrl;
      if (_photo != null) {
        final bytes = await _photo!.readAsBytes();
        photoUrl = await repo.uploadItemPhoto(
          bytes: bytes,
          fileName: 'item_${widget.item.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      await repo.updateOrderItem(
        orderId: widget.orderId,
        itemId: widget.item.id,
        status: _status,
        foundPrice: foundPrice,
        photoUrl: photoUrl,
      );

      // Refresh the active job
      ref.invalidate(activeJobProvider);

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    final isFound = _status == 1;
    final isUnavailable = _status == 2;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      // Let the sheet resize when the keyboard appears
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle ─────────────────────────────────────────────────────
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Item name + est. price ──────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.name,
                        style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800,
                          color: Color(0xFF0D1512),
                        ),
                      ),
                      if (widget.item.description.isNotEmpty ||
                          widget.item.unit.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (widget.item.description.isNotEmpty)
                              widget.item.description,
                            if (widget.item.unit.isNotEmpty)
                              '${widget.item.quantity} ${widget.item.unit}',
                          ].join(' • '),
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF9A9C97)),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.item.estimatedPrice > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0EE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Est. ₦${_fmt(widget.item.estimatedPrice)}',
                      style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: Color(0xFF9A9C97),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Status toggle ───────────────────────────────────────────────
            const Text(
              'STATUS',
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: Color(0xFF9A9C97), letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _StatusChip(
                  label: 'Found',
                  icon: Icons.check_circle_rounded,
                  selected: isFound,
                  color: AppColors.primary,
                  onTap: () => setState(() => _status = 1),
                ),
                const SizedBox(width: 10),
                _StatusChip(
                  label: 'Unavailable',
                  icon: Icons.block_rounded,
                  selected: isUnavailable,
                  color: const Color(0xFFE53935),
                  onTap: () => setState(() => _status = 2),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Price field (only when Found) ───────────────────────────────
            if (isFound) ...[
              const Text(
                'ACTUAL PRICE (₦)',
                style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: Color(0xFF9A9C97), letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: false),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800,
                  color: Color(0xFF0D1512),
                ),
                decoration: InputDecoration(
                  prefixText: '₦  ',
                  prefixStyle: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600,
                    color: Color(0xFF9A9C97),
                  ),
                  hintText: '0',
                  hintStyle: const TextStyle(
                    fontSize: 22, color: Color(0xFFCCCCCC),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF6F6F4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: 20),
            ],

            // ── Photo section ───────────────────────────────────────────────
            const Text(
              'ITEM PHOTO',
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: Color(0xFF9A9C97), letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Preview box
                GestureDetector(
                  onTap: () => _pickPhoto(ImageSource.camera),
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0EE),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFE0E0E0), width: 1.5,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _photo != null
                        ? Image.file(_photo!, fit: BoxFit.cover)
                        : widget.item.photoUrl != null
                            ? Image.network(
                                widget.item.photoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _photoIcon(),
                              )
                            : _photoIcon(),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PhotoButton(
                      icon: Icons.camera_alt_rounded,
                      label: 'Take Photo',
                      onTap: () => _pickPhoto(ImageSource.camera),
                    ),
                    const SizedBox(height: 8),
                    _PhotoButton(
                      icon: Icons.photo_library_rounded,
                      label: 'Choose from Gallery',
                      onTap: () => _pickPhoto(ImageSource.gallery),
                    ),
                  ],
                ),
              ],
            ),

            // ── Error message ───────────────────────────────────────────────
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Color(0xFFE53935), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 13, color: Color(0xFFE53935),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── Save button ─────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isUnavailable
                      ? const Color(0xFFE53935)
                      : AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        isUnavailable ? 'Mark Unavailable' : 'Mark as Found',
                        style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _photoIcon() {
    return const Center(
      child: Icon(Icons.add_a_photo_rounded,
          color: Color(0xFFB0B0B0), size: 28),
    );
  }
}

// ---------------------------------------------------------------------------
// Small reusable widgets
// ---------------------------------------------------------------------------
class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : const Color(0xFFF6F6F4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : const Color(0xFFE0E0E0),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 18,
                color: selected ? color : const Color(0xFFB0B0B0)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: selected ? color : const Color(0xFFB0B0B0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoButton extends StatelessWidget {
  const _PhotoButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F6F4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: Color(0xFF0D1512),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
