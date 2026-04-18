import 'package:flutter/material.dart';
import '../../layout/app_layout.dart';

class SalesDashboardPage extends StatefulWidget {
  const SalesDashboardPage({super.key});

  @override
  State<SalesDashboardPage> createState() => _SalesDashboardPageState();
}

class _SalesDashboardPageState extends State<SalesDashboardPage> {
  late final List<Map<String, dynamic>> flats;
  int? selectedFloor;

  @override
  void initState() {
    super.initState();
    flats = _generateDummyFlats();
  }

  // ------------------------------------------------------------
  // Dummy Data with BHK logic
  // ------------------------------------------------------------
  List<Map<String, dynamic>> _generateDummyFlats() {
    final List<Map<String, dynamic>> list = [];

    for (int floor = 1; floor <= 10; floor++) {
      String bhk;
      int area;

      if (floor <= 6) {
        bhk = "1 BHK";
        area = 420;
      } else if (floor <= 9) {
        bhk = "2 BHK";
        area = 860;
      } else {
        bhk = "3 BHK";
        area = 1200;
      }

      for (int flat = 1; flat <= 6; flat++) {
        list.add({
          "floor": floor,
          "flat": flat,
          "bhk": bhk,
          "area": area,
          "status": "UNSOLD",
          "price": "",
          "buyerName": "",
          "buyerPhone": "",
          "buyerAddress": "",
        });
      }
    }
    return list;
  }

  // ------------------------------------------------------------
  // Sell Flat Dialog
  // ------------------------------------------------------------
  void _sellFlat(Map<String, dynamic> flat) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Sell Flat"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Floor ${flat["floor"]} • Flat ${flat["flat"].toString().padLeft(2, '0')}",
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text("${flat["bhk"]} • ${flat["area"]} sqft"),
                const SizedBox(height: 12),

                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Buyer Name"),
                ),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: "Phone Number"),
                ),
                TextField(
                  controller: addrCtrl,
                  decoration: const InputDecoration(labelText: "Address"),
                ),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Selling Price"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  flat["status"] = "SOLD";
                  flat["buyerName"] = nameCtrl.text;
                  flat["buyerPhone"] = phoneCtrl.text;
                  flat["buyerAddress"] = addrCtrl.text;
                  flat["price"] = priceCtrl.text;
                });
                Navigator.pop(ctx);
              },
              child: const Text("Confirm Sale"),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return AppLayout(
      child: selectedFloor == null
          ? _buildFloorList()
          : _buildFloorDetails(),
    );
  }

  Widget _buildFloorList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          "Sales Dashboard",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
        for (int floor = 1; floor <= 10; floor++) _floorTile(floor),
      ],
    );
  }

  Widget _floorTile(int floor) {
    return GestureDetector(
      onTap: () => setState(() => selectedFloor = floor),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Floor $floor",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildFloorDetails() {
    final sold = flats.where((f) =>
        f["floor"] == selectedFloor && f["status"] == "SOLD");
    final unsold = flats.where((f) =>
        f["floor"] == selectedFloor && f["status"] == "UNSOLD");

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => selectedFloor = null),
            ),
            Text(
              "Floor $selectedFloor",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 16),

        const Text("SOLD",
            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.green)),
        const SizedBox(height: 8),
        ...sold.map(_soldCard),

        const SizedBox(height: 24),

        const Text("UNSOLD",
            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.orange)),
        const SizedBox(height: 8),
        ...unsold.map(_unsoldCard),
      ],
    );
  }

  Widget _soldCard(Map<String, dynamic> f) {
    return _card(
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          "Flat ${f["flat"].toString().padLeft(2, '0')} • ${f["bhk"]}",
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        Text("Area: ${f["area"]} sqft"),
        Text("Price: ₹${f["price"]}"),
        const SizedBox(height: 6),
        Text("Name: ${f["buyerName"]}"),
        Text("Phone: ${f["buyerPhone"]}"),
        Text("Address: ${f["buyerAddress"]}"),
      ]),
    );
  }

  Widget _unsoldCard(Map<String, dynamic> f) {
    return _card(
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Flat ${f["flat"].toString().padLeft(2, '0')} • ${f["bhk"]}",
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              Text("${f["area"]} sqft"),
            ],
          ),
          ElevatedButton(
            onPressed: () => _sellFlat(f),
            child: const Text("Sell"),
          ),
        ],
      ),
    );
  }

  Widget _card(Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: child,
    );
  }
}
