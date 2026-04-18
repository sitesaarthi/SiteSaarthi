import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class ClientGstInvoicesPage extends StatefulWidget {
  const ClientGstInvoicesPage({super.key});

  @override
  State<ClientGstInvoicesPage> createState() => _ClientGstInvoicesPageState();
}

class _ClientGstInvoicesPageState extends State<ClientGstInvoicesPage> {
  static const String baseUrl = "http://10.0.2.2:5000/api";

  bool loading = true;
  bool opening = false;

  String err = "";
  List<Map<String, dynamic>> invoices = [];

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("authToken") ?? "";
  }

  String _idOf(Map<String, dynamic> x) {
    if (x["_id"] != null) return x["_id"].toString();
    if (x["id"] != null) return x["id"].toString();
    return "";
  }

  String _safe(String? v) => (v ?? "").trim().isEmpty ? "-" : v!.trim();

  String _dateOf(dynamic raw) {
    if (raw == null) return "-";
    try {
      // your schema has timestamps, so createdAt exists
      final dt = DateTime.tryParse(raw.toString());
      if (dt == null) return raw.toString();
      return DateFormat("dd/MM/yyyy").format(dt);
    } catch (_) {
      return raw.toString();
    }
  }

  Future<void> fetchInvoices(String projectId, {bool silent = false}) async {
    final token = await _getToken();
    if (token.isEmpty) {
      setState(() {
        loading = false;
        err = "Token missing. Please login again.";
      });
      return;
    }

    try {
      if (!silent) {
        setState(() {
          loading = true;
          err = "";
          invoices = [];
        });
      } else {
        setState(() => err = "");
      }

      final res = await http.get(
        Uri.parse("$baseUrl/doc-history/$projectId/gst-invoices"),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(res.body);
      if (res.statusCode >= 400) {
        throw (data["message"] ?? "Failed to load GST invoices");
      }

      final List list = (data["gstInvoices"] ?? []) as List;
      final mapped = list.map((e) => Map<String, dynamic>.from(e)).toList();

      setState(() {
        invoices = mapped;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        err = "Network error: $e";
      });
    }
  }

  Future<void> openInvoicePdf(Map<String, dynamic> gst) async {
    final token = await _getToken();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Token missing. Login again.")),
      );
      return;
    }

    final gstId = _idOf(gst);
    if (gstId.isEmpty) return;

    setState(() => opening = true);

    try {
      final res = await http.get(
        Uri.parse("$baseUrl/doc-history/gst/$gstId/url"),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(res.body);
      if (res.statusCode >= 400) throw (data["message"] ?? "Failed to open");

      final signedUrl = (data["url"] ?? "").toString();
      if (signedUrl.isEmpty) throw "Signed url missing";

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _ClientPdfPreviewPage(
            title: gst["invoiceNumber"]?.toString() ?? "GST Invoice",
            url: signedUrl,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Open failed: $e")),
      );
    } finally {
      if (!mounted) return;
      setState(() => opening = false);
    }
  }

  int _gridCount(double width) {
    if (width >= 1024) return 3;
    if (width >= 720) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final projectId = (args?["projectId"] ?? "").toString();

    if (projectId.isNotEmpty && loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        fetchInvoices(projectId);
      });
    }

    final w = MediaQuery.of(context).size.width;

    // ✅ LOADING
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0B3C5D)),
        ),
      );
    }

    // ✅ ERROR
    if (err.isNotEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(title: const Text("GST Invoices")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 48, color: Color(0xFFF59E0B)),
                const SizedBox(height: 10),
                Text(
                  "Failed to load GST invoices",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  err,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () => fetchInvoices(projectId),
                  icon: const Icon(Icons.refresh),
                  label: const Text("Retry"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B3C5D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text("GST Invoices"),
        actions: [
          IconButton(
            onPressed: opening ? null : () => fetchInvoices(projectId, silent: true),
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => fetchInvoices(projectId, silent: true),
          child: invoices.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    const SizedBox(height: 160),
                    Center(
                      child: Text(
                        "No GST invoices yet.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: invoices.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _gridCount(w),
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.35,
                  ),
                  itemBuilder: (_, i) {
                    final gst = invoices[i];
                    return _GstInvoiceCard(
                      gst: gst,
                      onPreview: opening ? null : () => openInvoicePdf(gst),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

/// ============================================================
/// ✅ GST CARD
/// ============================================================
class _GstInvoiceCard extends StatelessWidget {
  final Map<String, dynamic> gst;
  final VoidCallback? onPreview;

  const _GstInvoiceCard({
    required this.gst,
    required this.onPreview,
  });

  String _safe(String? v) => (v ?? "").trim().isEmpty ? "-" : v!.trim();

  String _dateOf(dynamic raw) {
    if (raw == null) return "-";
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return raw.toString();
    return DateFormat("dd/MM/yyyy").format(dt);
    }

  @override
  Widget build(BuildContext context) {
    final invoiceNo = _safe(gst["invoiceNumber"]?.toString());
    final client = _safe(gst["clientName"]?.toString());
    final gstin = _safe(gst["clientGSTIN"]?.toString());
    final place = _safe(gst["placeOfSupply"]?.toString());
    final total = (gst["totalAmount"] as num?)?.toDouble() ?? 0;
    final date = _dateOf(gst["createdAt"]);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 12,
            offset: Offset(0, 8),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(height: 6, color: const Color(0xFF2563EB)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoiceNo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    client,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "GSTIN: $gstin",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Place: $place",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "₹${NumberFormat.decimalPattern('en_IN').format(total)}",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            date,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: onPreview,
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                        label: const Text("Preview"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B3C5D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================
/// ✅ PDF PREVIEW PAGE (IN-APP)
/// ============================================================
class _ClientPdfPreviewPage extends StatelessWidget {
  final String title;
  final String url;

  const _ClientPdfPreviewPage({
    required this.title,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.inter(fontWeight: FontWeight.w900),
        ),
      ),
      body: SfPdfViewer.network(url),
    );
  }
}
