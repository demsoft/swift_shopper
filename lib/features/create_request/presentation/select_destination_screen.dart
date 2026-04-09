import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/theme/app_colors.dart';
import '../../home/models/home_models.dart';
import '../../home/providers/home_provider.dart';
import '../providers/create_request_provider.dart';
import 'review_request_screen.dart';

class SelectDestinationScreen extends ConsumerStatefulWidget {
  const SelectDestinationScreen({
    super.key,
    required this.budget,
    required this.deliveryAddress,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    required this.deliveryNotes,
  });

  final double budget;
  final String deliveryAddress;
  final double deliveryLatitude;
  final double deliveryLongitude;
  final String deliveryNotes;

  @override
  ConsumerState<SelectDestinationScreen> createState() =>
      _SelectDestinationScreenState();
}

class _SelectDestinationScreenState
    extends ConsumerState<SelectDestinationScreen> {
  int _selectedIndex = 0;
  bool _isGeocoding = false;

  Future<({double lat, double lng})?> _geocodeAddress(String query) async {
    try {
      final url =
          'https://photon.komoot.io/api/?q=${Uri.encodeQueryComponent(query)}&limit=1&lang=en&bbox=2.6769,4.2725,14.6801,13.8856';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final features = json['features'] as List<dynamic>? ?? [];
        if (features.isNotEmpty) {
          final coords = features[0]['geometry']?['coordinates'] as List<dynamic>?;
          final lng = (coords?[0] as num?)?.toDouble();
          final lat = (coords?[1] as num?)?.toDouble();
          if (lat != null && lng != null) return (lat: lat, lng: lng);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _confirmSelection(List<MarketData> markets) async {
    if (markets.isEmpty) return;
    final market = markets[_selectedIndex];

    double? marketLat = market.latitude;
    double? marketLng = market.longitude;

    if (marketLat == null || marketLng == null) {
      setState(() => _isGeocoding = true);
      final coords = await _geocodeAddress('${market.name}, ${market.address}');
      marketLat = coords?.lat;
      marketLng = coords?.lng;
      if (mounted) setState(() => _isGeocoding = false);
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReviewRequestScreen(
          budget: widget.budget,
          deliveryAddress: widget.deliveryAddress,
          deliveryLatitude: widget.deliveryLatitude,
          deliveryLongitude: widget.deliveryLongitude,
          deliveryNotes: widget.deliveryNotes,
          storeName: market.name,
          storeLocation: market.address,
          storeImagePath: market.photoUrl,
          marketLatitude: marketLat,
          marketLongitude: marketLng,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(createRequestProvider).isSubmitting;
    final marketType = ref.watch(createRequestProvider).marketType;
    final marketsAsync = marketType == MarketType.supermarket
        ? ref.watch(supermarketsProvider)
        : ref.watch(openMarketsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F4),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: marketsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded,
                          size: 48, color: AppColors.textSecondary),
                      const SizedBox(height: 12),
                      Text(
                        e.toString(),
                        style: const TextStyle(
                            color: Colors.red, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          ref.invalidate(supermarketsProvider);
                          ref.invalidate(openMarketsProvider);
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (markets) {
                  if (markets.isEmpty) {
                    return const Center(
                      child: Text(
                        'No markets available yet.\nCheck back soon.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 15),
                      ),
                    );
                  }
                  // clamp selected index in case list shrank
                  if (_selectedIndex >= markets.length) {
                    _selectedIndex = 0;
                  }
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        const Text(
                          'Select\nDestination',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0D1512),
                            height: 1.05,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Choose a ${marketType == MarketType.supermarket ? 'supermarket' : 'open market'} near you.',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF7A7C77),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),
                        ...List.generate(markets.length, (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _StoreCard(
                            market: markets[i],
                            isSelected: _selectedIndex == i,
                            onTap: () => setState(() => _selectedIndex = i),
                          ),
                        )),
                      ],
                    ),
                  );
                },
              ),
            ),
            marketsAsync.whenData((markets) => markets).valueOrNull?.isNotEmpty == true
                ? _buildBottomButton(
                    isSubmitting,
                    marketsAsync.valueOrNull ?? [],
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
        ],
      ),
    );
  }

  Widget _buildBottomButton(bool isSubmitting, List<MarketData> markets) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: (isSubmitting || _isGeocoding) ? null : () => _confirmSelection(markets),
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(29),
          ),
          alignment: Alignment.center,
          child: (isSubmitting || _isGeocoding)
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Next: Review Request',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 10),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Store card
// ---------------------------------------------------------------------------
class _StoreCard extends StatelessWidget {
  const _StoreCard({
    required this.market,
    required this.isSelected,
    required this.onTap,
  });

  final MarketData market;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Market image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(18),
              ),
              child: SizedBox(
                width: 120,
                height: 150,
                child: market.photoUrl != null && market.photoUrl!.isNotEmpty
                    ? Image.network(
                        market.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _ImagePlaceholder(),
                      )
                    : _ImagePlaceholder(),
              ),
            ),
            // Market details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      market.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D1512),
                        height: 1.25,
                      ),
                    ),
                    if (market.address.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        market.address,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9A9C97),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (market.categories.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: market.categories.take(2).map((cat) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F4EA),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              cat,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 13, color: Color(0xFF9A9C97)),
                        const SizedBox(width: 4),
                        Text(
                          'Open ${market.openingTime} – ${market.closingTime}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9A9C97),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFD5DAD4),
      child: const Icon(
        Icons.storefront_rounded,
        color: Color(0xFF9A9C97),
        size: 36,
      ),
    );
  }
}
