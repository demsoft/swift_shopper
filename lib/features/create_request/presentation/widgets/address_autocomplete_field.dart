import 'dart:math';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/places/place_result.dart';
import '../../../../core/places/places_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/debounce.dart';

enum _FieldState { idle, tooShort, loading, results, noResults, error }

class AddressAutocompleteField extends ConsumerStatefulWidget {
  const AddressAutocompleteField({
    super.key,
    required this.onAddressSelected,
    this.onPlaceSelected,
    this.initialValue = '',
  });

  final void Function(String address, double lat, double lng) onAddressSelected;
  final void Function(PlaceResult place)? onPlaceSelected;
  final String initialValue;

  @override
  ConsumerState<AddressAutocompleteField> createState() =>
      _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState
    extends ConsumerState<AddressAutocompleteField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final Debouncer _debouncer;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  _FieldState _fieldState = _FieldState.idle;
  List<PlacePrediction> _predictions = [];
  List<PlacePrediction> _lastCachedPredictions = [];
  String? _sessionToken;
  bool _suppressSearch = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode()..addListener(_onFocusChanged);
    _debouncer = Debouncer(delay: const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    _removeOverlay();
    _debouncer.dispose();
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOrUpdateOverlay() {
    if (_overlayEntry == null) {
      _overlayEntry = OverlayEntry(
        builder: (_) => _DropdownOverlay(
          layerLink: _layerLink,
          predictions: _predictions,
          onSelect: _selectPrediction,
        ),
      );
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _overlayEntry!.markNeedsBuild();
    }
  }

  String _generateSessionToken() {
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    return base64UrlEncode(bytes);
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _sessionToken ??= _generateSessionToken();
    } else {
      if (mounted) {
        setState(() {
          _fieldState = _FieldState.idle;
          _predictions = [];
        });
        _removeOverlay();
      }
    }
  }

  void _onTextChanged(String value) {
    if (_suppressSearch) return;

    widget.onAddressSelected(value.trim(), 0.0, 0.0);

    final trimmed = value.trim();
    if (trimmed.length < 3) {
      _debouncer.cancel();
      setState(() {
        _fieldState =
            trimmed.isEmpty ? _FieldState.idle : _FieldState.tooShort;
        _predictions = [];
      });
      _removeOverlay();
      return;
    }

    setState(() => _fieldState = _FieldState.loading);
    _debouncer.run(() => _fetchPredictions(trimmed));
  }

  Future<void> _fetchPredictions(String query) async {
    _sessionToken ??= _generateSessionToken();
    final token = _sessionToken!;
    final service = ref.read(placesServiceProvider);

    final results = await service.getAutocomplete(query, token);

    if (!mounted) return;

    if (results == null) {
      if (_lastCachedPredictions.isNotEmpty) {
        setState(() {
          _predictions = _lastCachedPredictions;
          _fieldState = _FieldState.results;
        });
        _showOrUpdateOverlay();
      } else {
        setState(() => _fieldState = _FieldState.error);
        _removeOverlay();
      }
      return;
    }

    if (results.isEmpty) {
      setState(() {
        _predictions = [];
        _fieldState = _FieldState.noResults;
      });
      _removeOverlay();
      return;
    }

    _lastCachedPredictions = results;
    setState(() {
      _predictions = results;
      _fieldState = _FieldState.results;
    });
    _showOrUpdateOverlay();
  }

  Future<void> _selectPrediction(PlacePrediction prediction) async {
    _suppressSearch = true;
    _controller.text = prediction.description;
    _removeOverlay();
    setState(() {
      _fieldState = _FieldState.loading;
      _predictions = [];
    });

    final token = _sessionToken ?? _generateSessionToken();
    _sessionToken = null;

    final service = ref.read(placesServiceProvider);
    final place = await service.getPlaceDetails(prediction, token);

    _suppressSearch = false;

    if (!mounted) return;

    if (place != null) {
      widget.onAddressSelected(place.description, place.lat, place.lng);
      widget.onPlaceSelected?.call(place);
    } else {
      widget.onAddressSelected(prediction.description, 0.0, 0.0);
    }

    setState(() => _fieldState = _FieldState.idle);
  }

  Widget? _buildSuffix() {
    if (_fieldState == _FieldState.loading) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }
    return null;
  }

  Widget? _buildStatusMessage() {
    switch (_fieldState) {
      case _FieldState.tooShort:
        return _statusText('Type at least 3 characters');
      case _FieldState.noResults:
        return _statusText('No results found');
      case _FieldState.error:
        return _statusText('Search unavailable — check your connection');
      default:
        return null;
    }
  }

  Widget _statusText(String message) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Text(
        message,
        style: const TextStyle(fontSize: 12, color: Color(0xFF9A9C97)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusMsg = _buildStatusMessage();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delivery Address',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF202123),
          ),
        ),
        const SizedBox(height: 14),
        CompositedTransformTarget(
          link: _layerLink,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: _onTextChanged,
                  maxLines: 1,
                  decoration: InputDecoration(
                    hintText: _fieldState == _FieldState.idle
                        ? 'Start typing to search…'
                        : 'Search for an address…',
                    hintStyle: const TextStyle(
                      color: Color(0xFFB0B2AD),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.fromLTRB(16, 14, 8, 14),
                      child: Icon(
                        Icons.location_on_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(),
                    suffixIcon: _buildSuffix(),
                    suffixIconConstraints: const BoxConstraints(),
                  ),
                  style: const TextStyle(fontSize: 14, color: Color(0xFF202123)),
                ),
                if (statusMsg != null)
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0xFFEEF0ED)),
                      ),
                    ),
                    child: statusMsg,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownOverlay extends StatelessWidget {
  const _DropdownOverlay({
    required this.layerLink,
    required this.predictions,
    required this.onSelect,
  });

  final LayerLink layerLink;
  final List<PlacePrediction> predictions;
  final void Function(PlacePrediction) onSelect;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      width: layerLink.leaderSize?.width ?? 300,
      child: CompositedTransformFollower(
        link: layerLink,
        showWhenUnlinked: false,
        offset: Offset(0, (layerLink.leaderSize?.height ?? 54) + 4),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: predictions.length,
              itemBuilder: (ctx, index) {
                final prediction = predictions[index];
                final isLast = index == predictions.length - 1;
                return InkWell(
                  onTap: () => onSelect(prediction),
                  borderRadius: BorderRadius.vertical(
                    top: index == 0
                        ? const Radius.circular(16)
                        : Radius.zero,
                    bottom: isLast
                        ? const Radius.circular(16)
                        : Radius.zero,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: isLast
                          ? null
                          : const Border(
                              bottom: BorderSide(color: Color(0xFFEEF0ED)),
                            ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Color(0xFF9A9C97),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            prediction.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF202123),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
