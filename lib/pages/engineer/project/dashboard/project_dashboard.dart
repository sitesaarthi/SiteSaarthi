import 'package:flutter/material.dart';

/// ✅ Import your DPR page
/// Update the path if your CreateDprPage is somewhere else.
import '../../create_dpr_page.dart';
import 'purchase_order.dart';

class ProjectDashboardPage extends StatefulWidget {
  final String projectId;
  final String projectName;

  /// ✅ callback to open materials tab
  final VoidCallback onOpenMaterials;

  const ProjectDashboardPage({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.onOpenMaterials,
  });

  @override
  State<ProjectDashboardPage> createState() => _ProjectDashboardPageState();
}

class _ProjectDashboardPageState extends State<ProjectDashboardPage> {
  bool checkingLocation = false;

  /// ✅ GPS HOLD for now
  /// (we still show UI but no geolocator)
  String gpsStatus = "NOT_VERIFIED";
  int? distanceFromSite;

  bool dprSubmitted = false;

  Map<String, dynamic> attendance = {
    "self": false,
    "workers": 18,
  };

  /// ✅ GPS on hold, only attendance decides DPR.
  bool get dprEnabled => attendance["self"] == true;

  /* ================= CHECK-IN (GPS HOLD) ================= */
  Future<void> handleSelfCheckIn() async {
    if (attendance["self"] == true || checkingLocation) return;

    setState(() => checkingLocation = true);

    // ✅ frontend delay just to feel real
    await Future.delayed(const Duration(milliseconds: 650));

    setState(() {
      attendance["self"] = true;

      // keep gps UI consistent
      gpsStatus = "NOT_VERIFIED";
      distanceFromSite = null;

      checkingLocation = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Attendance marked ✅")),
    );
  }

  /* ================= DPR BUTTON ACTION ================= */
  Future<void> _openCreateDpr() async {
    if (!dprEnabled) return;

    final ok = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateDprPage(
          projectId: widget.projectId,
          projectName: widget.projectName,
        ),
      ),
    );

    /// ✅ If create DPR page returns true -> mark submitted
    if (ok == true) {
      setState(() => dprSubmitted = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: 18),

          /// ✅ ATTENDANCE CARD
          _attendanceCard(),
          const SizedBox(height: 14),

          /// ✅ DPR CARD
          _dprCard(),
          const SizedBox(height: 18),

          /// ✅ MATERIALS
          _materialsCard(),
        ],
      ),
    );
  }

  /* ================= UI ================= */

  Widget _header() {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(99),
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            widget.projectName,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: Color(0xFF0F172A),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _attendanceCard() {
    final bool selfCheckedIn = attendance["self"] == true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 12),
            color: Color(0x0C000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "ATTENDANCE STATUS",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              /// ✅ Self Check-in (square)
              Expanded(
                child: InkWell(
                  onTap: checkingLocation ? null : handleSelfCheckIn,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: selfCheckedIn
                            ? const Color(0xFFBBF7D0)
                            : const Color(0xFFE2E8F0),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: checkingLocation
                          ? const SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 34,
                                  color: selfCheckedIn
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFF94A3B8),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  selfCheckedIn
                                      ? "CHECKED IN"
                                      : "SELF CHECK-IN",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    color: selfCheckedIn
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFF64748B),
                                  ),
                                )
                              ],
                            ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              /// ✅ Purchase Order (replaces Workers Present)
              Expanded(
                child: GestureDetector(
                  onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const EngineerCreatePoPage(),
      settings: RouteSettings(
        arguments: {
          "projectId": widget.projectId,
          "projectName": widget.projectName,
        },
      ),
    ),
  );
},


                  child: Container(
                    height: 96,
                    decoration: BoxDecoration(
                      color: const Color(0xff0B3C5D),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.receipt_long,
                            size: 34,
                            color: Colors.white,
                          ),
                          SizedBox(height: 6),
                          Text(
                            "PURCHASE\nORDER",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white70,
                              height: 1.2,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          /// ✅ warning strip
          if (!dprEnabled)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFF97316), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "MARK ATTENDANCE TO ENABLE DPR",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: Color(0xFF9A3412),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 10),

          /// ✅ GPS line (UI only)
          Row(
            children: const [
              Icon(
                Icons.navigation_rounded,
                size: 16,
                color: Color(0xFF94A3B8),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "GPS verification will be added later",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dprCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xff0B3C5D),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 12),
            color: Color(0x16000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "DAILY PROGRESS",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Capture today’s work & photos",
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: (!dprEnabled || dprSubmitted) ? null : _openCreateDpr,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor:
                    dprSubmitted ? const Color(0xFF16A34A) : Colors.orange,
                disabledBackgroundColor: Colors.white12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                dprSubmitted ? "DPR SUBMITTED" : "START DPR",
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: Colors.white,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _materialsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "URGENT MATERIALS",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Raise request for cement, steel, etc.",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: widget.onOpenMaterials,
              icon: const Icon(Icons.add),
              label: const Text("RAISE REQUEST"),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xff0B3C5D),
                backgroundColor: const Color(0xFFF1F5F9),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
