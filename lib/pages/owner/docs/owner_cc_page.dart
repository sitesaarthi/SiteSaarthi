import 'package:flutter/material.dart';
import 'owner_manual_doc_page.dart';

class OwnerCcUploadPage extends StatelessWidget {
  const OwnerCcUploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OwnerManualDocPage(
      docKey: "cc",
      title: "Commencement Certificate (CC)",
      subtitle: "Upload CC PDF (only one allowed).",
    );
  }
}
