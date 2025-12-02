import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/coupon_provider.dart';
import '../../models/coupon.dart';
import '../../config/app_theme.dart';

class CouponFormScreen extends StatefulWidget {
  final Coupon? coupon;

  const CouponFormScreen({super.key, this.coupon});

  @override
  State<CouponFormScreen> createState() => _CouponFormScreenState();
}

class _CouponFormScreenState extends State<CouponFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  late TextEditingController _descriptionController;
  late TextEditingController _quantityController;
  late TextEditingController _discountPercentageController;
  late TextEditingController _minimumAmountController;
  DateTime? _expiryDate;
  bool _isActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.coupon?.code);
    _descriptionController = TextEditingController(
      text: widget.coupon?.description,
    );
    _quantityController = TextEditingController(
      text: widget.coupon?.quantity.toString() ?? '-1',
    );
    _discountPercentageController = TextEditingController(
      text: widget.coupon?.discountPercentage.toString(),
    );
    _minimumAmountController = TextEditingController(
      text: widget.coupon?.minimumAmount.toString() ?? '0',
    );
    _expiryDate = widget.coupon?.expiryDate;
    _isActive = widget.coupon?.isActive ?? true;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _discountPercentageController.dispose();
    _minimumAmountController.dispose();
    super.dispose();
  }

  Future<void> _selectExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.goldColor,
              onPrimary: AppTheme.textOnGold,
              surface: AppTheme.cardColor,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      final provider = Provider.of<CouponProvider>(context, listen: false);
      final coupon = Coupon(
        id: widget.coupon?.id ?? 0,
        code: _codeController.text.toUpperCase(),
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        quantity: int.tryParse(_quantityController.text) ?? -1,
        discountPercentage:
            int.tryParse(_discountPercentageController.text) ?? 0,
        minimumAmount: double.tryParse(_minimumAmountController.text) ?? 0,
        expiryDate: _expiryDate,
        isActive: _isActive,
      );

      final success = widget.coupon == null
          ? await provider.addCoupon(coupon)
          : await provider.updateCoupon(widget.coupon!.id, coupon);

      if (mounted) {
        setState(() => _isSaving = false);
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    widget.coupon == null
                        ? 'Coupon created successfully'
                        : 'Coupon updated successfully',
                  ),
                ],
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Failed to save coupon'),
                ],
              ),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.coupon != null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: Text(isEditing ? 'Edit Coupon' : 'Add Coupon')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppTheme.goldGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isEditing ? Icons.edit : Icons.local_offer,
                      color: AppTheme.textOnGold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Edit Coupon' : 'New Coupon',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          isEditing
                              ? 'Update coupon details'
                              : 'Create a new discount coupon',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Form Fields Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Coupon Code'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Coupon Code',
                      prefixIcon: Icon(Icons.confirmation_number_outlined),
                      hintText: 'e.g., SUMMER20',
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'Coupon code is required' : null,
                    enabled: !isEditing,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      prefixIcon: Icon(Icons.description_outlined),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Discount Settings'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _discountPercentageController,
                    decoration: const InputDecoration(
                      labelText: 'Discount Percentage',
                      prefixIcon: Icon(Icons.percent),
                      suffixText: '%',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Required';
                      final val = int.tryParse(v!);
                      if (val == null || val < 1 || val > 100) {
                        return 'Must be 1-100';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _minimumAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Minimum Order Amount',
                      prefixIcon: Icon(Icons.attach_money),
                      hintText: '0 for no minimum',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Usage Limits'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Usage Limit',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                      helperText: 'Enter -1 for unlimited usage',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Required';
                      final val = int.tryParse(v!);
                      if (val == null || (val != -1 && val <= 0)) {
                        return 'Must be -1 or > 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Expiry Date'),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _selectExpiryDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: AppTheme.goldColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Expiry Date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _expiryDate != null
                                      ? DateFormat(
                                          'MMMM dd, yyyy',
                                        ).format(_expiryDate!)
                                      : 'No expiry date set',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: _expiryDate != null
                                        ? AppTheme.textPrimary
                                        : AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_expiryDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () =>
                                  setState(() => _expiryDate = null),
                              color: AppTheme.textMuted,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Status'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SwitchListTile(
                      title: const Text('Active'),
                      subtitle: Text(
                        _isActive
                            ? 'Coupon is active and can be used'
                            : 'Coupon is disabled',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                      activeTrackColor: AppTheme.successColor.withValues(
                        alpha: 0.5,
                      ),
                      thumbColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return AppTheme.successColor;
                        }
                        return null;
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Save Button
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.textOnGold,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(isEditing ? Icons.save : Icons.add),
                          const SizedBox(width: 8),
                          Text(isEditing ? 'Save Changes' : 'Create Coupon'),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.goldDark,
        letterSpacing: 0.5,
      ),
    );
  }
}
