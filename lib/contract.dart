import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'db.dart';
import 'security.dart';
import 'utils.dart';

/// نافذة تجديد العقد بتاريخ بداية ومدة جديدة. ترجع true إذا تم التجديد.
Future<bool> showRenewContractDialog(
    BuildContext context, Map<String, dynamic> prop) async {
  final oldEnd = contractEnd(prop);
  final oldMonths = (prop['contract_months'] as num?)?.toInt() ?? 0;
  final t = DateTime.now();
  var newStart = oldEnd ?? DateTime(t.year, t.month, t.day);
  final months = TextEditingController(text: '${oldMonths > 0 ? oldMonths : 12}');

  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) {
        final m = int.tryParse(months.text.trim()) ?? 0;
        final end = m > 0 ? contractEndFrom(newStart, m) : null;
        return AlertDialog(
          title: const Text('تجديد العقد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (oldEnd != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text('العقد الحالي ينتهي في ${fmtDate(oldEnd)}',
                        style: const TextStyle(color: Colors.black54)),
                  ),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: newStart,
                      firstDate: DateTime(t.year - 5),
                      lastDate: DateTime(t.year + 15),
                    );
                    if (picked != null) setS(() => newStart = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'تاريخ بداية العقد الجديد',
                      prefixIcon: Icon(Icons.event_outlined),
                    ),
                    child: Text(fmtDate(newStart)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: months,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setS(() {}),
                  decoration: const InputDecoration(
                    labelText: 'مدة العقد (بالأشهر)',
                    prefixIcon: Icon(Icons.timelapse),
                  ),
                ),
                if (end != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text('ينتهي العقد الجديد في ${fmtDate(end)}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء')),
            FilledButton(
              onPressed: m > 0 ? () => Navigator.pop(ctx, true) : null,
              child: const Text('تجديد'),
            ),
          ],
        );
      },
    ),
  );

  final m = int.tryParse(months.text.trim()) ?? 0;
  if (res != true || m <= 0 || !context.mounted) return false;
  if (!await biometricAuth(context, 'تأكيد تجديد العقد')) return false;
  await DB.renewContract(prop['id'] as int, newStart, m);
  if (context.mounted) toast(context, 'تم تجديد العقد حتى ${fmtDate(contractEndFrom(newStart, m))}');
  return true;
}
