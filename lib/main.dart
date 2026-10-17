import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ربات‌ساز بله',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A60FF),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

// ---------------------------------------------------------------------------
// مدل داده‌ها برای ذخیره ربات‌ها
// ---------------------------------------------------------------------------
class SavedBot {
  final String id;
  final String trigger;
  final String token;
  final String response;
  final String date;

  SavedBot({
    required this.id,
    required this.trigger,
    required this.token,
    required this.response,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'trigger': trigger,
        'token': token,
        'response': response,
        'date': date,
      };

  factory SavedBot.fromJson(Map<String, dynamic> json) => SavedBot(
        id: json['id'],
        trigger: json['trigger'],
        token: json['token'],
        response: json['response'],
        date: json['date'],
      );
}

// ---------------------------------------------------------------------------
// صفحه اصلی با منوی پایین (۵ تب)
// ---------------------------------------------------------------------------
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const BotBuilderScreen(),
    const AIAssistantScreen(),
    const MyBotsScreen(),
    const TutorialsScreen(),
    const FaqScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.smart_toy), label: 'دستی'),
          NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'هوش مصنوعی'),
          NavigationDestination(icon: Icon(Icons.folder_shared), label: 'ربات‌های من'),
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'آموزش‌ها'),
          NavigationDestination(icon: Icon(Icons.help_outline), label: 'رفع مشکل'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ۱. صفحه ربات‌ساز دستی
// ---------------------------------------------------------------------------
class BotBuilderScreen extends StatefulWidget {
  const BotBuilderScreen({super.key});
  @override
  State<BotBuilderScreen> createState() => _BotBuilderScreenState();
}

class _BotBuilderScreenState extends State<BotBuilderScreen> {
  String selectedTrigger = '/start';
  final TextEditingController tokenController = TextEditingController();
  final TextEditingController responseController = TextEditingController(text: 'سلام! به ربات من خوش آمدی');
  final TextEditingController workerUrlController = TextEditingController();
  String generatedCode = '';
  bool isCopied = false;

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $url')));
    }
  }

  void generateCode() {
    final trigger = selectedTrigger.replaceAll('"', '\\"');
    final response = responseController.text.replaceAll('"', '\\"');
    final token = tokenController.text.trim().isEmpty ? "YOUR_BOT_TOKEN" : tokenController.text.trim();
    final code = '''
export default {
  async fetch(request, env, ctx) {
    if (request.method !== 'POST') return new Response('OK', { status: 200 });
    try {
      const update = await request.json();
      const botToken = "$token";
      const apiUrl = \`https://tapi.bale.ai/bot\${botToken}/\`;
      if (update.message && update.message.text === "$trigger") {
        await fetch(apiUrl + 'sendMessage', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ chat_id: update.message.chat.id, text: "$response" })
        });
      }
      return new Response('OK', { status: 200 });
    } catch (e) { return new Response('Error', { status: 500 }); }
  }
};
''';
    setState(() { generatedCode = code; isCopied = false; });
  }

  Future<void> _saveBot() async {
    if (generatedCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ابتدا کد ربات را بسازید!')));
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final savedBots = prefs.getStringList('saved_bots') ?? [];
    final botData = jsonEncode({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'trigger': selectedTrigger,
      'token': tokenController.text,
      'response': responseController.text,
      'date': DateTime.now().toIso8601String()
    });
    savedBots.add(botData);
    await prefs.setStringList('saved_bots', savedBots);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ربات در «ربات‌های من» ذخیره شد 💾'), backgroundColor: Colors.green));
  }

  void copyToClipboard(String text, {bool isWebhook = false}) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!isWebhook) setState(() => isCopied = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isWebhook ? 'لینک اتصال کپی شد ✅' : 'کد کپی شد ✅'), 
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
    }
    if (!isWebhook) Future.delayed(const Duration(seconds: 2), () { if (mounted) setState(() => isCopied = false); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ربات‌ساز دستی', style: TextStyle(fontWeight: FontWeight.bold)), 
        centerTitle: true, 
        backgroundColor: Colors.white, 
        elevation: 0,
        actions: [IconButton(onPressed: _saveBot, icon: const Icon(Icons.save, color: Color(0xFF4A60FF)), tooltip: 'ذخیره ربات')]
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [Icon(Icons.smart_toy_outlined, color: Color(0xFF4A60FF), size: 28), SizedBox(width: 10), Text('تنظیمات ربات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
            const Divider(height: 30),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('۱. توکن ربات', style: TextStyle(fontWeight: FontWeight.w600)), TextButton.icon(onPressed: () => _launchUrl('https://ble.ir/botfather'), icon: const Icon(Icons.link, size: 16), label: const Text('گرفتن توکن', style: TextStyle(fontSize: 12)))]),
            const SizedBox(height: 8),
            TextField(controller: tokenController, decoration: _inputDecoration('123456789:ABCdefGHI...')),
            const SizedBox(height: 20),
            const Text('۲. شرط پاسخ', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(value: selectedTrigger, decoration: _inputDecoration(''), items: const [DropdownMenuItem(value: '/start', child: Text('/start')), DropdownMenuItem(value: 'سلام', child: Text('سلام')), DropdownMenuItem(value: 'قیمت', child: Text('قیمت'))], onChanged: (val) => setState(() => selectedTrigger = val!)),
            const SizedBox(height: 20),
            const Text('۳. متن پاسخ', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(controller: responseController, maxLines: 3, decoration: _inputDecoration('پاسخ...')),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 52, child: FilledButton.icon(onPressed: generateCode, icon: const Icon(Icons.code), label: const Text('ساخت کد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4A60FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
          ]))),
          const SizedBox(height: 20),
          if (generatedCode.isNotEmpty) ...[
            Container(decoration: BoxDecoration(color: const Color(0xFF1E1E2E), borderRadius: BorderRadius.circular(16)), child: Column(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: const BoxDecoration(color: Color(0xFF181825), borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))), child: Row(children: [const Text('worker.js', style: TextStyle(color: Colors.white70, fontFamily: 'monospace')), const Spacer(), TextButton.icon(onPressed: () => copyToClipboard(generatedCode), icon: Icon(isCopied ? Icons.check_circle : Icons.copy, size: 16, color: isCopied ? Colors.greenAccent : Colors.blueAccent), label: Text(isCopied ? 'کپی شد!' : 'کپی کد', style: TextStyle(color: isCopied ? Colors.greenAccent : Colors.blueAccent, fontSize: 13)))])),
              SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.all(16), child: SelectableText(generatedCode, style: const TextStyle(fontFamily: 'monospace', color: Color(0xFFCDD6F4), fontSize: 13, height: 1.6))),
            ])),
            const SizedBox(height: 24),
            const Text('🔗 اتصال نهایی (Webhook)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('آدرس سایت کلودفلر خود را پیست کنید:', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(controller: workerUrlController, decoration: _inputDecoration('https://your-bot.workers.dev'), onChanged: (_) => setState(() {})),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: (tokenController.text.isEmpty || workerUrlController.text.isEmpty) ? null : () { copyToClipboard('https://tapi.bale.ai/bot${tokenController.text.trim()}/setWebhook?url=${workerUrlController.text.trim()}', isWebhook: true); }, icon: const Icon(Icons.link), label: const Text('کپی لینک اتصال نهایی'), style: FilledButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)))),
          ],
        ]),
      ),
    );
  }
  InputDecoration _inputDecoration(String hint) => InputDecoration(hintText: hint, filled: true, fillColor: Colors.grey.shade50, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)));
}

// ---------------------------------------------------------------------------
// ۲. صفحه هوش مصنوعی (با تزریق توکن هوشمند)
// ---------------------------------------------------------------------------
class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});
  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  // 🔴 آدرس ورکر تستی (کاربر باید آدرس خودش را وارد کند)
  final TextEditingController workerUrlController = TextEditingController(text: 'https://your-worker-name.workers.dev/');
  final TextEditingController promptController = TextEditingController();
  final TextEditingController tokenController = TextEditingController();
  
  String generatedCode = '';
  bool isLoading = false;
  bool isCopied = false;

  Future<void> generateWithAI() async {
    final url = workerUrlController.text.trim();
    final prompt = promptController.text.trim();

    if (url.isEmpty || prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفاً توضیحات ربات را وارد کنید.')));
      return;
    }

    setState(() { isLoading = true; generatedCode = ''; });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': prompt}),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        String rawCode = response.body;
        // پاکسازی کد از بلاک‌های مارک‌داون
        rawCode = rawCode.replaceAll('```javascript', '').replaceAll('```js', '').replaceAll('```', '').trim();
        setState(() { generatedCode = rawCode; });
      } else {
        throw Exception('خطا در سرور: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا در ارتباط: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => isLoading = false);
    }
  }

  // 🪄 تابع هوشمند تزریق توکن
  Future<void> injectTokenAndCopy() async {
    final token = tokenController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفاً توکن ربات را وارد کنید.'), backgroundColor: Colors.orange));
      return;
    }

    String finalCode = generatedCode;
    bool foundPlaceholder = false;

    // بررسی کلمات مختلفی که هوش مصنوعی ممکن است استفاده کرده باشد
    if (finalCode.contains('YOUR_BOT_TOKEN')) {
      finalCode = finalCode.replaceAll('YOUR_BOT_TOKEN', token);
      foundPlaceholder = true;
    } else if (finalCode.contains('YOUR_TOKEN')) {
      finalCode = finalCode.replaceAll('YOUR_TOKEN', token);
      foundPlaceholder = true;
    } else if (finalCode.contains('BOT_TOKEN')) {
      // اگر کد مستقیماً BOT_TOKEN داشت، جایگزین می‌کنیم
      finalCode = finalCode.replaceAll('BOT_TOKEN', token);
      foundPlaceholder = true;
    }

    if (!foundPlaceholder) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('کلمه YOUR_BOT_TOKEN در کد پیدا نشد! کد را دستی بررسی کنید.'), backgroundColor: Colors.orange, duration: Duration(seconds: 4)),
      );
    }

    try {
      // کپی کردن در حافظه
      await Clipboard.setData(ClipboardData(text: finalCode));
      
      setState(() => isCopied = true);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(foundPlaceholder ? 'توکن با موفقیت تزریق و کد کپی شد ✅' : 'کد کپی شد، اما توکن به صورت خودکار تزریق نشد! ⚠️'), 
            backgroundColor: foundPlaceholder ? Colors.green : Colors.orange
          ),
        );
      }
      
      Future.delayed(const Duration(seconds: 2), () { if (mounted) setState(() => isCopied = false); });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا در کپی کردن: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ربات‌ساز هوش مصنوعی', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true, backgroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6), size: 28), SizedBox(width: 10), Text('تولید کد با هوش مصنوعی', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
              const Divider(height: 30),
              const Text('۱. آدرس Worker', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(controller: workerUrlController, decoration: _inputDecoration('https://...'), textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 20),
              const Text('۲. چه رباتی می‌خواهید؟', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(controller: promptController, maxLines: 3, decoration: _inputDecoration('مثلاً: یک ربات با ۳ دکمه شیشه‌ای برای فروشگاه بساز.')),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 52, child: FilledButton.icon(
                onPressed: isLoading ? null : generateWithAI,
                icon: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.auto_awesome),
                label: Text(isLoading ? 'در حال فکر کردن...' : 'ساخت کد با هوش مصنوعی', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              )),
            ]))),
            if (generatedCode.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('🔑 توکن ربات خود را وارد کنید:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(controller: tokenController, decoration: _inputDecoration('123456789:ABCdef...'), textDirection: TextDirection.ltr),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, height: 50, child: FilledButton.icon(
                onPressed: injectTokenAndCopy, 
                icon: Icon(isCopied ? Icons.check : Icons.copy), 
                label: Text(isCopied ? 'کپی شد!' : 'تزریق توکن و کپی کد', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), 
                style: FilledButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))
              )),
              const SizedBox(height: 24),
              const Text('📝 کد تولید شده:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF1E1E2E), borderRadius: BorderRadius.circular(12)), child: SelectableText(generatedCode, style: const TextStyle(fontFamily: 'monospace', color: Color(0xFFCDD6F4), fontSize: 13, height: 1.6))),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
  InputDecoration _inputDecoration(String hint) => InputDecoration(hintText: hint, filled: true, fillColor: Colors.grey.shade50, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)));
}

// ---------------------------------------------------------------------------
// ۳. صفحه ربات‌های من
// ---------------------------------------------------------------------------
class MyBotsScreen extends StatefulWidget {
  const MyBotsScreen({super.key});
  @override
  State<MyBotsScreen> createState() => _MyBotsScreenState();
}

class _MyBotsScreenState extends State<MyBotsScreen> {
  List<SavedBot> savedBots = [];
  bool isLoading = true;

  @override
  void initState() { super.initState(); _loadBots(); }

  Future<void> _loadBots() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final botsJson = prefs.getStringList('saved_bots') ?? [];
    setState(() {
      savedBots = botsJson.map((e) => SavedBot.fromJson(jsonDecode(e))).toList();
      savedBots.sort((a, b) => b.date.compareTo(a.date));
      isLoading = false;
    });
  }

  Future<void> _deleteBot(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final botsJson = prefs.getStringList('saved_bots') ?? [];
    botsJson.removeWhere((element) => SavedBot.fromJson(jsonDecode(element)).id == id);
    await prefs.setStringList('saved_bots', botsJson);
    _loadBots();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ربات حذف شد 🗑️'), backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ربات‌های من', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true, backgroundColor: Colors.white, elevation: 0, actions: [IconButton(onPressed: _loadBots, icon: const Icon(Icons.refresh))]),
      body: isLoading ? const Center(child: CircularProgressIndicator()) : savedBots.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.folder_open, size: 64, color: Colors.grey.shade400), const SizedBox(height: 16), const Text('هنوز هیچ رباتی ذخیره نکرده‌اید!', style: TextStyle(fontSize: 16, color: Colors.grey))])) : ListView.builder(
        padding: const EdgeInsets.all(16), itemCount: savedBots.length, itemBuilder: (context, index) {
          final bot = savedBots[index];
          return Card(margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFFE0E7FF), child: Icon(Icons.smart_toy, color: Color(0xFF4A60FF))),
            title: Text('دستور: ${bot.trigger}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('پاسخ: ${bot.response}', maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _deleteBot(bot.id)),
          ));
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ۴. صفحه آموزش‌ها
// ---------------------------------------------------------------------------
class TutorialsScreen extends StatelessWidget {
  const TutorialsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('آموزش‌های کامل'), backgroundColor: Colors.white, elevation: 0),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _buildAccordion(context, title: 'مرحله ۱: ساخت ربات در بله', icon: Icons.smart_toy, content: 'در پیام‌رسان بله به @BotFather پیام دهید.\nدستور /newbot را ارسال کنید.\nیک نام و یوزرنیم انتخاب کنید.\nتوکن (Token) دریافتی را کپی کنید.'),
        _buildAccordion(context, title: 'مرحله ۲: ثبت‌نام در کلودفلر', icon: Icons.cloud, content: 'وارد سایت dash.cloudflare.com شوید.\nثبت‌نام رایگان کنید.\nاز منوی سمت چپ Workers & Pages را بزنید.'),
        _buildAccordion(context, title: 'مرحله ۳: قرار دادن کد', icon: Icons.code, content: 'یک Worker جدید بسازید.\nکدهای پیش‌فرض را پاک کنید.\nکدی که در این اپ ساختید را پیست کنید.\nدکمه Deploy را بزنید.'),
        _buildAccordion(context, title: 'مرحله ۴: اتصال نهایی', icon: Icons.settings_ethernet, content: 'آدرس سایت Worker را کپی کنید.\nدر تب ربات‌ساز این اپ، آدرس را پیست کنید و لینک اتصال را بگیرید.\nلینک را در مرورگر باز کنید تا پیام "Webhook was set" را ببینید.'),
      ]),
    );
  }
  Widget _buildAccordion(BuildContext context, {required String title, required IconData icon, required String content}) {
    return Card(margin: const EdgeInsets.only(bottom: 12), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade300)), child: Theme(data: Theme.of(context).copyWith(dividerColor: Colors.transparent), child: ExpansionTile(leading: Icon(icon, color: const Color(0xFF4A60FF)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: [Text(content, style: TextStyle(fontSize: 13, height: 1.8, color: Colors.grey.shade800))])));
  }
}

// ---------------------------------------------------------------------------
// ۵. صفحه رفع مشکلات (FAQ)
// ---------------------------------------------------------------------------
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('پرسش‌های متداول'), backgroundColor: Colors.white, elevation: 0),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _buildFaqItem(context, question: 'چرا ربات جواب نمی‌دهد؟', answer: '۱. لینک Webhook را در مرورگر باز کرده‌اید؟\n۲. توکن درست است؟\n۳. کد را در کلودفلر Deploy کرده‌اید؟'),
        _buildFaqItem(context, question: 'آیا کلودفلر هزینه دارد؟', answer: 'خیر، پلن رایگان برای ربات‌های معمولی کاملاً کافی است.'),
        _buildFaqItem(context, question: 'آیا با موبایل می‌شود؟', answer: 'بله، تمام مراحل برای موبایل بهینه‌سازی شده است.'),
      ]),
    );
  }
  Widget _buildFaqItem(BuildContext context, {required String question, required String answer}) {
    return Card(margin: const EdgeInsets.only(bottom: 12), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade300)), child: Theme(data: Theme.of(context).copyWith(dividerColor: Colors.transparent), child: ExpansionTile(leading: const Icon(Icons.help_outline, color: Colors.orange), title: Text(question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: [Text(answer, style: TextStyle(fontSize: 13, height: 1.8, color: Colors.grey.shade800))])));
  }
}