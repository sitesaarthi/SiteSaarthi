import 'package:flutter/material.dart';
import 'owner_manual_doc_page.dart';

class OwnerIodUploadPage extends StatelessWidget {
  const OwnerIodUploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OwnerManualDocPage(
      docKey: "iod",
      title: "IOD (Intimation of Disapproval)",
      subtitle: "Upload official IOD PDF (only one allowed).",
    );
  }
}
