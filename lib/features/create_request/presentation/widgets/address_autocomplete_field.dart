import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/config/app_env.dart';

class AddressSuggestion {
  final String address;
  final double latitude;
  final double longitude;

  AddressSuggestion({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory AddressSuggestion.fromJson(Map<String, dynamic> json) {
    return AddressSuggestion(
      address: json['address'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AddressAutocompleteField extends StatefulWidget {
  const AddressAutocompleteField({
    super.key,
    required this.onAddressSelected,
    this.initialValue = '',
  });

  final Function(String address, double lat, double lng) onAddressSelected;
  final String initialValue;

  @override
  State<AddressAutocompleteField> createState() =>
      _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  late final TextEditingController _controller;
  Timer? _debounce;
  List<AddressSuggestion> _suggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _searchAddresses(String query) async {
    if (query.length < 3) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url =
          '${AppEnv.apiBaseUrl}/api/places/search?query=${Uri.encodeQueryComponent(query)}&limit=10';

      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final results = (json['results'] as List?)
                ?.map((item) => AddressSuggestion.fromJson(item))
                .toList() ??
            [];

        if (mounted) {
          setState(() {
            _suggestions = results;
            _showSuggestions = results.isNotEmpty;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _suggestions = []);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onTextChanged(String value) {
    _debounce?.cancel();
    _debounce =
        Timer(const Duration(milliseconds: 400), () => _searchAddresses(value));
  }

  void _selectSuggestion(AddressSuggestion suggestion) {
    _controller.text = suggestion.address;
    widget.onAddressSelected(
      suggestion.address,
      suggestion.latitude,
      suggestion.longitude,
    );
    setState(() => _showSuggestions = false);
  }

  @override
  Widget build(BuildContext context) {
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
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                onChanged: _onTextChanged,
                onTap: () {
                  if (_suggestions.isNotEmpty) {
                    setState(() => _showSuggestions = true);
                  }
                },
                maxLines: 1,
                decoration: InputDecoration(
                  hintText: 'Search for an address...',
                  hintStyle:
                      const TextStyle(color: Color(0xFFB0B2AD), fontSize: 14),
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
                  suffixIcon: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                        )
                      : null,
                  suffixIconConstraints: const BoxConstraints(),
                ),
                style: const TextStyle(fontSize: 14, color: Color(0xFF202123)),
              ),
              if (_showSuggestions && _suggestions.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: const Color(0xFFEEF0ED),
                      ),
                    ),
                  ),
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      return GestureDetector(
                        onTap: () => _selectSuggestion(suggestion),
                        child: Container(
                          color: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
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
                                  suggestion.address,
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
            ],
          ),
        ),
      ],
    );
  }
}
