import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mah_front/file_input.dart';
import 'package:snow_fall_animation/snow_fall_animation.dart';
import 'address_dropdown.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: const MilkPromoPage());
  }
}

class MilkPromoPage extends StatefulWidget {
  const MilkPromoPage({super.key});

  @override
  State<MilkPromoPage> createState() => _MilkPromoPageState();
}

class _MilkPromoPageState extends State<MilkPromoPage> with SingleTickerProviderStateMixin {
  String cityId = '';
  String districtId = '';
  String quarterId = '';

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController checkPhoneController = TextEditingController();

  final TextEditingController lotteryController = TextEditingController();
  late TabController _tabController;

  bool isSubmitting = false;
  PlatformFile? myEbarimtFile;

  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool isReady = false;
  List<dynamic> phoneResults = [];
  bool isChecking = false;
  @override
  void initState() {
    _autoScroll();
    _tabController = TabController(length: 2, vsync: this);

    super.initState();
  }

  final List<String> imageUrls = [
    "assets/images/photo_1.png",
    "assets/images/photo_2.png",
    "assets/images/photo_3.png",
    "assets/images/photo_4.png",
    "assets/images/photo_5.png",
    "assets/images/photo_6.png",
  ];

  void _autoScroll() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;

      int next = _currentPage + 1;
      if (next >= imageUrls.length) next = 0;

      _pageController.animateToPage(next, duration: const Duration(seconds: 2), curve: Curves.easeInOut);

      _autoScroll();
    });
  }

  Future<http.MultipartFile> createMultipartFile(PlatformFile file) async {
    if (file.bytes != null) {
      // ⭐ WEB (path = null)
      return http.MultipartFile.fromBytes('ebarimt_picture', file.bytes!, filename: file.name);
    } else {
      // ⭐ Mobile / Desktop
      return await http.MultipartFile.fromPath('ebarimt_picture', file.path!, filename: file.name);
    }
  }

  bool ready() {
    if (phoneController.text.isEmpty || lotteryController.text.isEmpty || myEbarimtFile == null || cityId == '' || quarterId == '') {
      return false;
    } else {
      return true;
    }
  }

  Future<void> submitLottery() async {
    if (phoneController.text.isEmpty || lotteryController.text.isEmpty || myEbarimtFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Бүх талбарыг бөглөнө үү!")));
      return;
    }

    setState(() => isSubmitting = true);

    final uri = Uri.parse('https://mglrndm.online/lotteries/');

    var request = http.MultipartRequest('POST', uri);

    request.fields['phone_number'] = phoneController.text;
    request.fields['lottery_number'] = lotteryController.text;
    request.fields['aimag'] = cityId.toString();
    request.fields['sum'] = districtId.toString();
    request.fields['horoo'] = quarterId.toString();
    request.fields['status'] = 'pending';

    print("Request Fields:");
    request.fields.forEach((key, value) {
      print("  $key = $value");
    });

    if (myEbarimtFile != null) {
      print("Attaching file: ${myEbarimtFile!.name}");
      var file = await createMultipartFile(myEbarimtFile!);
      request.files.add(file);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Баримтны зургаа оруулна уу!")));
      return;
    }

    try {
      print("Sending request…");
      var response = await request.send();

      print("Response Code: ${response.statusCode}");

      final responseBody = await response.stream.bytesToString();
      print("Response Body: $responseBody");

      if (response.statusCode == 201 || response.statusCode == 200) {
        print("🎉 SUCCESS");

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Амжилттай илгээв!")));

        phoneController.clear();
        lotteryController.clear();
        setState(() => myEbarimtFile = null);
      } else {
        print("❌ FAILED: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Амжилтгүй: ${response.statusCode}")));
      }
    } catch (e) {
      print("🔥 Exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Алдаа гарлаа: ")));
    } finally {
      print("==== SUBMIT LOTTERY END ====");
      setState(() => isSubmitting = false);
    }
  }

  Future<void> checkByPhone() async {
    final phone = checkPhoneController.text;

    setState(() {
      isChecking = true;
    });

    final url = Uri.parse("https://mglrndm.online/by-phone/?phone_number=$phone");

    final res = await http.get(url);
    print('res:${res.statusCode}\n${res.body}');

    if (res.statusCode == 200) {
      if (res.body == "[]") {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Таны утсан дээр бүртгүүлсэн сугалаа олдсонгүй")));
      }
      setState(() {
        phoneResults = jsonDecode(res.body);
        isChecking = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Таны утсан дээр бүртгүүлсэн сугалаа олдсонгүй")));

      setState(() {
        phoneResults = [];
        isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isDesktop = width >= 900;
    final bool isTablet = width >= 600 && width < 900;

    return Scaffold(
      // Add this to prevent the background image/color from resizing awkwardly when keyboard opens
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D73D1), Color(0xFFE0F2FF), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: isDesktop
                  ? Row(
                      children: [
                        Expanded(child: _buildForm(isDesktop: true)),
                        Expanded(child: _buildDynamicImage()),
                      ],
                    )
                  : SingleChildScrollView(
                      // <--- 1. ADD THIS WRAPPER
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16, vertical: 16),
                        child: Column(
                          children: [
                            _buildDynamicImage(height: isTablet ? 300 : 200),
                            const SizedBox(height: 20),
                            _buildForm(isDesktop: false),
                            // Add extra padding at bottom so keyboard doesn't hide the button
                            SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 200 : 20),
                          ],
                        ),
                      ),
                    ),
            ),
            IgnorePointer(
              ignoring: true, // Prevents SnowFallAnimation from capturing touch events
              child: SnowFallAnimation(
                config: SnowfallConfig(
                  minSnowflakeSize: isDesktop ? 20 : 12,
                  windForce: 5,
                  numberOfSnowflakes: isDesktop ? 20 : 8,
                  speed: 1.0,
                  useEmoji: true,
                  holdSnowAtBottom: false,
                  customEmojis: ['❄️', '❄️', '🎁', '❄️', '❄️'],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm({required bool isDesktop}) {
    final double fullScreenHeight = MediaQuery.of(context).size.height + MediaQuery.of(context).viewInsets.bottom;

    final double tabViewHeight = isDesktop ? 520 : (fullScreenHeight * 0.55).clamp(450.0, 700.0);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 60 : 16, vertical: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Image.asset('assets/images/mah_logo.png', height: isDesktop ? 100 : 80)),
            SizedBox(height: isDesktop ? 10 : 0),

            // Wrap TabBar in Material to avoid layout/theme issues on some devices
            Material(
              color: Colors.transparent,
              child: TabBar(
                controller: _tabController,
                physics: NeverScrollableScrollPhysics(),
                tabs: const [
                  Tab(text: "Бүртгүүлэх"),
                  Tab(text: "Шалгах"),
                ],
              ),
            ),

            SizedBox(height: isDesktop ? 30 : 20),

            // Constrain the TabBarView height instead of using Expanded
            SizedBox(
              height: tabViewHeight,
              child: TabBarView(
                controller: _tabController,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  _buildFormDetail(isDesktop),
                  _buildCheckTab(isDesktop: isDesktop),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckTab({required bool isDesktop}) {
    return (phoneResults.isNotEmpty)
        ? _buildPhoneResultList(isDesktop: isDesktop)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: isDesktop ? 30 : 20),
              Text("Хэрэглэгч та урамшууллын эрхээ шалгах утасны дугаараа оруулна уу:"),
              SizedBox(height: 10),
              _buildLabelInput(
                "Утасны дугаар",
                checkPhoneController,
                type: TextInputType.phone,
                format: [FilteringTextInputFormatter.digitsOnly],
                maxlength: 8,
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Colors.blue[900],
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: checkready()
                      ? () {
                          // Шалгах үйлдэл энд
                          checkByPhone();
                        }
                      : null,
                  child: Text("Шалгах", style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 35),
              Center(
                child: Text(
                  "МАХ ИМПЭКС ХК",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.blue[900]),
                ),
              ),
            ],
          );
  }

  Widget _buildPhoneResultList({required bool isDesktop}) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: isDesktop ? 30 : 20),
          Text("Таны урамшууллын эрхүүд:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 15),

          // List
          ...phoneResults.map((item) {
            final lotteryNumber = item["lottery_number"];
            final masked = lotteryNumber.substring(0, lotteryNumber.length - 2) + "XX";

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(masked, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            );
          }).toList(),

          const SizedBox(height: 20),

          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: Colors.blue[900],
              ),
              onPressed: () {
                setState(() {
                  phoneResults = [];
                });
              },
              child: const Text("Буцах", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormDetail(bool isDesktop) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(right: 8.0), // prevent overflow from scrollbar on small screens
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              "Шинэ оны мэнд! 🎉\nСугалааны дугаараа бүртгүүлнэ үү",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: isDesktop ? 30 : 20),
          _buildLabelInput(
            "Утасны дугаар",
            phoneController,
            type: TextInputType.phone,
            format: [FilteringTextInputFormatter.digitsOnly],
            maxlength: 8,
          ),
          const SizedBox(height: 18),
          _buildLabelInput("Сугалааны дугаар", lotteryController),
          const SizedBox(height: 18),
          FileInput(
            label: "И-Баримт зураг",
            onFileSelected: (file) {
              myEbarimtFile = file;
              print("Сонгосон файл: ${file?.name}");
            },
          ),
          const SizedBox(height: 18),
          const Text("Хаяг сонгоно уу", style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          AddressDropdown(
            onChanged: ({required cityId, required districtId, required quarterId}) {
              setState(() {
                this.cityId = cityId ?? '';
                this.districtId = districtId ?? '';
                this.quarterId = quarterId ?? '';
              });
              print("CITY=$cityId DISTRICT=$districtId QUARTER=$quarterId");
            },
          ),
          const SizedBox(height: 14),
          Center(
            child: ElevatedButton(
              onPressed: ready()
                  ? () {
                      if (!isSubmitting) {
                        submitLottery();
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: Colors.blue[900],
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: const Text("Сугалаанд оролцох", style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 35),
          Center(
            child: Text(
              "МАХ ИМПЭКС ХК",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.blue[900]),
            ),
          ),
          // Add some bottom spacing so content isn't flush to the bottom
          const SizedBox(height: 5),
        ],
      ),
    );
  }

  Widget _buildLabelInput(String label, TextEditingController controller, {TextInputType? type, List<TextInputFormatter>? format, int? maxlength}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: controller,
            maxLength: maxlength,
            inputFormatters: format,

            keyboardType: type,
            decoration: InputDecoration(border: InputBorder.none, counterText: '', hintText: label == 'Сугалааны дугаар' ? '80-2026XXXXX' : label),
          ),
        ),
      ],
    );
  }

  bool checkready() {
    if (checkPhoneController.text.length == 8) {
      return true;
    } else {
      return false;
    }
  }

  // -------------------------
  // DYNAMIC IMAGE SECTION
  // -------------------------
  Widget _buildDynamicImage({double? height}) {
    return Container(
      height: height ?? 720,
      // width: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: height != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset("assets/images/cover.png", fit: BoxFit.fitHeight),
            )
          : Stack(
              alignment: Alignment.bottomCenter,
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: imageUrls.length,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        print("next");
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Container(
                          color: Colors.blue.withValues(alpha: 0.1),
                          child: Image.asset(imageUrls[index], fit: BoxFit.fitHeight),
                        ),
                      ),
                    );
                  },
                ),

                // ❄ Snow overlay
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(opacity: 0.05, child: Image.asset('assets/images/snow.jpeg', fit: BoxFit.cover)),
                  ),
                ),

                // 🔵 Page indicator
                Positioned(
                  bottom: 16,
                  child: Row(
                    children: List.generate(
                      imageUrls.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 12 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? Colors.white : Colors.white54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
