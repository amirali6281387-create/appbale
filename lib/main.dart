import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

// کنترلر مرکزی برای تم (روشن / تاریک)
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // خواندن تم ذخیره شده از حافظه
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? themeStr = prefs.getString('theme_mode');
  if (themeStr == 'dark') {
    themeNotifier.value = ThemeMode.dark;
  } else {
    themeNotifier.value = ThemeMode.light;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'ربات‌ساز بله',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          
          // ☀️ تم روشن
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4A60FF),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
            ),
          ),
          
          // 🌙 تم تاریک
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4A60FF),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF0F172A),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E293B),
              surfaceTintColor: Colors.transparent,
              elevation: 0,
            ),
          ),
          
          home: const MainNavigationScreen(),
        );
      }
    );
  }
}

// تابع تغییر تم و ذخیره آن
Future<void> toggleTheme() async {
  if (themeNotifier.value == ThemeMode.light) {
    themeNotifier.value = ThemeMode.dark;
    (await SharedPreferences.getInstance()).setString('theme_mode', 'dark');
  } else {
    themeNotifier.value = ThemeMode.light;
    (await SharedPreferences.getInstance()).setString('theme_mode', 'light');
  }
}

// ---------------------------------------------------------------------------
// مدل داده‌ها
// ---------------------------------------------------------------------------
class SavedBot {
  final String id;
  final String title;
  final String token;
  final String code;
  final String date;

  SavedBot({
    required this.id,
    required this.title,
    required this.token,
    required this.code,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id, 'title': title, 'token': token, 'code': code, 'date': date,
      };

  factory SavedBot.fromJson(Map<String, dynamic> json) => SavedBot(
        id: json['id'], title: json['title'], token: json['token'], code: json['code'], date: json['date'],
      );
}

// ---------------------------------------------------------------------------
// صفحه اصلی (ناوبری)
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
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.smart_toy_outlined), selectedIcon: Icon(Icons.smart_toy), label: 'دستی'),
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: 'هوش مصنوعی'),
          NavigationDestination(icon: Icon(Icons.folder_outlined), selectedIcon: Icon(Icons.folder), label: 'ربات‌های من'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'آموزش‌ها'),
          NavigationDestination(icon: Icon(Icons.help_outline), selectedIcon: Icon(Icons.help), label: 'رفع مشکل'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ویجت مشترک برای نمایش کد
// ---------------------------------------------------------------------------
class CodeViewer extends StatelessWidget {
  final String code;
  final VoidCallback onCopy;
  final bool isCopied;

  const CodeViewer({super.key, required this.code, required this.onCopy, required this.isCopied});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF1E1E2E), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(color: Color(0xFF181825), borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
            child: Row(
              children: [
                const Text('worker.js', style: TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 13)),
                const Spacer(),
                TextButton.icon(
                  onPressed: onCopy,
                  icon: Icon(isCopied ? Icons.check_circle : Icons.copy, size: 16, color: isCopied ? Colors.greenAccent : Colors.blueAccent),
                  label: Text(isCopied ? 'کپی شد!' : 'کپی کد', style: TextStyle(color: isCopied ? Colors.greenAccent : Colors.blueAccent, fontSize: 13)),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: SelectableText(code, style: const TextStyle(fontFamily: 'monospace', color: Color(0xFFCDD6F4), fontSize: 13, height: 1.5)),
          ),
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطا در باز کردن لینک')));
    }
  }

  void generateCode() {
    if (tokenController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفاً ابتدا توکن ربات را وارد کنید.'), backgroundColor: Colors.orange));
      return;
    }
    final trigger = selectedTrigger.replaceAll('"', '\\"');
    final response = responseController.text.replaceAll('"', '\\"');
    final token = tokenController.text.trim();

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
    if (generatedCode.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final savedBots = prefs.getStringList('saved_bots') ?? [];
    savedBots.add(jsonEncode({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': 'ربات دستی ($selectedTrigger)',
      'token': tokenController.text.trim(),
      'code': generatedCode,
      'date': DateTime.now().toIso8601String()
    }));
    await prefs.setStringList('saved_bots', savedBots);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ربات ذخیره شد 💾'), backgroundColor: Colors.green));
  }

  void copyToClipboard(String text, {bool isWebhook = false}) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!isWebhook) setState(() => isCopied = true);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isWebhook ? 'لینک کپی شد ✅' : 'کد کپی شد ✅'), backgroundColor: Colors.green));
    if (!isWebhook) Future.delayed(const Duration(seconds: 2), () { if (mounted) setState(() => isCopied = false); });
  }

  @override
  void dispose() {
    tokenController.dispose(); responseController.dispose(); workerUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ربات‌ساز دستی', style: TextStyle(fontWeight: FontWeight.bold)), 
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: toggleTheme,
            icon: ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, mode, child) {
                return Icon(mode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode);
              }
            )
          ),
          IconButton(onPressed: _saveBot, icon: const Icon(Icons.save_outlined, color: Color(0xFF4A60FF))),
        ]
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Card(
            elevation: 0,
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).dividerColor)),
            child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.settings, color: Color(0xFF4A60FF)), const SizedBox(width: 8),
                const Text('تنظیمات ربات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(onPressed: () => _launchUrl('https://ble.ir/botfather'), icon: const Icon(Icons.link, size: 16), label: const Text('گرفتن توکن', style: TextStyle(fontSize: 12))),
              ]),
              const Divider(height: 24),
              TextField(controller: tokenController, decoration: _inputDecoration(context, 'توکن ربات (مثلاً 123456:ABC...)')),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(value: selectedTrigger, decoration: _inputDecoration(context, ''), items: const [
                DropdownMenuItem(value: '/start', child: Text('پاسخ به /start')),
                DropdownMenuItem(value: 'سلام', child: Text('پاسخ به سلام')),
                DropdownMenuItem(value: 'قیمت', child: Text('پاسخ به قیمت')),
              ], onChanged: (val) => setState(() => selectedTrigger = val!)),
              const SizedBox(height: 16),
              TextField(controller: responseController, maxLines: 3, decoration: _inputDecoration(context, 'متن پاسخ ربات...')),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 48, child: FilledButton.icon(onPressed: generateCode, icon: const Icon(Icons.code), label: const Text('ساخت کد', style: TextStyle(fontWeight: FontWeight.bold)), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4A60FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
            ])),
          ),
          const SizedBox(height: 20),
          if (generatedCode.isNotEmpty) ...[
            CodeViewer(code: generatedCode, isCopied: isCopied, onCopy: () => copyToClipboard(generatedCode)),
            const SizedBox(height: 20),
            Card(
              elevation: 0,
              color: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).dividerColor)),
              child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('🔗 اتصال نهایی (Webhook)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(controller: workerUrlController, decoration: _inputDecoration(context, 'https://your-bot.workers.dev'), onChanged: (_) => setState(() {})),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: FilledButton.icon(
                  onPressed: (tokenController.text.isEmpty || workerUrlController.text.isEmpty) ? null : () => copyToClipboard('https://tapi.bale.ai/bot${tokenController.text.trim()}/setWebhook?url=${workerUrlController.text.trim()}', isWebhook: true),
                  icon: const Icon(Icons.link), label: const Text('کپی لینک اتصال'), style: FilledButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14))
                )),
              ])),
            )
          ],
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ۲. صفحه هوش مصنوعی
// ---------------------------------------------------------------------------
class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});
  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController workerUrlController = TextEditingController(text: 'https://your-worker-name.workers.dev/');
  final TextEditingController promptController = TextEditingController();
  final TextEditingController tokenController = TextEditingController();
  String generatedCode = '';
  bool isLoading = false;
  bool isCopied = false;

  Future<void> generateWithAI() async {
    final url = workerUrlController.text.trim();
    final prompt = promptController.text.trim();
    if (url.isEmpty || prompt.isEmpty) return;

    setState(() { isLoading = true; generatedCode = ''; });
    try {
      final response = await http.post(Uri.parse(url), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'prompt': prompt})).timeout(const Duration(seconds: 60));
      if (response.statusCode == 200) {
        String rawCode = response.body.replaceAll('```javascript', '').replaceAll('```js', '').replaceAll('```', '').trim();
        setState(() => generatedCode = rawCode);
      } else {
        throw Exception('خطا در سرور');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveBot() async {
    if (generatedCode.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final savedBots = prefs.getStringList('saved_bots') ?? [];
    savedBots.add(jsonEncode({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': 'ربات هوش مصنوعی',
      'token': tokenController.text.trim(),
      'code': generatedCode,
      'date': DateTime.now().toIso8601String()
    }));
    await prefs.setStringList('saved_bots', savedBots);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ربات AI ذخیره شد 💾'), backgroundColor: Colors.green));
  }

  void injectTokenAndCopy() {
    final token = tokenController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفاً توکن ربات را وارد کنید.'), backgroundColor: Colors.orange));
      return;
    }
    final finalCode = generatedCode.replaceAll('YOUR_BOT_TOKEN', token).replaceAll('YOUR_TOKEN', token).replaceAll('BOT_TOKEN', token);
    Clipboard.setData(ClipboardData(text: finalCode));
    setState(() => isCopied = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('توکن جایگزین و کد کپی شد ✅'), backgroundColor: Colors.green));
    Future.delayed(const Duration(seconds: 2), () { if (mounted) setState(() => isCopied = false); });
  }

  @override
  void dispose() {
    workerUrlController.dispose(); promptController.dispose(); tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ربات‌ساز هوش مصنوعی', style: TextStyle(fontWeight: FontWeight.bold)), 
        centerTitle: true, 
        actions: [
          IconButton(
            onPressed: toggleTheme,
            icon: ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, mode, child) {
                return Icon(mode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode);
              }
            )
          ),
          IconButton(onPressed: _saveBot, icon: const Icon(Icons.save_outlined, color: Color(0xFF8B5CF6))),
        ]
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Card(
            elevation: 0,
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).dividerColor)),
            child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6)), SizedBox(width: 8), Text('تولید کد با هوش مصنوعی', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
              const Divider(height: 24),
              TextField(controller: workerUrlController, decoration: _inputDecoration(context, 'آدرس Worker شما'), textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 16),
              TextField(controller: promptController, maxLines: 3, decoration: _inputDecoration(context, 'مثلاً: یک ربات با دکمه شیشه‌ای بساز...')),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 48, child: FilledButton.icon(
                onPressed: isLoading ? null : generateWithAI,
                icon: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.auto_awesome),
                label: Text(isLoading ? 'در حال پردازش...' : 'ساخت کد', style: const TextStyle(fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              )),
            ])),
          ),
          const SizedBox(height: 20),
          if (generatedCode.isNotEmpty) ...[
            Card(
              elevation: 0,
              color: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).dividerColor)),
              child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [
                Expanded(child: TextField(controller: tokenController, decoration: _inputDecoration(context, 'توکن ربات خود را وارد کنید...'), textDirection: TextDirection.ltr)),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: injectTokenAndCopy,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: const Text('کپی'),
                )
              ])),
            ),
            const SizedBox(height: 20),
            CodeViewer(code: generatedCode, isCopied: isCopied, onCopy: injectTokenAndCopy),
          ],
        ]),
      ),
    );
  }
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
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حذف شد 🗑️'), backgroundColor: Colors.redAccent));
  }

  void _showBotDetails(SavedBot bot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(bot.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('توکن: ${bot.token}', style: const TextStyle(color: Colors.grey, fontFamily: 'monospace')),
            const SizedBox(height: 16),
            CodeViewer(
              code: bot.code, 
              isCopied: false, 
              onCopy: () {
                Clipboard.setData(ClipboardData(text: bot.code));
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('کد کپی شد ✅')));
              }
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ربات‌های من', style: TextStyle(fontWeight: FontWeight.bold)), 
        centerTitle: true, 
        actions: [IconButton(onPressed: _loadBots, icon: const Icon(Icons.refresh))]
      ),
      body: isLoading ? const Center(child: CircularProgressIndicator()) : savedBots.isEmpty 
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.folder_open, size: 64, color: Colors.grey.shade400), const SizedBox(height: 16), const Text('هنوز هیچ رباتی ذخیره نکرده‌اید!', style: TextStyle(color: Colors.grey))])) 
        : ListView.builder(
        padding: const EdgeInsets.all(16), itemCount: savedBots.length, itemBuilder: (context, index) {
          final bot = savedBots[index];
          return Card(
            elevation: 0,
            color: Theme.of(context).cardColor,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).dividerColor)),
            child: ListTile(
              onTap: () => _showBotDetails(bot),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: const CircleAvatar(backgroundColor: Color(0xFFE0E7FF), child: Icon(Icons.smart_toy, color: Color(0xFF4A60FF))),
              title: Text(bot.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('برای مشاهده کد کلیک کنید', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _deleteBot(bot.id)),
            ),
          );
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
      appBar: AppBar(title: const Text('آموزش‌های کامل')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _buildAccordion(context, title: 'مرحله ۱: ساخت ربات در بله', icon: Icons.smart_toy, content: 'در پیام‌رسان بله به @BotFather پیام دهید.\nدستور /newbot را ارسال کنید.\nیک نام و یوزرنیم انتخاب کنید.\nتوکن (Token) دریافتی را کپی کنید.'),
        _buildAccordion(context, title: 'مرحله ۲: ثبت‌نام در کلودفلر', icon: Icons.cloud, content: 'وارد سایت dash.cloudflare.com شوید.\nثبت‌نام رایگان کنید.\nاز منوی سمت چپ Workers & Pages را بزنید.'),
        _buildAccordion(context, title: 'مرحله ۳: قرار دادن کد', icon: Icons.code, content: 'یک Worker جدید بسازید.\nکدهای پیش‌فرض را پاک کنید.\nکدی که در این اپ ساختید را پیست کنید.\nدکمه Deploy را بزنید.'),
        _buildAccordion(context, title: 'مرحله ۴: اتصال نهایی', icon: Icons.settings_ethernet, content: 'آدرس سایت Worker را کپی کنید.\nدر تب ربات‌ساز این اپ، آدرس را پیست کنید و لینک اتصال را بگیرید.\nلینک را در مرورگر باز کنید تا پیام "Webhook was set" را ببینید.'),
      ]),
    );
  }
  Widget _buildAccordion(BuildContext context, {required String title, required IconData icon, required String content}) {
    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).dividerColor)),
      child: Theme(data: Theme.of(context).copyWith(dividerColor: Colors.transparent), child: ExpansionTile(
        leading: Icon(icon, color: const Color(0xFF4A60FF)), 
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), 
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16), 
        children: [Text(content, style: TextStyle(fontSize: 13, height: 1.8, color: Theme.of(context).textTheme.bodyMedium?.color))]
      ))
    );
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
      appBar: AppBar(title: const Text('پرسش‌های متداول')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _buildFaqItem(context, question: 'چرا ربات جواب نمی‌دهد؟', answer: '۱. لینک Webhook را در مرورگر باز کرده‌اید؟\n۲. توکن درست است؟\n۳. کد را در کلودفلر Deploy کرده‌اید؟'),
        _buildFaqItem(context, question: 'آیا کلودفلر هزینه دارد؟', answer: 'خیر، پلن رایگان برای ربات‌های معمولی کاملاً کافی است.'),
        _buildFaqItem(context, question: 'آیا با موبایل می‌شود؟', answer: 'بله، تمام مراحل برای موبایل بهینه‌سازی شده است.'),
      ]),
    );
  }
  Widget _buildFaqItem(BuildContext context, {required String question, required String answer}) {
    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).dividerColor)),
      child: Theme(data: Theme.of(context).copyWith(dividerColor: Colors.transparent), child: ExpansionTile(
        leading: const Icon(Icons.help_outline, color: Colors.orange), 
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), 
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16), 
        children: [Text(answer, style: TextStyle(fontSize: 13, height: 1.8, color: Theme.of(context).textTheme.bodyMedium?.color))]
      ))
    );
  }
}

// ---------------------------------------------------------------------------
// ویجت کمکی برای استایل فیلدهای متنی
// ---------------------------------------------------------------------------
InputDecoration _inputDecoration(BuildContext context, String hint) => InputDecoration(
  hintText: hint,
  filled: true,
  fillColor: Theme.of(context).brightness == Brightness.dark 
      ? Colors.grey.shade800.withOpacity(0.3) 
      : Colors.grey.shade50,
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12), 
    borderSide: BorderSide(color: Theme.of(context).dividerColor)
  ),
);