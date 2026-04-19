import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:wsfm/cubits/reports/reports_state.dart';

class ReportExportService {
  Future<File> exportCenterReportCsv({
    required String centerName,
    required List<ReportRecordRow> rows,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('Date,Type,Item,Quantity,Amount,Description');

    for (final row in rows) {
      final date =
          '${row.createdAt.year.toString().padLeft(4, '0')}-'
          '${row.createdAt.month.toString().padLeft(2, '0')}-'
          '${row.createdAt.day.toString().padLeft(2, '0')} '
          '${row.createdAt.hour.toString().padLeft(2, '0')}:'
          '${row.createdAt.minute.toString().padLeft(2, '0')}';

      buffer.writeln([
        _csv(date),
        _csv(row.type),
        _csv(row.itemName),
        _csv(row.quantity?.toString() ?? '-'),
        _csv(row.amount.toStringAsFixed(2)),
        _csv(row.description),
      ].join(','));
    }

    final dir = await getTemporaryDirectory();
    final safeCenter = centerName.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');
    final now = DateTime.now();
    final fileName =
        '${safeCenter}_report_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.csv';

    final file = File('${dir.path}/$fileName');
    await file.writeAsString(buffer.toString());

    return file;
  }

  String _csv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}