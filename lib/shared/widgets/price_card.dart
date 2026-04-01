import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../widgets/custom_button.dart';

class PriceCard extends StatelessWidget {
  const PriceCard({
    super.key,
    required this.itemName,
    required this.imageUrl,
    required this.price,
    required this.onAccept,
    required this.onNegotiate,
    required this.onReject,
  });

  final String itemName;
  final String imageUrl;
  final double price;
  final VoidCallback onAccept;
  final VoidCallback onNegotiate;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.gapMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrl,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 120,
                  width: double.infinity,
                  color: AppColors.background,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.textSecondary,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppDimens.gapSm),
          Text(
            itemName,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppDimens.gapXs),
          Text(
            'Price: ₦${price.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimens.gapMd),
          Row(
            children: [
              Expanded(
                child: CustomButton(label: 'Accept', onPressed: onAccept),
              ),
              const SizedBox(width: AppDimens.gapSm),
              Expanded(
                child: CustomButton(
                  label: 'Negotiate',
                  onPressed: onNegotiate,
                  isPrimary: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.gapSm),
          CustomButton(label: 'Reject', onPressed: onReject, isPrimary: false),
        ],
      ),
    );
  }
}
