# Chat S

تطبيق مراسلة عربي بواجهة RTL، مبني باستخدام Flutter.

## الحالة الحالية

هذه نسخة تأسيسية قابلة للبناء والتجربة، وتتضمن:
- واجهة عربية داكنة بلمسات خضراء.
- قائمة محادثات تجريبية مع البحث.
- شاشة محادثة محلية لإرسال رسائل داخل المعاينة.
- أقسام الحالات والمكالمات والإعدادات كواجهات أولية.

**تنبيه:** الرسائل الحالية تجريبية ومحلية وليست مرسلة إلى مستخدمين آخرين. تسجيل الدخول، المزامنة الفورية، الإشعارات، الوسائط والمكالمات تحتاج إلى إعداد وربط Firebase وخدماتها قبل الإطلاق.

## المتطلبات

- Flutter stable
- Java 17
- Android SDK

## التشغيل محلياً

```bash
flutter create --platforms=android --org com.chats.mobile .
flutter pub get
flutter run
```

## إنشاء APK

```bash
flutter build apk --release
```

سيكون الملف الناتج في:

`build/app/outputs/flutter-apk/app-release.apk`

## البناء عبر GitHub

من صفحة المستودع افتح **Actions** ثم اختر **Build Android APK** واضغط **Run workflow**. بعد نجاح المهمة افتح تفاصيل التشغيل ونزّل artifact باسم `chat-s-android-apk`.

## إعداد Firebase لاحقاً

1. أنشئ مشروع Firebase.
2. أضف تطبيق Android بمعرّف الحزمة `com.chats.mobile`.
3. فعّل Phone Authentication وCloud Firestore وStorage وCloud Messaging.
4. أضف ملفات وإعدادات Firebase الصحيحة للمشروع.
5. نفّذ قواعد أمان Firestore وStorage قبل استخدام بيانات حقيقية.

لا تضع مفاتيح أو ملفات أسرار في المستودع العام.
