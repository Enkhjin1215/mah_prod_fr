import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class AddressDropdown extends StatefulWidget {
  final Function({required String? cityId, required String? districtId, required String? quarterId}) onChanged;

  const AddressDropdown({super.key, required this.onChanged});

  @override
  _AddressDropdownState createState() => _AddressDropdownState();
}

class _AddressDropdownState extends State<AddressDropdown> {
  List<dynamic> cities = [];
  List<dynamic> districts = [];
  List<dynamic> quarters = [];

  Map<String, dynamic>? selectedCity;
  Map<String, dynamic>? selectedDistrict;
  Map<String, dynamic>? selectedQuarter;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    cities = jsonDecode(await rootBundle.loadString('lib/language/city.json'));
    districts = jsonDecode(await rootBundle.loadString('lib/language/district.json'));
    quarters = jsonDecode(await rootBundle.loadString('lib/language/quarter.json'));
    setState(() {});
  }

  void emitChange() {
    widget.onChanged(cityId: selectedCity?['name'], districtId: selectedDistrict?['name'], quarterId: selectedQuarter?['name']);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _box(
          DropdownButton<Map<String, dynamic>>(
            isExpanded: true,
            hint: const Text("Хот сонгох"),
            value: selectedCity,
            items: cities.map<DropdownMenuItem<Map<String, dynamic>>>((city) => DropdownMenuItem(value: city, child: Text(city["name"]))).toList(),
            onChanged: (v) {
              setState(() {
                selectedCity = v;
                selectedDistrict = null;
                selectedQuarter = null;
              });
              emitChange();
            },
          ),
        ),

        const SizedBox(height: 12),

        _box(
          DropdownButton<Map<String, dynamic>>(
            isExpanded: true,
            hint: const Text("Дүүрэг / Сум сонгох"),
            value: selectedDistrict,
            items: districts
                .where((d) => d["parent"] == (selectedCity?["id"] ?? -1))
                .map<DropdownMenuItem<Map<String, dynamic>>>((d) => DropdownMenuItem(value: d, child: Text(d["name"])))
                .toList(),
            onChanged: (v) {
              setState(() {
                selectedDistrict = v;
                selectedQuarter = null;
              });
              emitChange();
            },
          ),
        ),

        const SizedBox(height: 12),

        _box(
          DropdownButton<Map<String, dynamic>>(
            isExpanded: true,
            hint: const Text("Баг / Хороо сонгох"),
            value: selectedQuarter,
            items: quarters
                .where((q) => q["parent"] == (selectedDistrict?["id"] ?? -1))
                .map<DropdownMenuItem<Map<String, dynamic>>>((q) => DropdownMenuItem(value: q, child: Text(q["name"])))
                .toList(),
            onChanged: (v) {
              setState(() {
                selectedQuarter = v;
              });
              emitChange();
            },
          ),
        ),
      ],
    );
  }

  Widget _box(Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(child: child),
    );
  }
}
