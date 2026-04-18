import 'package:flutter/material.dart';
import 'owner_manual_doc_page.dart';

class OwnerReraUploadPage extends StatelessWidget {
  const OwnerReraUploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OwnerManualDocPage(
      docKey: "rera",
      title: "RERA Certificate",
      subtitle: "Upload official RERA certificate PDF (only one allowed).",
    );
  }
}
