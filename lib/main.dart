import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const demoMode = String.fromEnvironment('APP_MODE', defaultValue: 'connected');
  if (demoMode == 'user' || demoMode == 'admin') {
    runApp(ChatSDemoApp(adminMode: demoMode == 'admin'));
    return;
  }
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ChatSApp());
}

class ChatSDemoApp extends StatefulWidget {
  final bool adminMode;
  const ChatSDemoApp({super.key, required this.adminMode});
  @override
  State<ChatSDemoApp> createState() => _ChatSDemoAppState();
}

class _ChatSDemoAppState extends State<ChatSDemoApp> {
  bool darkMode = true;
  static const gold = Color(0xFFD6B45B);
  @override
  Widget build(BuildContext context) {
    final dark = darkMode;
    return MaterialApp(
      title: widget.adminMode ? 'Chat S Admin' : 'Chat S User',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: dark ? Brightness.dark : Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: gold,
          brightness: dark ? Brightness.dark : Brightness.light,
          surface: dark ? const Color(0xFF1B1B1B) : const Color(0xFFFFFCF5),
        ),
        scaffoldBackgroundColor: dark ? const Color(0xFF101010) : const Color(0xFFF7F4EC),
        appBarTheme: AppBarTheme(
          backgroundColor: dark ? const Color(0xFF101010) : const Color(0xFFF7F4EC),
          foregroundColor: dark ? Colors.white : const Color(0xFF17130D),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: gold, foregroundColor: Colors.black,
        ),
      ),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: widget.adminMode
          ? DemoAdminHome(onToggleTheme: () => setState(() => darkMode = !darkMode), darkMode: dark)
          : DemoUserHome(onToggleTheme: () => setState(() => darkMode = !darkMode), darkMode: dark),
      ),
    );
  }
}

const _demoNames = ['أحمد محمد', 'العائلة ❤️', 'ليلى', 'فريق العمل', 'يوسف'];
const _demoMessages = ['وصلت البيت؟', 'مساء الخير جميعاً', 'شكراً لك، إلى اللقاء!', 'تم إرسال الملف', 'هل نتحدث لاحقاً؟'];

class DemoUserHome extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool darkMode;
  const DemoUserHome({super.key, required this.onToggleTheme, required this.darkMode});
  @override
  State<DemoUserHome> createState() => _DemoUserHomeState();
}

class _DemoUserHomeState extends State<DemoUserHome> {
  int tab = 0;
  final search = TextEditingController();
  final List<String> names = List<String>.from(_demoNames);
  final List<String> previews = List<String>.from(_demoMessages);
  @override
  void dispose() { search.dispose(); super.dispose(); }

  void notice(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final pages = [_chats(), _stories(), _calls(), _groups(), _settings()];
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFFD6B45B), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.chat_bubble, color: Colors.black)),
          const SizedBox(width: 10),
          const Text('Chat S', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(width: 8),
          const Chip(label: Text('نسخة تجريبية', style: TextStyle(fontSize: 10)), visualDensity: VisualDensity.compact),
        ]),
        actions: [IconButton(onPressed: widget.onToggleTheme, icon: Icon(widget.darkMode ? Icons.light_mode : Icons.dark_mode)),],
      ),
      body: IndexedStack(index: tab, children: pages),
      floatingActionButton: tab == 0 ? FloatingActionButton(
        onPressed: () => _newChat(), child: const Icon(Icons.edit_square),
      ) : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'الدردشات'),
          NavigationDestination(icon: Icon(Icons.circle_outlined), label: 'الحالات'),
          NavigationDestination(icon: Icon(Icons.call_outlined), label: 'المكالمات'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), label: 'المجموعات'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'الإعدادات'),
        ],
      ),
    );
  }

  Widget _chats() {
    final filtered = List.generate(names.length, (i) => i).where((i) =>
      names[i].contains(search.text) || previews[i].contains(search.text)).toList();
    return Column(children: [
      Padding(padding: const EdgeInsets.all(14), child: TextField(
        controller: search, onChanged: (_) => setState(() {}),
        decoration: InputDecoration(hintText: 'ابحث عن محادثة أو صديق', prefixIcon: const Icon(Icons.search),
          filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none)),
      )),
      SizedBox(height: 105, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12),
        children: ['قصتي','سارة','أحمد','ليلى','يوسف'].asMap().entries.map((e) => SizedBox(width: 72, child: Column(children: [
          Container(padding: const EdgeInsets.all(3), decoration: BoxDecoration(shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFD6B45B), width: 2)),
            child: CircleAvatar(radius: 25, child: Icon(e.key == 0 ? Icons.add : Icons.person))),
          const SizedBox(height: 5), Text(e.value, style: const TextStyle(fontSize: 11)),
        ]))).toList(),
      )),
      const Padding(padding: EdgeInsets.symmetric(horizontal: 18, vertical: 5), child: Align(alignment: Alignment.centerRight,
        child: Text('أحدث المحادثات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)))),
      Expanded(child: ListView.separated(itemCount: filtered.length, separatorBuilder: (_, __) => const Divider(indent: 80, height: 1),
        itemBuilder: (context, index) { final i = filtered[index]; return ListTile(
          leading: CircleAvatar(backgroundColor: const Color(0xFF6B5730), child: Text(names[i].substring(0,1))),
          title: Text(names[i]), subtitle: Text(previews[i], maxLines: 1), trailing: const Text('الآن', style: TextStyle(fontSize: 11)),
          onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) =>
            DemoConversationScreen(name: names[i], onLastMessage: (m) => setState(() => previews[i] = m))); },
        ); },
      )),
    ]);
  }

  Widget _stories() => _featurePage(Icons.auto_awesome, 'حالات الأصدقاء', [
    'نشر صورة أو فيديو أو نص',
    'مشاهدة الحالات لمدة 24 ساعة',
    'قائمة المشاهدين والتحكم بالخصوصية',
    'الرد على الحالة والتفاعل معها',
  ], 'هذه بيانات تجريبية للمعاينة فقط.');
  Widget _calls() => _featurePage(Icons.video_call, 'مركز المكالمات', [
    'مكالمات صوتية فردية',
    'مكالمات فيديو مع تبديل الكاميرا',
    'مكالمات جماعية',
    'سجل المكالمات والمكالمات الفائتة',
    'مشاركة الشاشة وكتم الصوت',
  ], 'أزرار الاتصال تجريبية ولا تنشئ اتصالاً حقيقياً.');
  Widget _groups() => _featurePage(Icons.groups, 'المجموعات والقنوات', [
    'إنشاء مجموعات وإضافة أعضاء',
    'مشرفون وصلاحيات وإدارة الأعضاء',
    'قنوات عامة وخاصة',
    'روابط دعوة وتثبيت الرسائل',
  ], 'يمكنك استعراض شكل الأقسام قبل ربط الخادم.');
  Widget _settings() => ListView(padding: const EdgeInsets.all(16), children: [
    const ListTile(leading: CircleAvatar(child: Icon(Icons.person)), title: Text('مستخدم Chat S'), subtitle: Text('حساب محلي تجريبي')),
    const Divider(),
    ListTile(leading: const Icon(Icons.palette), title: const Text('المظهر'), subtitle: const Text('تبديل الوضع الفاتح والداكن'), onTap: widget.onToggleTheme),
    ...[
      ['الخصوصية والأمان', Icons.lock], ['الأجهزة المرتبطة', Icons.devices],
      ['النسخ الاحتياطي', Icons.backup], ['الملصقات والرموز', Icons.emoji_emotions],
      ['اللغة', Icons.language], ['حول Chat S', Icons.info_outline],
    ].map((e) => ListTile(leading: Icon(e[1] as IconData), title: Text(e[0] as String), onTap: () => notice('معاينة تجريبية: ${e[0]}'))),
  ]);

  Widget _featurePage(IconData icon, String title, List<String> features, String note) => ListView(padding: const EdgeInsets.all(18), children: [
    Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(colors: [Color(0xFF3B2D13), Color(0xFF17130D)])),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 38, color: const Color(0xFFD6B45B)), const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8), const Text('استكشف تجربة Chat S الجديدة', style: TextStyle(color: Colors.white70)),
      ]),
    ),
    const SizedBox(height: 18),
    ...features.map((f) => Card(child: ListTile(leading: const Icon(Icons.check_circle_outline, color: Color(0xFFD6B45B)), title: Text(f)))),
    const SizedBox(height: 12), Text(note, style: const TextStyle(color: Colors.grey)),
  ]);

  void _newChat() {
    final input = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('محادثة تجريبية جديدة'),
      content: TextField(controller: input, decoration: const InputDecoration(hintText: 'اسم الصديق')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        FilledButton(onPressed: () { final n=input.text.trim(); if(n.isNotEmpty) setState(() { names.insert(0,n); previews.insert(0,'ابدأ المحادثة الآن'); }); Navigator.pop(ctx); },
          child: const Text('إنشاء')),
      ],
    ));
  }
}

class DemoConversationScreen extends StatefulWidget {
  final String name;
  final ValueChanged<String> onLastMessage;
  const DemoConversationScreen({super.key, required this.name, required this.onLastMessage});
  @override
  State<DemoConversationScreen> createState() => _DemoConversationScreenState();
}

class _DemoConversationScreenState extends State<DemoConversationScreen> {
  final input = TextEditingController();
  final messages = <Map<String, String>>[
    {'type':'text','text':'مرحباً! أهلاً بك في محادثة Chat S التجريبية.'},
    {'type':'text','text':'يمكنك تجربة إرسال الرسائل والمقاطع الصوتية هنا.'},
  ];
  bool recording = false;
  int seconds = 0;
  @override
  void dispose() { input.dispose(); super.dispose(); }

  void _send() { final t=input.text.trim(); if(t.isEmpty) return; setState(() { messages.add({'type':'text','text':t}); input.clear(); }); widget.onLastMessage(t); }
  void _record() {
    setState(() { recording = !recording; seconds = 0; });
    if (recording) {
      Future.doWhile(() async { await Future.delayed(const Duration(seconds: 1)); if(!mounted || !recording) return false; setState(() => seconds++); return true; });
    } else {
      setState(() => messages.add({'type':'voice','text':'مقطع صوتي تجريبي • ${seconds} ثانية'}));
      widget.onLastMessage('🎙 مقطع صوتي تجريبي');
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Row(children: [const CircleAvatar(child: Icon(Icons.person)), const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.name, style: const TextStyle(fontSize: 16)), const Text('متصل • وضع تجريبي', style: TextStyle(fontSize: 11, color: Colors.green))])]),
      actions: [IconButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('المكالمة غير مفعلة في وضع المعاينة'))), icon: const Icon(Icons.call)),
        IconButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('مكالمة الفيديو غير مفعلة في وضع المعاينة'))), icon: const Icon(Icons.videocam))]),
    body: Column(children: [
      Expanded(child: ListView.builder(padding: const EdgeInsets.all(14), itemCount: messages.length, itemBuilder: (_,i) {
        final m=messages[i]; final voice=m['type']=='voice';
        return Align(alignment: i.isEven ? Alignment.centerRight : Alignment.centerLeft, child: Container(
          margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(color: i.isEven ? const Color(0xFF51401D) : Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if(voice) const Icon(Icons.play_circle_fill, color: Color(0xFFD6B45B)),
            if(voice) const SizedBox(width: 7),
            Flexible(child: Text(m['text']!)),
          ]),
        ));
      })),
      if(recording) Container(width: double.infinity, padding: const EdgeInsets.all(10), color: Colors.red.withValues(alpha:.12),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.fiber_manual_record, color: Colors.red, size: 13),
          const SizedBox(width: 8), Text('جارٍ التسجيل التجريبي 00:${seconds.toString().padLeft(2,'0')}') ])),
      SafeArea(child: Padding(padding: const EdgeInsets.all(9), child: Row(children: [
        IconButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('المرفقات ستعمل بعد ربط الخدمات'))), icon: const Icon(Icons.add_circle_outline, color: Color(0xFFD6B45B))),
        Expanded(child: TextField(controller: input, decoration: InputDecoration(hintText: 'اكتب رسالة...', filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none)))),
        IconButton(onPressed: _record, icon: Icon(recording ? Icons.stop_circle : Icons.mic, color: recording ? Colors.red : const Color(0xFFD6B45B), size: 29)),
        IconButton(onPressed: _send, icon: const Icon(Icons.send, color: Color(0xFFD6B45B))),
      ]))),
    ]),
  );
}

class DemoAdminHome extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool darkMode;
  const DemoAdminHome({super.key, required this.onToggleTheme, required this.darkMode});
  @override
  State<DemoAdminHome> createState() => _DemoAdminHomeState();
}

class _DemoAdminHomeState extends State<DemoAdminHome> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [_dashboard(), _users(), _reports(), _adminSettings()];
    return Scaffold(
      appBar: AppBar(title: Row(children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFFD6B45B), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.admin_panel_settings, color: Colors.black)),
        const SizedBox(width: 10), const Text('Chat S Admin', style: TextStyle(fontWeight: FontWeight.w900)),
      ]), actions: [IconButton(onPressed: widget.onToggleTheme, icon: Icon(widget.darkMode ? Icons.light_mode : Icons.dark_mode))]),
      body: IndexedStack(index: tab, children: pages),
      bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (v)=>setState(()=>tab=v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'المستخدمون'),
          NavigationDestination(icon: Icon(Icons.flag_outlined), label: 'البلاغات'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'الإعدادات'),
        ]),
    );
  }

  Widget _dashboard() => ListView(padding: const EdgeInsets.all(16), children: [
    Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(colors: [Color(0xFF493817), Color(0xFF17130D)])),
      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('لوحة تحكم Chat S', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
        SizedBox(height: 7), Text('وضع إدارة تجريبي • البيانات محلية وغير متصلة بالخادم', style: TextStyle(color: Colors.white70)),
      ]),
    ),
    const SizedBox(height: 16),
    GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, childAspectRatio: 1.45, crossAxisSpacing: 10, mainAxisSpacing: 10,
      children: [
        _stat('المستخدمون', '1,248', Icons.people),
        _stat('المحادثات', '3,820', Icons.chat),
        _stat('البلاغات', '12', Icons.flag),
        _stat('المجموعات', '86', Icons.groups),
      ]),
    const SizedBox(height: 18), const Text('أدوات الإدارة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    _action('إدارة المستخدمين', Icons.manage_accounts, ()=>setState(()=>tab=1)),
    _action('مراجعة البلاغات', Icons.report, ()=>setState(()=>tab=2)),
    _action('إدارة المجموعات والقنوات', Icons.forum, ()=>_notice('معاينة إدارة المجموعات')),
    _action('رسائل الدعم الفني', Icons.support_agent, ()=>_notice('معاينة صندوق الدعم')),
    _action('إعدادات التطبيق', Icons.tune, ()=>setState(()=>tab=3)),
  ]);
  Widget _stat(String title,String value,IconData icon)=>Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children:[Icon(icon,color:const Color(0xFFD6B45B)), Text(value,style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)), Text(title,style:const TextStyle(color:Colors.grey))])));
  Widget _users()=>ListView(padding: const EdgeInsets.all(12), children: [
    const Padding(padding: EdgeInsets.all(8), child: Text('إدارة المستخدمين التجريبية', style: TextStyle(fontSize: 19,fontWeight: FontWeight.bold))),
    ...['أحمد محمد','سارة علي','يوسف خالد','ليلى حسن','محمد أمين'].map((n)=>Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text(n), subtitle: const Text('حساب تجريبي • نشط'),
      trailing: PopupMenuButton<String>(onSelected: (v)=>_notice('$v • ${n} (تجريبي)'), itemBuilder: (_)=>const [PopupMenuItem(value:'عرض الملف',child:Text('عرض الملف')),PopupMenuItem(value:'تعليق الحساب',child:Text('تعليق الحساب')),PopupMenuItem(value:'توثيق الحساب',child:Text('توثيق الحساب'))])))),
  ]);
  Widget _reports()=>ListView(padding: const EdgeInsets.all(12), children: [
    const Padding(padding: EdgeInsets.all(8), child: Text('مراجعة البلاغات', style: TextStyle(fontSize: 19,fontWeight: FontWeight.bold))),
    ...['محتوى غير مناسب','إزعاج متكرر','حساب مزيف','رسائل مزعجة'].map((n)=>Card(child: ListTile(leading: const Icon(Icons.flag,color:Colors.orange), title: Text(n), subtitle: const Text('بلاغ تجريبي • قيد المراجعة'),
      trailing: PopupMenuButton<String>(onSelected: (v)=>_notice('$v • تم تسجيله محلياً'), itemBuilder: (_)=>const [PopupMenuItem(value:'قبول البلاغ',child:Text('قبول البلاغ')),PopupMenuItem(value:'رفض البلاغ',child:Text('رفض البلاغ'))])))),
  ]);
  Widget _adminSettings()=>ListView(children: [
    ListTile(leading: const Icon(Icons.palette), title: const Text('المظهر'), subtitle: const Text('تبديل الوضع الفاتح والداكن'), onTap: widget.onToggleTheme),
    const ListTile(leading: Icon(Icons.security), title: Text('الأمان والصلاحيات'), subtitle: Text('إعدادات معاينة فقط')),
    const ListTile(leading: Icon(Icons.analytics), title: Text('إحصائيات النظام'), subtitle: Text('بيانات توضيحية وليست مباشرة')),
    const ListTile(leading: Icon(Icons.backup), title: Text('النسخ الاحتياطي'), subtitle: Text('سيتم ربطه لاحقاً')),
  ]);
  Widget _action(String title,IconData icon,VoidCallback onTap)=>Card(child:ListTile(leading:Icon(icon,color:const Color(0xFFD6B45B)),title:Text(title),trailing:const Icon(Icons.chevron_left),onTap:onTap));
  void _notice(String text)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(text)));
}


const Color brandGreen = Color(0xFFD6B45B); // هوية Chat S الذهبية
const Color pageColor = Color(0xFF101010);
const Color panelColor = Color(0xFF1B1B1B);

class ChatSApp extends StatelessWidget {
  const ChatSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat S',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: pageColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD6B45B),
          brightness: Brightness.dark,
          surface: panelColor,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) return const HomeScreen();
        return const PhoneLoginScreen();
      },
    );
  }
}

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  String? _verificationId;
  int? _resendToken;
  bool _codeSent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'رقم الهاتف غير صحيح. أدخل الرقم مع مفتاح الدولة مثل +33612345678.';
      case 'too-many-requests':
        return 'تم إرسال طلبات كثيرة. حاول مرة أخرى لاحقاً.';
      case 'quota-exceeded':
        return 'تم تجاوز الحد المسموح لرسائل التحقق حالياً.';
      case 'invalid-verification-code':
        return 'رمز التحقق غير صحيح. حاول مرة أخرى.';
      case 'session-expired':
        return 'انتهت صلاحية الرمز. اطلب رمزاً جديداً.';
      case 'network-request-failed':
        return 'تعذر الاتصال بالإنترنت. تحقق من اتصالك وحاول مجدداً.';
      default:
        return e.message ?? 'حدث خطأ أثناء التحقق. حاول مرة أخرى.';
    }
  }

  Future<void> _sendCode({bool resend = false}) async {
    final phone = _phoneController.text.trim().replaceAll(' ', '');
    if (!phone.startsWith('+') || phone.length < 8) {
      setState(() => _error = 'أدخل رقم الهاتف كاملاً مع مفتاح الدولة، مثال: +33612345678');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        forceResendingToken: resend ? _resendToken : null,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
          } on FirebaseAuthException catch (e) {
            if (mounted) setState(() => _error = _friendlyError(e));
          }
        },
        verificationFailed: (e) {
          if (mounted) setState(() { _busy = false; _error = _friendlyError(e); });
        },
        codeSent: (verificationId, resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _codeSent = true;
            _busy = false;
          });
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() { _busy = false; _error = _friendlyError(e); });
    } catch (_) {
      if (mounted) setState(() { _busy = false; _error = 'تعذر إرسال الرمز. تحقق من الرقم والإنترنت.'; });
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6 || _verificationId == null) {
      setState(() => _error = 'أدخل رمز التحقق المكوّن من 6 أرقام.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() { _busy = false; _error = _friendlyError(e); });
    } catch (_) {
      if (mounted) setState(() { _busy = false; _error = 'تعذر التحقق من الرمز. حاول مجدداً.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 72, height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: brandGreen, borderRadius: BorderRadius.circular(22)),
                    child: const Icon(Icons.chat_bubble_rounded, color: Colors.black, size: 38),
                  ),
                  const SizedBox(height: 28),
                  const Text('مرحباً بك في Chat S',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Text(
                    _codeSent ? 'أدخل رمز التحقق الذي أرسلناه إلى هاتفك' : 'سجّل الدخول باستخدام رقم هاتفك',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white60, height: 1.6)),
                  const SizedBox(height: 30),
                  if (!_codeSent) ...[
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.left,
                      decoration: InputDecoration(
                        labelText: 'رقم الهاتف مع مفتاح الدولة',
                        hintText: '+33612345678',
                        prefixIcon: const Icon(Icons.phone_android),
                        filled: true, fillColor: panelColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: 'رمز التحقق SMS',
                        hintText: '••••••',
                        counterText: '',
                        prefixIcon: const Icon(Icons.lock_outline),
                        filled: true, fillColor: panelColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _busy ? null : () => setState(() { _codeSent = false; _error = null; }),
                        child: const Text('تغيير رقم الهاتف'),
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent)),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy ? null : (_codeSent ? _verifyCode : _sendCode),
                    style: FilledButton.styleFrom(
                      backgroundColor: brandGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _busy
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_codeSent ? 'تأكيد الرمز وتسجيل الدخول' : 'إرسال رمز التحقق',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  if (_codeSent) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _busy ? null : () => _sendCode(resend: true),
                      child: const Text('إعادة إرسال الرمز'),
                    ),
                  ],
                  const SizedBox(height: 18),
                  const Text('باستخدامك التطبيق، ستتلقى رسالة SMS للتحقق من ملكية رقمك.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.5)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ChatPreview {
  final String name;
  final String message;
  final String time;
  final String initials;
  final int unread;
  final Color color;
  const ChatPreview(this.name, this.message, this.time, this.initials,
      this.unread, this.color);
}

const chats = [
  ChatPreview('أحمد محمد', 'وصلت البيت؟', 'الآن', 'أم', 2, Color(0xFF286B55)),
  ChatPreview('العائلة ❤️', 'سارة: مساء الخير جميعاً', '12:42', 'ع', 5, Color(0xFF74533A)),
  ChatPreview('ليلى', 'شكراً لك، إلى اللقاء!', 'أمس', 'ل', 0, Color(0xFF62518A)),
  ChatPreview('فريق العمل', 'تم إرسال الملف', 'أمس', 'ف', 0, Color(0xFF42617A)),
  ChatPreview('يوسف', 'مكالمة فائتة', 'الأحد', 'ي', 0, Color(0xFF80505A)),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int tab = 0;
  final search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ensureUserProfile();
  }

  Future<void> _ensureUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'uid': user.uid,
        'displayName': 'مستخدم Chat S',
        'bio': '',
        'photoUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['المحادثات', 'الحالات', 'المكالمات', 'المجموعات', 'الإعدادات'];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: pageColor,
        titleSpacing: 20,
        title: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: brandGreen, borderRadius: BorderRadius.circular(13)),
            child: const Icon(Icons.chat_bubble_rounded, color: Colors.black, size: 22),
          ),
          const SizedBox(width: 11),
          const Text('Chat S', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: .3)),
        ]),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.camera_alt_outlined)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
          const SizedBox(width: 6),
        ],
      ),
      body: IndexedStack(index: tab, children: [
        _chatsPage(),
        _emptyPage(Icons.circle_outlined, 'حالاتك', 'شارك لحظاتك مع أصدقائك قريباً'),
        _callsPage(),
        _groupsPage(),
        _settingsPage(),
      ]),
      floatingActionButton: tab == 0
          ? FloatingActionButton(
              backgroundColor: brandGreen,
              foregroundColor: Colors.black,
              onPressed: () => _showNotice('ستتوفر جهات الاتصال بعد ربط الحساب.'),
              child: const Icon(Icons.edit_square),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        backgroundColor: panelColor,
        indicatorColor: brandGreen.withValues(alpha: .18),
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'الدردشات'),
          NavigationDestination(icon: Icon(Icons.circle_outlined), label: 'الحالات'),
          NavigationDestination(icon: Icon(Icons.call_outlined), label: 'المكالمات'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), label: 'المجموعات'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'الإعدادات'),
        ],
      ),
    );
  }

  Widget _chatsPage() {
    final filtered = chats.where((c) =>
      c.name.contains(search.text) || c.message.contains(search.text)).toList();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: TextField(
          controller: search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'ابحث في المحادثات',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: panelColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
          ),
        ),
      ),
      _storiesStrip(),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        child: Row(children: [
          const Text('رسائلك', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text('${filtered.length} محادثات', style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ]),
      ),
      const SizedBox(height: 8),
      Expanded(child: ListView.separated(
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 86, endIndent: 18, color: Colors.white10),
        itemBuilder: (context, index) {
          final chat = filtered[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
            leading: CircleAvatar(
              radius: 27,
              backgroundColor: chat.color,
              child: Text(chat.initials, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            title: Text(chat.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(chat.message, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60)),
            ),
            trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(chat.time, style: const TextStyle(color: Colors.white54, fontSize: 11)),
              const SizedBox(height: 7),
              if (chat.unread > 0)
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(color: brandGreen, shape: BoxShape.circle),
                  child: Text('${chat.unread}', style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ]),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => Directionality(textDirection: TextDirection.rtl, child: ConversationScreen(chat: chat)),
            )),
          );
        },
      )),
    ]);
  }


  Widget _storiesStrip() => SizedBox(
    height: 112,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 12),
      children: [
        _storyItem('قصتي', Icons.add, true),
        _storyItem('سارة', Icons.face_rounded, false),
        _storyItem('أحمد', Icons.person, false),
        _storyItem('ليلى', Icons.face_3, false),
        _storyItem('يوسف', Icons.person_rounded, false),
      ],
    ),
  );

  Widget _storyItem(String name, IconData icon, bool own) => Padding(
    padding: const EdgeInsetsDirectional.only(end: 15),
    child: SizedBox(width: 62, child: Column(children: [
      Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: own ? Colors.white24 : brandGreen, width: 2),
        ),
        child: CircleAvatar(
          radius: 25,
          backgroundColor: panelColor,
          child: Icon(icon, color: brandGreen, size: 25),
        ),
      ),
      const SizedBox(height: 6),
      Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, color: Colors.white70)),
    ])),
  );

  Widget _callsPage() => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF302514), Color(0xFF17130D)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: brandGreen.withValues(alpha: .35)),
        ),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.call, color: brandGreen, size: 30),
          SizedBox(height: 12),
          Text('مكالمات Chat S', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          Text('مكالمات صوتية ومرئية بجودة عالية — ستُفعّل خدمة الاتصال في مرحلة لاحقة.',
            style: TextStyle(color: Colors.white70, height: 1.5)),
        ]),
      ),
      const SizedBox(height: 22),
      const Text('مميزات المكالمات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      const SizedBox(height: 10),
      _featureTile(Icons.call_outlined, 'مكالمة صوتية', 'تواصل صوتي عبر الإنترنت'),
      _featureTile(Icons.video_call_outlined, 'مكالمة فيديو', 'رؤية الأصدقاء بوضوح'),
      _featureTile(Icons.groups_outlined, 'مكالمات جماعية', 'اجمع أصدقاءك في مكالمة واحدة'),
      _featureTile(Icons.screen_share_outlined, 'مشاركة الشاشة', 'شارك ما يظهر على هاتفك'),
    ],
  );

  Widget _groupsPage() => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: brandGreen.withValues(alpha: .25)),
        ),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.groups_rounded, color: brandGreen, size: 34),
          SizedBox(height: 12),
          Text('مجتمعاتك في مكان واحد', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          Text('أنشئ مجموعات للأصدقاء والعائلة والعمل، مع أدوات للمشرفين وإدارة الأعضاء.',
            style: TextStyle(color: Colors.white60, height: 1.5)),
        ]),
      ),
      const SizedBox(height: 18),
      _featureTile(Icons.group_add_outlined, 'إنشاء مجموعة', 'ابدأ مجموعة جديدة مع أصدقائك'),
      _featureTile(Icons.campaign_outlined, 'القنوات', 'تابع القنوات العامة والخاصة'),
      _featureTile(Icons.admin_panel_settings_outlined, 'إدارة الأعضاء', 'صلاحيات للمشرفين وأدوات تنظيم'),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: () => _showNotice('سيتم ربط إنشاء المجموعات بقاعدة البيانات في المرحلة التالية.'),
        icon: const Icon(Icons.add),
        label: const Text('إنشاء مجموعة جديدة'),
      ),
    ],
  );

  Widget _featureTile(IconData icon, String title, String subtitle) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 3),
    leading: Container(
      width: 44, height: 44,
      decoration: BoxDecoration(color: brandGreen.withValues(alpha: .13), borderRadius: BorderRadius.circular(14)),
      child: Icon(icon, color: brandGreen),
    ),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54)),
  );

  Widget _emptyPage(IconData icon, String title, String subtitle) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 58, color: brandGreen),
      const SizedBox(height: 16),
      Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text(subtitle, style: const TextStyle(color: Colors.white54)),
    ]),
  );

  Widget _settingsPage() {
    final user = FirebaseAuth.instance.currentUser!;
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final name = (data['displayName'] as String?) ?? user.phoneNumber ?? 'حسابي';
        return ListView(padding: const EdgeInsets.all(18), children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 27,
              backgroundColor: brandGreen,
              backgroundImage: (data['photoUrl'] as String?)?.isNotEmpty == true
                  ? NetworkImage(data['photoUrl'] as String) : null,
              child: (data['photoUrl'] as String?)?.isNotEmpty == true
                  ? null : const Icon(Icons.person, color: Colors.black),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('عرض وتعديل ملفك الشخصي'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const UserProfileScreen(),
            )),
          ),
          const Divider(color: Colors.white12),
          _setting(Icons.lock_outline, 'الخصوصية'),
          _setting(Icons.notifications_none, 'الإشعارات'),
          _setting(Icons.language, 'اللغة'),
          FutureBuilder<IdTokenResult>(
            future: user.getIdTokenResult(),
            builder: (context, claimSnapshot) {
              if (claimSnapshot.data?.claims?['admin'] != true) return const SizedBox.shrink();
              return ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: Color(0xFFFFD54F)),
                title: const Text('صندوق الدعم الفني'),
                subtitle: const Text('الرد على رسائل المستخدمين'),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportInboxScreen())),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.support_agent, color: brandGreen),
            title: const Text('الدعم الفني'),
            subtitle: const Text('أرسل مشكلة أو تواصل مع فريق الدعم'),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const SupportChatScreen(),
            )),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('تسجيل الخروج'),
            onTap: () async { await FirebaseAuth.instance.signOut(); },
          ),
          const SizedBox(height: 22),
          const Center(child: Text('Chat S • إصدار 1.3.0', style: TextStyle(color: Colors.white38))),
        ]);
      },
    );
  }

  Widget _setting(IconData icon, String label) => ListTile(
    leading: Icon(icon, color: brandGreen), title: Text(label),
    trailing: const Icon(Icons.chevron_left, color: Colors.white38),
    onTap: () => _showNotice('سيتم تفعيل هذا القسم في التحديث القادم.'),
  );

  void _showNotice(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class ConversationScreen extends StatefulWidget {
  final ChatPreview chat;
  const ConversationScreen({super.key, required this.chat});
  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final controller = TextEditingController();
  final messages = <String>['مرحباً! كيف حالك؟', 'أهلاً، أنا بخير الحمد لله 😊'];
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Row(children: [
        CircleAvatar(backgroundColor: widget.chat.color, child: Text(widget.chat.initials)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.chat.name, style: const TextStyle(fontSize: 16)),
          const Text('معاينة تجريبية', style: TextStyle(fontSize: 11, color: Colors.white54)),
        ]),
      ]),
      actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.call_outlined)), IconButton(onPressed: () {}, icon: const Icon(Icons.videocam_outlined))],
    ),
    body: Column(children: [
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: messages.length,
        itemBuilder: (_, i) => Align(
          alignment: i.isEven ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
            constraints: const BoxConstraints(maxWidth: 290),
            decoration: BoxDecoration(
              color: i.isEven ? const Color(0xFF174D39) : panelColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(messages[i]),
          ),
        ),
      )),
      SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
        child: Row(children: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.add, color: brandGreen)),
          Expanded(child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'اكتب رسالة...',
              filled: true, fillColor: panelColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
          )),
          const SizedBox(width: 7),
          CircleAvatar(backgroundColor: brandGreen, child: IconButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              setState(() { messages.add(controller.text.trim()); controller.clear(); });
            },
            icon: const Icon(Icons.send_rounded, color: Colors.black, size: 19),
          )),
        ]),
      )),
    ]),
  );
}


// ملف المستخدم: الاسم والصورة والنبذة. لا يسمح التطبيق بتعديل شارة التوثيق.
class UserProfileScreen extends StatefulWidget {
  final String? userId;
  const UserProfileScreen({super.key, this.userId});
  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final name = TextEditingController();
  final bio = TextEditingController();
  bool loading = true;
  bool saving = false;
  Map<String, dynamic> data = {};

  String get uid => widget.userId ?? FirebaseAuth.instance.currentUser!.uid;
  bool get isOwn => uid == FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    data = snap.data() ?? {};
    name.text = (data['displayName'] as String?) ?? '';
    bio.text = (data['bio'] as String?) ?? '';
    if (mounted) setState(() => loading = false);
  }

  Future<void> _save() async {
    if (name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب اسمك أولاً')));
      return;
    }
    setState(() => saving = true);
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'uid': uid,
      'displayName': name.text.trim(),
      'bio': bio.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (mounted) setState(() => saving = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الملف الشخصي')));
  }

  @override
  void dispose() { name.dispose(); bio.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final verified = data['isVerifiedSupport'] == true;
    return Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي')),
      body: ListView(padding: const EdgeInsets.all(22), children: [
        const SizedBox(height: 18),
        Center(child: CircleAvatar(
          radius: 48,
          backgroundColor: brandGreen,
          backgroundImage: (data['photoUrl'] as String?)?.isNotEmpty == true
              ? NetworkImage(data['photoUrl'] as String) : null,
          child: (data['photoUrl'] as String?)?.isNotEmpty == true
              ? null : const Icon(Icons.person, color: Colors.black, size: 48),
        )),
        const SizedBox(height: 14),
        Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text((data['displayName'] as String?)?.isNotEmpty == true
              ? data['displayName'] as String : 'مستخدم Chat S',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          if (verified) const Padding(
            padding: EdgeInsetsDirectional.only(start: 6),
            child: Icon(Icons.verified, color: Color(0xFFFFD54F), size: 22),
          ),
        ])),
        const SizedBox(height: 28),
        if (isOwn) ...[
          TextField(controller: name, decoration: const InputDecoration(labelText: 'الاسم')),
          const SizedBox(height: 14),
          TextField(controller: bio, maxLines: 3, decoration: const InputDecoration(labelText: 'نبذة عنك')),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: saving ? null : _save,
            style: FilledButton.styleFrom(backgroundColor: brandGreen, foregroundColor: Colors.black),
            child: saving ? const CircularProgressIndicator() : const Text('حفظ التغييرات'),
          ),
        ] else ...[
          Text((data['bio'] as String?)?.isNotEmpty == true
              ? data['bio'] as String : 'لا توجد نبذة تعريفية.',
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('سيتم تفعيل بدء المحادثات المباشرة في المرحلة التالية.'))),
            icon: const Icon(Icons.message), label: const Text('مراسلة'),
          ),
        ],
      ]),
    );
  }
}

// محادثة دعم فني محفوظة في Firestore، ويمكن لفريق الدعم الرد عليها من لوحة الإدارة.

class SupportInboxScreen extends StatelessWidget {
  const SupportInboxScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('صندوق الدعم الفني')),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('supportTickets')
          .orderBy('updatedAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('تعذر تحميل الطلبات. تأكد من صلاحيات حساب الإدارة.'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('لا توجد طلبات دعم حالياً.'));
        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = docs[index];
            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFD54F),
                child: Icon(Icons.support_agent, color: Colors.black),
              ),
              title: Text('مستخدم: ${item.id}'),
              subtitle: Text((item.data()['status'] as String?) ?? 'مفتوح'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => SupportChatScreen(ticketUserId: item.id))),
            );
          },
        );
      },
    ),
  );
}

class SupportChatScreen extends StatefulWidget {
  final String? ticketUserId;
  const SupportChatScreen({super.key, this.ticketUserId});
  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final input = TextEditingController();
  bool sending = false;
  String get uid => widget.ticketUserId ?? FirebaseAuth.instance.currentUser!.uid;
  String get currentUid => FirebaseAuth.instance.currentUser!.uid;
  bool get adminMode => widget.ticketUserId != null;
  CollectionReference<Map<String, dynamic>> get messages =>
      FirebaseFirestore.instance.collection('supportTickets').doc(uid).collection('messages');

  Future<void> _send() async {
    final value = input.text.trim();
    if (value.isEmpty || sending) return;
    setState(() => sending = true);
    try {
      final ticket = FirebaseFirestore.instance.collection('supportTickets').doc(uid);
      await ticket.set({
        'userId': uid,
        if (!adminMode) 'status': 'open',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await messages.add({
        'senderId': currentUid,
        'text': value,
        'createdAt': FieldValue.serverTimestamp(),
      });
      input.clear();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر إرسال الرسالة. تحقق من إعدادات Firestore.')));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  void dispose() { input.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(adminMode ? 'محادثة دعم • $uid' : 'الدعم الفني')),
    body: Column(children: [
      Container(
        width: double.infinity, padding: const EdgeInsets.all(14), color: panelColor,
        child: const Text('أرسل لنا وصف المشكلة، وسيتابع فريق الدعم طلبك.',
            textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
      ),
      Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: messages.orderBy('createdAt').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('تحقق من إعدادات Firestore وقواعد الأمان.'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('لا توجد رسائل بعد. اكتب رسالتك لبدء طلب الدعم.'));
          return ListView.builder(
            padding: const EdgeInsets.all(14), itemCount: docs.length,
            itemBuilder: (context, index) {
              final item = docs[index].data();
              final mine = item['senderId'] == currentUid;
              return Align(
                alignment: mine ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(maxWidth: 300),
                  decoration: BoxDecoration(
                    color: mine ? const Color(0xFF174D39) : panelColor,
                    borderRadius: BorderRadius.circular(15)),
                  child: Text((item['text'] as String?) ?? ''),
                ),
              );
            },
          );
        },
      )),
      SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
        child: Row(children: [
          Expanded(child: TextField(controller: input, minLines: 1, maxLines: 4,
              decoration: InputDecoration(hintText: 'اكتب رسالتك للدعم الفني...',
                filled: true, fillColor: panelColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none)))),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: sending ? null : _send,
            style: IconButton.styleFrom(backgroundColor: brandGreen, foregroundColor: Colors.black),
            icon: sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send),
          ),
        ]),
      )),
    ]),
  );
}
