import 'package:flutter/material.dart';

class ClientReraPage extends StatelessWidget {
  const ClientReraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // 🔙 HEADER
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "RERA REPORT",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                ],
              ),

              const SizedBox(height: 16),

              // ================= PROJECT HEADER =================
              _card(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Green Valley Residency",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    _infoRow("RERA No", "PRM/MAHA/2024/001234"),
                    _infoRow("Quarter", "Q1 (Apr–Jun 2026)"),
                    _infoRow("Reporting Date", "30 June 2026"),
                    _infoRow("Promoter", "ABC Developers Pvt Ltd"),
                    _infoRow("Signatory", "Mr. Raj Mehta (Director)"),
                  ],
                ),
              ),

              // ================= BASIC DETAILS =================
              _sectionTitle("Project Details"),
              _card(Column(
                children: [
                  _infoRow("Total Area", "10,200 sq.m"),
                  _infoRow("Total Units", "200 (180 Res + 20 Comm)"),
                  _infoRow("Authority", "Mumbai Municipal Corp"),
                  _infoRow("Start Date", "Jan 2024"),
                  _infoRow("Completion", "Dec 2025 → Jun 2026"),
                ],
              )),

              // ================= PHYSICAL PROGRESS =================
              _sectionTitle("Physical Progress"),
              _card(
                Column(
                  children: [
                    _tableHeader(["Stage", "Start", "This Q", "End", "Status"]),

                    _tableRowStyled("Excavation", "0%", "20%", "20%", "On Track"),
                    _tableRowStyled("Plinth", "20%", "30%", "50%", "On Track"),
                    _tableRowStyled("Slab (G+10)", "0%", "10%", "10%", "Delayed"),
                    _tableRowStyled("Superstructure", "50%", "60%", "60%", "On Track"),
                    _tableRowStyled("Finishing", "5%", "15%", "20%", "Under"),

                    const Divider(height: 20),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Milestone:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Text("✔ G+10 slab casting completed"),

                    const SizedBox(height: 8),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Delay:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Text("⚠ Approval clearance delay"),
                  ],
                ),
              ),

              // ================= FINANCIAL BREAKDOWN =================
              _sectionTitle("Financial Breakdown"),
              _card(
                Column(
                  children: [
                    _tableHeader(["Work", "Allocated", "Used"]),

                    _financeRow("Scaffolding", "₹20L", "₹24L"),
                    _financeRow("Foundation Work", "₹50L", "₹45L"),
                    _financeRow("Steel & Material", "₹1.2Cr", "₹1.1Cr"),
                    _financeRow("Labor Cost", "₹80L", "₹70L"),
                    _financeRow("Finishing", "₹60L", "₹20L"),

                    const Divider(height: 20),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Insight:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Text("⚠ Scaffolding exceeded by ₹4L"),
                    const Text("✔ Overall spending controlled"),
                  ],
                ),
              ),

              // ================= REPORT ANALYSIS =================
              _sectionTitle("Report Analysis"),
              _card(
                Column(
                  children: [
                    _infoRow("Internal Progress", "65%"),
                    _infoRow("RERA Reported", "52%"),
                    const Divider(),

                    _infoRow("Consistency Score", "68%"),

                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "⚠ Moderate mismatch between internal and RERA reports. Needs verification.",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

              // ================= DECLARATION =================
              _sectionTitle("Declaration"),
              _card(
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "I hereby certify that the information provided is true and correct to the best of my knowledge.",
                    ),
                    SizedBox(height: 10),
                    Text("Name: Raj Mehta"),
                    Text("Designation: Director"),
                    Text("PAN: AABCM1234X"),
                    Text("Date: 30 June 2026"),
                    Text("Place: Mumbai"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= UI HELPERS =================

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 15),
      ),
    );
  }

  Widget _card(Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
          )
        ],
      ),
      child: child,
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _tableHeader(List<String> titles) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: titles
            .map((e) => Expanded(
                  child: Text(
                    e,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _tableRowStyled(
      String stage, String start, String current, String end, String status) {

    Color statusColor;

    switch (status) {
      case "On Track":
        statusColor = Colors.green;
        break;
      case "Delayed":
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(stage)),
          Expanded(child: Text(start)),
          Expanded(child: Text(current)),
          Expanded(child: Text(end)),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _financeRow(String work, String allocated, String used) {
    bool isOver = used.compareTo(allocated) > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(work)),
          Expanded(child: Text(allocated)),
          Expanded(
            child: Text(
              used,
              style: TextStyle(
                color: isOver ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}