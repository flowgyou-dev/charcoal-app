import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';

class DeliveryAddressSheet extends StatefulWidget {
  final String? initialAddress;

  const DeliveryAddressSheet({super.key, this.initialAddress});

  static Future<String?> show(BuildContext context, {String? initialAddress}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DeliveryAddressSheet(initialAddress: initialAddress),
    );
  }

  @override
  State<DeliveryAddressSheet> createState() => _DeliveryAddressSheetState();
}

class _DeliveryAddressSheetState extends State<DeliveryAddressSheet> {
  final _formKey = GlobalKey<FormState>();
  final _streetCtrl = TextEditingController();
  final _barangayCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _provinceCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();

  String _label = 'Home';

  @override
  void dispose() {
    _streetCtrl.dispose();
    _barangayCtrl.dispose();
    _cityCtrl.dispose();
    _provinceCtrl.dispose();
    _postalCtrl.dispose();
    _landmarkCtrl.dispose();
    super.dispose();
  }

  void _saveAddress() {
    if (!_formKey.currentState!.validate()) return;

    final street = Validators.sanitizeText(_streetCtrl.text);
    final brgy = Validators.sanitizeText(_barangayCtrl.text);
    final city = Validators.sanitizeText(_cityCtrl.text);
    final prov = Validators.sanitizeText(_provinceCtrl.text);
    final postal = _postalCtrl.text.trim();
    final landmark = Validators.sanitizeText(_landmarkCtrl.text);

    final parts = <String>[
      '[$_label] $street',
      if (brgy.isNotEmpty) 'Brgy. $brgy',
      city,
      if (prov.isNotEmpty) prov,
      if (postal.isNotEmpty) postal,
    ];

    var formatted = parts.join(', ');
    if (landmark.isNotEmpty) {
      formatted += ' (Landmark: $landmark)';
    }

    Navigator.pop(context, formatted);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Delivery Address',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.inkCharcoal,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Fill in your complete Philippine delivery details.',
                style: TextStyle(fontSize: 12, color: AppTheme.mutedSlate),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Text(
                    'Label as:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.inkCharcoal,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text('Home', style: TextStyle(fontSize: 12)),
                    selected: _label == 'Home',
                    onSelected: (_) => setState(() => _label = 'Home'),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Work', style: TextStyle(fontSize: 12)),
                    selected: _label == 'Work',
                    onSelected: (_) => setState(() => _label = 'Work'),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _streetCtrl,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Street Name, Building, House No. *',
                  hintText: 'e.g. Blk 4 Lot 12 Sampaguita St.',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (v) => Validators.validateRequiredText(v, label: 'Street / House No.', min: 4, max: 120),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _barangayCtrl,
                      maxLength: 60,
                      decoration: const InputDecoration(
                        labelText: 'Barangay *',
                        hintText: 'e.g. Brgy. San Jose',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (v) => Validators.validateRequiredText(v, label: 'Barangay', min: 2, max: 60),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _cityCtrl,
                      maxLength: 60,
                      decoration: const InputDecoration(
                        labelText: 'City / Municipality *',
                        hintText: 'e.g. Manila',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (v) => Validators.validateRequiredText(v, label: 'City', min: 2, max: 60),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _provinceCtrl,
                      maxLength: 60,
                      decoration: const InputDecoration(
                        labelText: 'Province / Metro Manila',
                        hintText: 'e.g. Metro Manila',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (v) => Validators.validateOptionalText(v, label: 'Province', max: 60),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _postalCtrl,
                      maxLength: 4,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Postal Code',
                        hintText: '1000',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _landmarkCtrl,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Landmark / Delivery Note (Optional)',
                  hintText: 'e.g. Near blue gate / Sari-sari store',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (v) => Validators.validateOptionalText(v, label: 'Landmark', max: 100),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.headerForest,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _saveAddress,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text(
                    'Use This Delivery Address',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
