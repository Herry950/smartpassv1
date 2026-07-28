import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

Future<pw.Widget> buildOfficialStamp() async {
  final image = pw.MemoryImage(
    (await rootBundle.load(
      'assets/images/smartpass_stamp.png',
    ))
        .buffer
        .asUint8List(),
  );

  return pw.Align(
    alignment: pw.Alignment.centerRight,
    child: pw.Opacity(
      opacity: 0.85,
      child: pw.Transform.rotate(
        angle: -0.15,
        child: pw.Image(
          image,
          width: 140,
          height: 140,
        ),
      ),
    ),
  );
}