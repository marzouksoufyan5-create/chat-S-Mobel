import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ChatSApp());
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
    final titles = ['المحادثات', 'الحالات', 'المكالمات', 'الإعدادات'];
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
        _emptyPage(Icons.call_outlined, 'المكالمات', 'ستظهر مكالماتك هنا'),
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
