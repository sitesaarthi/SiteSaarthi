import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import '../../utils/dpr_pdf_builder.dart';
import '../../services/dpr_service.dart';

class CreateDprPage extends StatefulWidget {
  final String projectId;
  final String projectName;

  const CreateDprPage({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<CreateDprPage> createState() => _CreateDprPageState();
}

class _CreateDprPageState extends State<CreateDprPage> {
  final dprService = DprService();
  final picker = ImagePicker();

  bool loading = false;

  /// ✅ fixed date = today only (no picker)
  final DateTime selectedDate = DateTime.now();

  final titleCtrl = TextEditingController();
  final workCtrl = TextEditingController();
  final issuesCtrl = TextEditingController();

  /// ✅ Site photos as files
  final List<File> sitePhotos = [];

  /// ✅ Workers list
  final List<_WorkerInput> workers = [];

  @override
  void dispose() {
    titleCtrl.dispose();
    workCtrl.dispose();
    issuesCtrl.dispose();
    for (final w in workers) {
      w.dispose();
    }
    super.dispose();
  }

  /* ================= SITE PHOTOS ================= */

  Future<void> _pickSitePhoto({required bool camera}) async {
    final XFile? img = await picker.pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 70,
    );

    if (img == null) return;

    setState(() {
      sitePhotos.add(File(img.path));
    });
  }

  void _removeSitePhoto(int index) {
    setState(() => sitePhotos.removeAt(index));
  }

  /* ================= WORKERS ================= */

  void _addWorker() {
    setState(() => workers.add(_WorkerInput()));
  }

  void _removeWorker(int i) {
    setState(() {
      workers[i].dispose();
      workers.removeAt(i);
    });
  }

  /* ================= SUBMIT ================= */

  Future<void> _submit() async {
    final work = workCtrl.text.trim();

    if (work.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Work Done is required")),
      );
      return;
    }

    if (sitePhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload at least 1 site photo")),
      );
      return;
    }

    try {
      setState(() => loading = true);

      final workersData = workers.map((w) => w.toMap()).toList();

      /// ✅ Create PDF with images
      // ✅ Create PDF with images
      final pdfFile = await DprPdfBuilder.buildPdf(
        projectName: widget.projectName,
        date: selectedDate,
        title: titleCtrl.text.trim(),
        workDone: workCtrl.text.trim(),
        issues: issuesCtrl.text.trim(),
        photos: sitePhotos,
        workers: workersData,
      );

// ✅ Upload PDF and get URL
      final pdfUrl = await dprService.uploadDprPdf(pdfFile);

// ✅ Create DPR with fileUrl now
      final res = await dprService.createDpr(
        projectId: widget.projectId,
        date: selectedDate,
        title: titleCtrl.text.trim(),
        workDone: workCtrl.text.trim(),
        issues: issuesCtrl.text.trim(),
        photos: const [],
        fileUrl: pdfUrl,
      );

      setState(() => loading = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "DPR submitted ✅ (${res["dpr"]?["_id"] ?? ""})",
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      setState(() => loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Submit failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat("dd MMM yyyy").format(selectedDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        title: Text(
          "Create DPR",
          style: GoogleFonts.inter(fontWeight: FontWeight.w900),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _headerCard(dateText),
            const SizedBox(height: 14),
            _inputCard(),
            const SizedBox(height: 14),
            _sitePhotosCard(),
            const SizedBox(height: 14),
            _workersCard(),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B3C5D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        "Submit DPR",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* ================= UI ================= */

  Widget _headerCard(String dateText) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(LucideIcons.fileText, color: Color(0xFF7C3AED)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.projectName,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Date: $dateText",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          /// ✅ No change button now
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "Auto",
              style:
                  GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 11),
            ),
          )
        ],
      ),
    );
  }

  Widget _inputCard() {
    return _SectionCard(
      title: "DPR Info",
      child: Column(
        children: [
          TextField(
            controller: titleCtrl,
            decoration: const InputDecoration(
              labelText: "Title (optional)",
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: workCtrl,
            minLines: 4,
            maxLines: 10,
            decoration: const InputDecoration(
              labelText: "Work Done *",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: issuesCtrl,
            minLines: 3,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: "Issues / blockers (optional)",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sitePhotosCard() {
    return _SectionCard(
      title: "Site Photos",
      trailing: PopupMenuButton<String>(
        icon: const Icon(LucideIcons.plus),
        onSelected: (v) {
          if (v == "camera") _pickSitePhoto(camera: true);
          if (v == "gallery") _pickSitePhoto(camera: false);
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: "camera", child: Text("Camera")),
          PopupMenuItem(value: "gallery", child: Text("Gallery")),
        ],
      ),
      child: sitePhotos.isEmpty
          ? Text(
              "No photos uploaded yet",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF94A3B8),
              ),
            )
          : Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(sitePhotos.length, (i) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(
                        sitePhotos[i],
                        width: 92,
                        height: 92,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        onTap: () => _removeSitePhoto(i),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    )
                  ],
                );
              }),
            ),
    );
  }

  Widget _workersCard() {
    return _SectionCard(
      title: "Workers",
      trailing: IconButton(
        onPressed: _addWorker,
        icon: const Icon(LucideIcons.plus),
      ),
      child: workers.isEmpty
          ? Text(
              "No workers added yet",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF94A3B8),
              ),
            )
          : Column(
              children: List.generate(workers.length, (i) {
                final w = workers[i];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            "Worker ${i + 1}",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => _removeWorker(i),
                            icon: const Icon(LucideIcons.x),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),

                      TextField(
                        controller: w.name,
                        decoration: const InputDecoration(
                          labelText: "Name",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),

                      TextField(
                        controller: w.role,
                        decoration: const InputDecoration(
                          labelText: "Role (mistri/helper/etc)",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),

                      TextField(
                        controller: w.price,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Daily Price (₹)",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),

                      /// ✅ Worker Photo
                      _workerPhotoBlock(
                        label: "Worker Photo",
                        file: w.workerPhoto,
                        onPickCamera: () => w.pickWorkerPhoto(
                            picker, true, () => setState(() {})),
                        onPickGallery: () => w.pickWorkerPhoto(
                            picker, false, () => setState(() {})),
                        onRemove: () => setState(() => w.workerPhoto = null),
                      ),

                      const SizedBox(height: 10),

                      /// ✅ Aadhaar Photo
                      _workerPhotoBlock(
                        label: "Aadhaar Photo",
                        file: w.aadhaarPhoto,
                        onPickCamera: () => w.pickAadhaarPhoto(
                            picker, true, () => setState(() {})),
                        onPickGallery: () => w.pickAadhaarPhoto(
                            picker, false, () => setState(() {})),
                        onRemove: () => setState(() => w.aadhaarPhoto = null),
                      ),
                    ],
                  ),
                );
              }),
            ),
    );
  }

  Widget _workerPhotoBlock({
    required String label,
    required File? file,
    required VoidCallback onPickCamera,
    required VoidCallback onPickGallery,
    required VoidCallback onRemove,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          if (file == null)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPickCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Camera"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPickGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Gallery"),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(file,
                      width: 72, height: 72, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Uploaded ✅",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete, color: Colors.red),
                )
              ],
            )
        ],
      ),
    );
  }
}

class _WorkerInput {
  final name = TextEditingController();
  final role = TextEditingController();
  final price = TextEditingController();

  File? workerPhoto;
  File? aadhaarPhoto;

  void dispose() {
    name.dispose();
    role.dispose();
    price.dispose();
  }

  Future<void> pickWorkerPhoto(
      ImagePicker picker, bool camera, VoidCallback refresh) async {
    final XFile? img = await picker.pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 70,
    );
    if (img == null) return;
    workerPhoto = File(img.path);
    refresh();
  }

  Future<void> pickAadhaarPhoto(
      ImagePicker picker, bool camera, VoidCallback refresh) async {
    final XFile? img = await picker.pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 70,
    );
    if (img == null) return;
    aadhaarPhoto = File(img.path);
    refresh();
  }

  Map<String, dynamic> toMap() {
    return {
      "name": name.text.trim(),
      "role": role.text.trim(),
      "dailyPrice": price.text.trim(),
      "workerPhotoFile": workerPhoto,
      "aadhaarPhotoFile": aadhaarPhoto,
    };
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
