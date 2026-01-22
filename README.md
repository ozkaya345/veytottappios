# OTT

A new Flutter project.

## Firebase Kurulumu

Projede `firebase_core` entegre edildi ve uygulama açılışında `Firebase.initializeApp()` çalışıyor.

Eklenen paketler:

- `firebase_auth`
- `cloud_firestore`

Gerekli dosyalar:

- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

Önerilen (kolay) yöntem: FlutterFire CLI ile otomatik konfigürasyon

- `dart pub global activate flutterfire_cli`
- `flutterfire configure`

Notlar:

- `google-services.json` ve `GoogleService-Info.plist` dosyalarını Firebase Console’dan indirip yukarıdaki konumlara koymanız gerekir.
- Web kullanacaksanız `flutterfire configure` ile web config de üretilir.
 - Web kullanacaksanız `flutterfire configure` ile web config de üretilir.

## Firestore Kuralları (Sahip-Temelli Görünürlük)

“Kod ile Aç” akışında tablo içeriği (`status_tables`) sadece **sahibi** veya **link’lenmiş kullanıcı** tarafından okunabilir. Müşteri ilk kez kod girerken henüz link olmadığı için, kod → tablo id çözümü için ayrıca `status_table_codes` koleksiyonu kullanılır.

- `status_tables`: read => signed-in + (owner OR link) + trashed=false
- `status_table_links`: müşteri kendi hesabına link yazar
- `status_table_codes`: signed-in kullanıcılar koddan `tableId` çözebilir (write sadece owner)

Kurallar dosyası: `firestore.rules`

Dağıtım adımları (Firebase CLI):

```
npm i -g firebase-tools
firebase login
firebase use --add
firebase deploy --only firestore:rules
```

Not: Kod → id çözümü artık öncelikle `status_table_codes/{OTT-123456}` dokümanı üzerinden yapılır; bu yüzden `status_tables` üzerinde `code` sorgusu çoğu durumda gerekmez.

Notlar:
- `status_tables` belgeleri oluşturulurken `ownerId` ve benzersiz `code` alanları servis tarafından yazılır.
- “Kod ile Aç” akışı: kullanıcı kodu girer → `status_table_codes` ile `tableId` bulunur → `status_table_links` yazılır → kart listede görünür ve tablo okunabilir.

## Legacy Kayıtları Düzeltme (ownerId boş olanlar)

Önceki bug'lar yüzünden `status_tables` içinde `ownerId` alanı boş/eksik kalmış eski kayıtlar varsa, bu kayıtlar artık kural gereği okunamaz ve UI listesinde görünmez.

Tek seferlik onarım için admin yetkisiyle çalışan script: `tools/repair_status_tables_ownerid.mjs`

Örnek:

```
cd tools
npm i firebase-admin
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\path\to\service-account.json"
node .\repair_status_tables_ownerid.mjs --uid <USER_UID>
```

## Eski Tablolar için Kod Eşlemesi (Backfill)

Eğer daha önce oluşturulmuş tablolarınız varsa, "Kod ile Aç" akışının çalışması için `status_table_codes` eşlemesi gerekir.

Tek seferlik backfill scripti: `tools/backfill_status_table_codes.mjs`

```
cd tools
npm i firebase-admin
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\path\to\service-account.json"
node .\backfill_status_table_codes.mjs
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
