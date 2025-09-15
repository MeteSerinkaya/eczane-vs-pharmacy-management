# Eczane VS - Nöbetçi Eczane Yönetim Sistemi

Flutter tabanlı, Firebase entegrasyonlu modern eczane yönetim sistemi. Kullanıcıların konumlarına göre nöbetçi eczaneleri bulmalarını ve yönetmelerini sağlayan kapsamlı mobil uygulama.

## 📱 Uygulama Özellikleri

### 🔐 Kullanıcı Yönetimi
- Email/Şifre ile kayıt olma ve giriş yapma
- Email doğrulama sistemi
- Profil yönetimi ve şifre değiştirme
- Kullanıcı oturum yönetimi

### 📍 Konum Servisleri
- GPS tabanlı otomatik konum algılama
- Manuel konum seçimi (il/ilçe)
- Konum izinleri yönetimi
- Gerçek zamanlı konum güncelleme

### 🏥 Eczane Yönetimi
- Konum tabanlı eczane arama
- Nöbetçi eczane listesi
- Favori eczane ekleme/çıkarma
- Eczane detayları ve iletişim bilgileri
- Harita entegrasyonu ile navigasyon

### 🔔 Bildirim Sistemi
- Push bildirimleri (Firebase Cloud Messaging)
- Yerel bildirimler
- Bildirim geçmişi
- Toplu bildirim silme

### 📢 Duyuru Sistemi
- Gerçek zamanlı duyuru görüntüleme
- Yönetici duyuru yönetimi
- Kronolojik duyuru sıralama

### 👨‍💼 Yönetici Paneli
- Eczane verilerini toplu aktarım
- Veri migrasyon durumu takibi
- Şehir bazlı veri yönetimi
- Yönetici yetki kontrolü

## 🛠️ Teknoloji Stack

### Frontend
- **Flutter** - Cross-platform mobil uygulama geliştirme
- **Dart** - Programlama dili
- **Material Design 3** - Modern UI/UX tasarım
- **Provider Pattern** - State management

### Backend
- **Firebase Authentication** - Kullanıcı kimlik doğrulama
- **Cloud Firestore** - NoSQL veritabanı
- **Firebase Cloud Messaging** - Push bildirimler
- **Firebase Storage** - Dosya depolama

### External APIs
- **CollectAPI** - Türkiye eczane verileri
- **Turkey API** - Konum verileri
- **Cloudinary** - Görsel işleme ve CDN

### Development Tools
- **Git** - Versiyon kontrolü
- **SharedPreferences** - Yerel veri depolama
- **HTTP** - API istekleri
- **Geolocator** - GPS entegrasyonu

## 🏗️ Proje Mimarisi

```
lib/
├── main.dart                 # Uygulama giriş noktası
├── models/                   # Veri modelleri
│   ├── pharmacy_model.dart
│   ├── notification_model.dart
│   └── announcement_model.dart
├── providers/                # State management
│   ├── location_provider.dart
│   └── theme_provider.dart
├── screens/                  # UI ekranları
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   └── email_verification_screen.dart
│   ├── main/
│   │   ├── home_screen.dart
│   │   ├── profile_screen.dart
│   │   └── notification_screen.dart
│   └── admin/
│       └── admin_screen.dart
├── services/                 # İş mantığı servisleri
│   ├── auth_service.dart
│   ├── location_service.dart
│   ├── notification_service.dart
│   └── pharmacy_service.dart
├── widgets/                  # Yeniden kullanılabilir widget'lar
│   └── app_drawer.dart
└── theme/                    # Tema konfigürasyonu
    └── app_theme.dart
```

## 🚀 Kurulum ve Çalıştırma

### Gereksinimler
- Flutter SDK (3.0+)
- Dart SDK (3.0+)
- Android Studio / VS Code
- Firebase projesi

### Adımlar

1. **Repository'yi klonlayın**
```bash
git clone https://github.com/MeteSerinkaya/eczane-vs-pharmacy-management.git
cd eczane-vs-pharmacy-management
```

2. **Dependencies'leri yükleyin**
```bash
flutter pub get
```

3. **Firebase konfigürasyonu**
- `firebase_options.dart` dosyasını güncelleyin
- `google-services.json` (Android) ve `GoogleService-Info.plist` (iOS) dosyalarını ekleyin

4. **Uygulamayı çalıştırın**
```bash
flutter run
```

## 📱 Ekran Görüntüleri

### Ana Ekranlar
- **Splash Screen** - Uygulama başlatma ve konum alma
- **Login/Register** - Kullanıcı kimlik doğrulama
- **Home Screen** - Eczane listesi ve arama
- **Profile Screen** - Kullanıcı profil yönetimi

### Yönetim Ekranları
- **Admin Panel** - Veri migrasyon yönetimi
- **Notification Screen** - Bildirim geçmişi
- **Location Update** - Konum güncelleme

## 🔧 Konfigürasyon

### Firebase Setup
1. Firebase Console'da yeni proje oluşturun
2. Authentication, Firestore, Cloud Messaging'i etkinleştirin
3. Android/iOS uygulaması ekleyin
4. Konfigürasyon dosyalarını projeye ekleyin

### API Keys
- CollectAPI key'i `lib/services/api_service.dart` dosyasında güncelleyin
- Cloudinary konfigürasyonunu `lib/screens/profile_screen.dart` dosyasında ayarlayın

## 🧪 Test

```bash
# Unit testleri çalıştır
flutter test

# Widget testleri
flutter test test/widget_test.dart

# Integration testleri
flutter test integration_test/
```

## 📊 Performans

- **Lazy Loading** - Büyük veri setleri için
- **Caching** - SharedPreferences ile yerel önbellekleme
- **Batch Processing** - Toplu veri işleme
- **Memory Management** - Optimize edilmiş bellek kullanımı

## 🔒 Güvenlik

- Firebase Security Rules ile veritabanı erişim kontrolü
- Kullanıcı kimlik doğrulama ve yetkilendirme
- Veri validasyonu ve sanitizasyon
- HTTPS ile güvenli API iletişimi

## 🤝 Katkıda Bulunma

1. Fork edin
2. Feature branch oluşturun (`git checkout -b feature/AmazingFeature`)
3. Commit edin (`git commit -m 'Add some AmazingFeature'`)
4. Push edin (`git push origin feature/AmazingFeature`)
5. Pull Request oluşturun

