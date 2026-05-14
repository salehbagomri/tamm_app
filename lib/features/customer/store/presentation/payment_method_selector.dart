import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class PaymentMethod {
  final String id;
  final String name;
  final String type;
  final String? accountNumber;
  final String? accountName;
  final String? logoUrl;

  const PaymentMethod({
    required this.id,
    required this.name,
    required this.type,
    this.accountNumber,
    this.accountName,
    this.logoUrl,
  });

  factory PaymentMethod.fromMap(Map<String, dynamic> m) => PaymentMethod(
    id: m['id'] as String,
    name: m['name'] as String,
    type: m['type'] as String,
    accountNumber: m['account_number'] as String?,
    accountName: m['account_name'] as String?,
    logoUrl: m['logo_url'] as String?,
  );
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final _paymentMethodsProvider = FutureProvider.family<List<PaymentMethod>, String>(
  (ref, type) async {
    final data = await Supabase.instance.client
        .from('payment_methods')
        .select()
        .eq('type', type)
        .eq('is_active', true)
        .order('sort_order');
    return (data as List).map((e) => PaymentMethod.fromMap(e)).toList();
  },
);

// ---------------------------------------------------------------------------
// PaymentMethodSelector — public widget
// ---------------------------------------------------------------------------

class PaymentMethodSelector extends ConsumerWidget {
  final String selectedType;
  final String? selectedMethodId;
  final void Function(String type, String? methodId) onChanged;

  const PaymentMethodSelector({
    super.key,
    required this.selectedType,
    required this.selectedMethodId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'طريقة الدفع',
          style: AppTextStyles.cardTitle(context.colors.textPrimary),
        ),
        AppSpacing.gapSm2,
        Row(
          children: [
            _TypeTile(
              label: 'كاش',
              icon: Icons.payments_outlined,
              value: 'cash',
              selected: selectedType == 'cash',
              onTap: () => onChanged('cash', null),
            ),
            AppSpacing.hGapSm2,
            _TypeTile(
              label: 'بنك',
              icon: Icons.account_balance_outlined,
              value: 'bank',
              selected: selectedType == 'bank',
              onTap: () => onChanged('bank', null),
            ),
            AppSpacing.hGapSm2,
            _TypeTile(
              label: 'محفظة',
              icon: Icons.account_balance_wallet_outlined,
              value: 'wallet',
              selected: selectedType == 'wallet',
              onTap: () => onChanged('wallet', null),
            ),
          ],
        ),
        if (selectedType != 'cash') ...[
          AppSpacing.gapSm2,
          _MethodList(
            type: selectedType,
            selectedId: selectedMethodId,
            onSelect: (id) => onChanged(selectedType, id),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _TypeTile
// ---------------------------------------------------------------------------

class _TypeTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _TypeTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? context.colors.bluePrimary.withValues(alpha: 0.1)
                : context.colors.bgSurface,
            borderRadius: AppSpacing.radius,
            border: Border.all(
              color: selected ? context.colors.bluePrimary : context.colors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: AppSpacing.iconMd,
                color: selected
                    ? context.colors.bluePrimary
                    : context.colors.textSecond,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.bodySmall(
                  selected
                      ? context.colors.bluePrimary
                      : context.colors.textSecond,
                ).copyWith(
                  fontWeight:
                      selected ? AppTextStyles.semiBold : AppTextStyles.regular,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _MethodList
// ---------------------------------------------------------------------------

class _MethodList extends ConsumerWidget {
  final String type;
  final String? selectedId;
  final void Function(String id) onSelect;

  const _MethodList({
    required this.type,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methodsAsync = ref.watch(_paymentMethodsProvider(type));
    return methodsAsync.when(
      data: (methods) {
        if (methods.isEmpty) {
          return Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: context.colors.bgSurface,
              borderRadius: AppSpacing.radius,
              border: Border.all(color: context.colors.border),
            ),
            child: Text(
              'لا توجد وسائل دفع متاحة حالياً',
              style: AppTextStyles.body(context.colors.textSecond),
            ),
          );
        }
        return Column(
          children: methods
              .map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _MethodCard(
                    method: m,
                    selected: m.id == selectedId,
                    onTap: () => onSelect(m.id),
                  ),
                ),
              )
              .toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Text(
        'تعذر تحميل وسائل الدفع',
        style: AppTextStyles.body(context.colors.error),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _MethodCard
// ---------------------------------------------------------------------------

class _MethodCard extends StatelessWidget {
  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  const _MethodCard({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: AppSpacing.cardPaddingSm,
        decoration: BoxDecoration(
          color: selected
              ? context.colors.bluePrimary.withValues(alpha: 0.08)
              : context.colors.bgSurface,
          borderRadius: AppSpacing.radius,
          border: Border.all(
            color: selected ? context.colors.bluePrimary : context.colors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.colors.bgSurface2,
                borderRadius: AppSpacing.radiusSm,
              ),
              child: Icon(
                method.type == 'bank'
                    ? Icons.account_balance_outlined
                    : Icons.account_balance_wallet_outlined,
                size: AppSpacing.iconSm,
                color: context.colors.bluePrimary,
              ),
            ),
            AppSpacing.hGapSm2,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.name,
                    style: AppTextStyles.body(context.colors.textPrimary)
                        .copyWith(fontWeight: AppTextStyles.semiBold),
                  ),
                  if (method.accountNumber != null)
                    Text(
                      method.accountNumber!,
                      style: AppTextStyles.caption(context.colors.textSecond),
                    ),
                  if (method.accountName != null)
                    Text(
                      method.accountName!,
                      style: AppTextStyles.caption(context.colors.textSecond),
                    ),
                ],
              ),
            ),
            if (selected)
              Icon(
                Icons.check_circle,
                color: context.colors.bluePrimary,
                size: AppSpacing.iconMd,
              ),
          ],
        ),
      ),
    );
  }
}
