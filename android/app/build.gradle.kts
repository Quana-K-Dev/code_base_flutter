plugins {
    // Plugin chuẩn để build ứng dụng Android
    id("com.android.application")
    // Hỗ trợ ngôn ngữ Kotlin cho Android
    id("kotlin-android")
    // Plugin của Flutter (Bắt buộc phải đứng sau Android và Kotlin để nhận diện cấu hình Flutter)
    id("dev.flutter.flutter-gradle-plugin")
}

// Map ánh xạ tên môi trường (flavor) với đường dẫn file .env tương ứng.
// Giúp package 'flutter_dotenv' hoặc script custom biết đọc file nào khi chạy lệnh --flavor.
project.extra["envConfigFiles"] = mapOf(
    "alpha" to "env/.env.alpha",
    "dev" to "env/.env.dev",
    "prg" to "env/.env.prg",
    "uat" to "env/.env.uat",
    "prd" to "env/.env.prd"
)

android {
    // Namespace: Tên gói dùng cho mã nguồn Java/Kotlin (tạo file R.java và BuildConfig.java).
    // Lưu ý: Nếu đổi cái này, phải vào file MainActivity.kt sửa lại package tương ứng.
    namespace = "com.example.code_base_flutter"

    // Phiên bản Android SDK dùng để biên dịch (Lấy theo cấu hình mặc định của Flutter).
    compileSdk = flutter.compileSdkVersion
    
    // Phiên bản NDK (Native Development Kit).
    // Nên để flutter tự quản lý để tránh lỗi không tương thích giữa các phiên bản.
    ndkVersion = flutter.ndkVersion

    // Bật tính năng tự động tạo class 'BuildConfig'.
    // Cần thiết để code Native (Kotlin/Java) có thể đọc được Flavor hiện tại hoặc các biến môi trường custom.
    buildFeatures.buildConfig = true 

    compileOptions {
        // Bật tính năng "Desugaring": Cho phép dùng các hàm Java 8+ (như java.time, Stream API)
        // chạy mượt mà trên các máy Android đời cũ (API < 26) mà không bị crash.
        isCoreLibraryDesugaringEnabled = true
        
        // Thiết lập chuẩn Java 11 cho dự án (bắt buộc với các bản Gradle mới).
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // ID định danh duy nhất của ứng dụng trên Store (Google Play).
        // LƯU Ý: Hiện tại đang set cứng (hardcode). 
        // Điều này có nghĩa là bạn KHÔNG THỂ cài song song bản Dev và Prg trên cùng 1 điện thoại.
        // (Muốn cài song song thì cần code đoạn đọc từ .env để thêm suffix).
        applicationId = "com.example.code_base_flutter"
        
        // Các thông số version (Lấy từ file pubspec.yaml thông qua Flutter config).
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Tạo một string resource chứa package name, phòng khi code Native cần gọi tới.
        resValue("string", "build_config_package", "com.example.code_base_flutter")
    }

    // --- CẤU HÌNH CHỮ KÝ SỐ (SIGNING) ---
    signingConfigs {
        // CÁCH 1: Cấu hình nhanh (Dùng cho dự án cá nhân/học tập)
        create("release") {
            // File .jks chứa chữ ký (đặt tại thư mục 'key', ngang hàng thư mục 'android')
            storeFile = file("../key/wana_development.jks")
            
            // ⚠️ CẢNH BÁO BẢO MẬT: Mật khẩu lộ thiên.
            // Hacker có thể thấy nếu bạn push file này lên Git public.
            storePassword = "wana@2026"
            keyAlias = "wana"
            keyPassword = "wana@2026"
        }
    }
    
    // CÁCH 2: Cấu hình chuẩn bảo mật (Best Practice) - Đang comment
    // Nên dùng cách này khi làm dự án thực tế để giấu mật khẩu vào file 'key.properties' (file này không up lên Git).
    /*
    signingConfigs {
         create("release") {
             val keystoreProperties = java.util.Properties()
             val keyFile = rootProject.file("key.properties")
             if (keyFile.exists()) {
                 keystoreProperties.load(java.io.FileInputStream(keyFile))
                 keyAlias = keystoreProperties["keyAlias"] as String
                 keyPassword = keystoreProperties["keyPassword"] as String
                 storePassword = keystoreProperties["storePassword"] as String
                 storeFile = file(keystoreProperties["storeFile"] as String)
             }
         }
    }
    */

    buildTypes {
        release {
            // Áp dụng cấu hình chữ ký 'release' ở trên.
            // Bắt buộc phải có dòng này thì file build ra mới cài được (Signed APK/AAB).
            signingConfig = signingConfigs.getByName("release")
            
            // BẬT: Xóa các tài nguyên thừa (ảnh, xml layout không dùng) -> Giảm dung lượng App.
            isShrinkResources = true
            
            // BẬT: R8 Compiler - Làm mờ code (Obfuscate) và đổi tên class/hàm ngắn lại (a.b.c).
            // Tác dụng: App nhẹ hơn nhiều + Chống hacker dịch ngược code (Reverse Engineering).
            isMinifyEnabled = true
            
            // File cấu hình luật ProGuard.
            // Quan trọng: Phải cấu hình file này để tránh việc R8 xóa nhầm các Model/Class quan trọng gây crash app.
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    // --- CẤU HÌNH ĐA MÔI TRƯỜNG (FLAVORS) ---
    // Khai báo tên chiều (Dimension)
    flavorDimensions += "environment"
    
    // Định nghĩa danh sách các môi trường. 
    // Tên (dev, prg...) phải khớp chính xác với key trong map 'envConfigFiles' ở đầu file.
    productFlavors {
        create("alpha") { dimension = "environment" } // Môi trường sơ khai
        create("dev") { dimension = "environment" }   // Môi trường phát triển (Development)
        create("prg") { dimension = "environment" }   // Môi trường Staging/Program (Test gần giống thật)
        create("uat") { dimension = "environment" }   // Môi trường kiểm thử chấp nhận (User Acceptance Test)
        create("prd") { dimension = "environment" }   // Môi trường thật (Production - Lên Store)
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Thư viện hỗ trợ tính năng Desugaring (để chạy Java 8+ trên Android cũ).
    // Bắt buộc phải có vì đã bật 'isCoreLibraryDesugaringEnabled = true' ở trên.
    add("coreLibraryDesugaring", "com.android.tools:desugar_jdk_libs:2.1.4")
}