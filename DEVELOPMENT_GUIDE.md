# DeviceInspector（设备鉴）— 双端App开发指南 v1.0

---

## 一、技术架构选型

### 1.1 Flutter vs 原生开发对比

| 维度 | Flutter | iOS原生(Swift) | Android原生(Kotlin) |
|---|---|---|---|
| 开发效率 | 高（单代码库双端） | 低（需分别开发） | 低（需分别开发） |
| 性能 | 优 | 优 | 优 |
| 硬件API访问 | 需插件 | 原生支持 | 原生支持 |
| Deep Link支持 | 有限（需插件） | 完善（URL Scheme/App Links） | 完善（Intent/App Links） |
| iOS设置跳转 | 受限 | App-Prefs: 支持 | 不适用 |
| 学习成本 | 中 | 高（需分别学习） | 高（需分别学习） |
| 维护成本 | 低 | 高 | 高 |

### 1.2 推荐方案：**Flutter + 原生模块插件**

**结论：采用 Flutter 跨平台架构，但对 iOS Deep Link 和硬件检测功能使用原生平台通道（Method Channel）实现。**

架构逻辑：
- Flutter 作为视图层和业务逻辑层，保持双端代码统一
- iOS 特有的 URL Scheme 跳转（App-Prefs）和零件历史 API 通过 Method Channel 调用原生 Swift 代码
- Android 特有的 ADB 权限和 Accessibility 服务通过 Method Channel 调用原生 Kotlin 代码
- 后端采用 Python FastAPI，保持轻量

---

## 二、iOS端开发指南

### 2.1 项目结构

```
ios/
├── Runner/
│   ├── AppDelegate.swift           # 入口
│   ├── SceneDelegate.swift         # 生命周期
│   ├── MethodChannelHandler.swift   # Flutter通信
│   ├── DeepLinkHandler.swift       # URL Scheme处理
│   ├── PartsHistoryService.swift   # iOS17零件历史API
│   └── Info.plist                   # URL Schemes配置
```

### 2.2 URL Scheme 配置（Info.plist）

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>app-prefs</string>
            <string>App-Prefs</string>
        </array>
    </dict>
</array>
```

### 2.3 核心URL Scheme跳转

| 功能 | URL Scheme |
|---|---|
| 通用设置 | `App-Prefs:General` |
| Apple ID账户 | `App-Prefs:AppleAccount` (iOS 18+) |
| 蜂窝网络 | `App-Prefs:Cellular` |
| 电池设置 | `App-Prefs:Battery` |
| 隐私设置 | `App-Prefs:Privacy` |
| MDM/配置文件 | `App-Prefs:General&path=Management` |

```swift
// DeepLinkHandler.swift
class DeepLinkHandler {
    enum SettingsPage: String {
        case general = "App-Prefs:General"
        case appleAccount = "App-Prefs:AppleAccount"
        case cellular = "App-Prefs:Cellular"
        case battery = "App-Prefs:Battery"
        case privacy = "App-Prefs:Privacy"
        case profile = "App-Prefs:General&path=Management"
    }

    func open(page: SettingsPage, completion: @escaping (Bool) -> Void) {
        if let url = URL(string: page.rawValue) {
            completion(UIApplication.shared.open(url))
        } else {
            completion(false)
        }
    }
}
```

### 2.4 iOS 17+ 零件修复历史 API

iOS 17 引入 `CHRepairability Suitability API`，通过 IORegistry 读取零件修复历史：

```swift
// PartsHistoryService.swift
import Foundation
import CoreBrightness

class PartsHistoryService {
    struct PartHistory: Codable {
        let partType: String        // battery, display, camera, etc.
        let isGenuine: Bool
        let repairFacility: String?
        let repairDate: Date?
        let serialNumber: String?
    }

    func fetchPartsHistory() async throws -> [PartHistory] {
        // iOS 17+ 通过 IORegistry 读取零件信息
        // 路径: IORegistryPlane::IODeviceTree → AppleARMIICElector
        // 具体实现需调用 IOKit framework
        // 注意：此API需要设备运行iOS 17+且已解锁
    }
}
```

**重要限制**：
- 此API仅在 iOS 17+ 可用
- 设备必须未越狱且能正常访问 IORegistry
- 部分维修记录需要 Apple 授权维修点才能写入

### 2.5 Method Channel 注册（AppDelegate.swift）

```swift
@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        // 处理 URL Scheme 返回
        return super.application(app, open: url, options: options)
    }

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller = window?.rootViewController as! FlutterViewController

        // 注册iOS原生能力通道
        let channel = FlutterMethodChannel(
            name: "com.deviceinspector/ios",
            binaryMessenger: controller.binaryMessenger
        )

        channel.setMethodCallHandler { [weak self] call, result in
            switch call.method {
            case "openSettings":
                if let args = call.arguments as? [String: Any],
                   let page = args["page"] as? String {
                    self?.openSettingsPage(page: page, result: result)
                }
            case "getPartsHistory":
                self?.getPartsHistory(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func openSettingsPage(page: String, result: FlutterResult) {
        let scheme = DeepLinkHandler.SettingsPage(rawValue: page)
        DeepLinkHandler().open(page: scheme ?? .general) { success in
            result(["success": success])
        }
    }
}
```

### 2.6 UI框架选择

**推荐：SwiftUI + Flutter**

- iOS端的Deep Link跳转用原生SwiftUI实现
- Flutter通过Method Channel调用，保持UI一致性
- Flutter端使用 Material Design 3，双端体验统一

### 2.7 权限和审核注意

| 权限 | 用途 | App Store风险 |
|---|---|---|
| Camera | 扫描序列号/IMEI条码 | 低（常规扫码） |
| Bluetooth | 检测设备连接 | 低 |
| 第三方支付 | ¥1付费功能 | 需使用IAP |

**App Store审核重点**：
- iOS端¥1付费必须通过IAP（应用内购买），不能跳转到外部支付
- Deep Link跳转到系统设置是用户主动行为，审核无风险
- 零件历史API仅读取数据，不涉及隐私

---

## 三、Android端开发指南

### 3.1 项目结构

```
android/
├── app/src/main/
│   ├── java/com/deviceinspector/
│   │   ├── MainActivity.kt
│   │   ├── MethodChannelHandler.kt   # Flutter通信
│   │   ├── DeepLinkHandler.kt        # Intent跳转
│   │   ├── AccessibilityService.kt    # 无障碍服务
│   │   └── AdbService.kt             # ADB权限处理
│   └── AndroidManifest.xml
```

### 3.2 AndroidManifest配置

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.BLUETOOTH"/>
<uses-permission android:name="android.permission.ACCESSIBILITY_SERVICE"/>

<application>
    <activity
        android:name=".MainActivity"
        android:exported="true"
        android:launchMode="singleTask">
        <intent-filter>
            <action android:name="android.intent.action.MAIN"/>
            <category android:name="android.intent.category.LAUNCHER"/>
        </intent-filter>
        <!-- App Links -->
        <intent-filter android:autoVerify="true">
            <action android:name="android.intent.action.VIEW"/>
            <category android:name="android.intent.category.DEFAULT"/>
            <data android:scheme="https" android:host="deviceinspector.app"/>
        </intent-filter>
    </activity>

    <!-- Accessibility Service -->
    <service
        android:name=".AccessibilityService"
        android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE"
        android:exported="false">
        <intent-filter>
            <action android:name="android.accessibilityservice.AccessibilityService"/>
        </intent-filter>
        <meta-data android:name="android.accessibilityservice" android:resource="@xml/accessibility_config"/>
    </service>
</application>
```

### 3.3 Intent跳转

```kotlin
// DeepLinkHandler.kt
object DeepLinkHandler {
    enum class SettingsPage(val action: String) {
        APPLICATION_SETTINGS(SriSettings.ACTION_APPLICATION_SETTINGS),
        PRIVACY_SETTINGS(SriSettings.ACTION_PRIVACY_SETTINGS),
        SECURITY_SETTINGS(SriSettings.ACTION_SECURITY_SETTINGS),
        DEVICE_INFO("android.settings.DEVICE_INFO_SETTINGS"),
    }

    fun open(page: SettingsPage, context: Context): Boolean {
        return try {
            val intent = Intent(page.action)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }
}
```

### 3.4 ADB权限处理

```kotlin
// AdbService.kt
class AdbService {
    fun isAdbAuthorized(): Boolean {
        // 通过adb devices检测授权状态
        // 需用户手动授权调试
    }

    fun getDeviceInfo(): Map<String, Any?> {
        // 通过adb shell获取设备信息
        // 必须已授权USB调试
    }

    fun getBatteryInfo(): BatteryInfo? {
        // adb shell dumpsys battery
    }

    fun checkActivationLock(): Boolean {
        // 检测FRP(Factory Reset Protection)锁状态
        // 通过查询google account状态
    }
}
```

### 3.5 激活锁检测（Accessibility服务）

```kotlin
// AccessibilityService.kt
class DeviceInspectorAccessibility : AccessibilityService() {
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        when (event?.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                // 读取当前页面内容
                val content = event.text?.joinToString("")
                // 检测是否包含"激活锁"、"Google锁"等关键词
            }
        }
    }

    override fun onInterrupt() {}

    override fun onServiceConnected() {
        // 服务连接后可以执行自动化检测
    }
}
```

### 3.6 Android权限碎片化应对

| 厂商 | 权限限制 | 解决方案 |
|---|---|---|
| 小米 | MIUI限制ADB权限 | 提供官方解锁工具引导 |
| 华为 | EMUI限制后台activity | Deep Link兜底方案 |
| OPPO/Vivo | ColorOS/Funtouch限制多 | 仅支持标准Settings跳转 |
| 三星 | OneUI相对开放 | 可尝试更多自动化检测 |

**策略**：
- 标准Intent跳转作为基础兜底
- Accessibility服务作为增强检测
- ADB作为专业模式（需用户手动授权）

---

## 四、后端开发指南

### 4.1 技术栈

- **框架**：Python FastAPI
- **数据库**：PostgreSQL 15+（主数据）
- **缓存**：Redis（会话、频率限制）
- **文件存储**：本地MinIO或云OSS（报告图片/PDF）
- **部署**：Docker + Nginx

### 4.2 API设计

```
Base URL: https://api.deviceinspector.app

POST /api/v1/device/query          # 序列号查询
GET  /api/v1/device/{serial}       # 获取设备详情
POST /api/v1/device/activation-lock  # 激活锁查询
POST /api/v1/report/generate       # 生成验机报告
GET  /api/v1/report/{report_id}    # 获取报告
GET  /api/v1/report/{report_id}/verify  # 验证报告签名
GET  /api/v1/price/{model}         # 二手行情价格
POST /api/v1/purchase/verify       # 验证¥1购买
```

### 4.3 数据库设计

```sql
-- 用户表
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id VARCHAR(255) UNIQUE NOT NULL,  -- 设备唯一标识
    created_at TIMESTAMP DEFAULT NOW(),
    is_premium BOOLEAN DEFAULT FALSE,        -- 是否已购¥1
    purchase_receipt TEXT,                   -- IAP收据（校验用）
    last_query_at TIMESTAMP
);

-- 设备信息缓存表
CREATE TABLE devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    serial_number VARCHAR(64) UNIQUE NOT NULL,
    imei VARCHAR(20),
    model VARCHAR(64),                      -- 机型
    region VARCHAR(16),                      -- 销售地
    activation_lock BOOLEAN,
    carrier_lock VARCHAR(64),               -- 运营商锁状态
    mdm_lock BOOLEAN,                       -- MDM配置锁
    is_refurbished BOOLEAN,                 -- 是否官方翻新
    parts_history JSONB,                    -- 零件历史
    battery_health INTEGER,                 -- 电池健康度
    raw_data JSONB,                         -- 原始数据
    queried_at TIMESTAMP DEFAULT NOW()
);

-- 报告表
CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    device_id UUID REFERENCES devices(id),
    report_data JSONB NOT NULL,             -- 完整报告内容
    signature TEXT NOT NULL,                 -- RSA签名
    created_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP,                   -- 报告有效期
    verification_url VARCHAR(255)            # 二维码验证URL
);

-- 序列号区间表（翻新机识别）
CREATE TABLE serial_prefixes (
    id SERIAL PRIMARY KEY,
    prefix VARCHAR(16) NOT NULL,
    device_type VARCHAR(64),
    is_refurbished_range BOOLEAN DEFAULT FALSE,
    description TEXT
);
```

### 4.4 关键接口实现

#### 4.4.1 激活锁查询（对接CheckM32等）

```python
# routers/device.py
from fastapi import APIRouter, HTTPException
import httpx

router = APIRouter(prefix="/api/v1/device", tags=["device"])

@router.post("/activation-lock")
async def check_activation_lock(imei: str, serial: str = None):
    """
    对接CheckM32.info API查询激活锁状态
    """
    async with httpx.AsyncClient(timeout=30) as client:
        # CheckM32 API调用
        response = await client.get(
            f"https://checkm32.info/api/check",
            params={"imei": imei, "sn": serial}
        )

        if response.status_code != 200:
            raise HTTPException(status_code=502, detail="查询服务不可用")

        data = response.json()
        return {
            "imei": imei,
            "activation_lock": data.get("locked"),
            "lost_stolen": data.get("lost"),
            "blacklist": data.get("blacklist"),
            "carrier": data.get("carrier"),
            "region": data.get("region")
        }
```

#### 4.4.2 报告签名机制

```python
# services/signer.py
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.backends import default_backend
import hashlib
import base64
import json

class ReportSigner:
    def __init__(self, private_key_path: str):
        with open(private_key_path, "rb") as f:
            self.private_key = serialization.load_pem_private_key(
                f.read(), password=None, backend=default_backend()
            )

    def sign(self, report_data: dict) -> str:
        """
        对报告内容进行SHA-256哈希，然后RSA签名
        """
        # 标准化报告JSON（排序key保证一致性）
        canonical_json = json.dumps(report_data, sort_keys=True, ensure_ascii=False)

        # SHA-256哈希
        digest = hashes.Hash(hashes.SHA256(), backend=default_backend())
        digest.update(canonical_json.encode("utf-8"))
        content_hash = digest.finalize()

        # RSA签名
        signature = self.private_key.sign(
            content_hash,
            padding.PKCS1v15(),
            hashes.SHA256()
        )

        return base64.b64encode(signature).decode("utf-8")

    def verify(self, report_data: dict, signature: str) -> bool:
        """供外部验证报告完整性"""
        # 验证逻辑...
        pass

# 报告生成
@router.post("/report/generate")
async def generate_report(device_id: str, user_id: str):
    report_data = {
        "device_id": device_id,
        "timestamp": datetime.now().isoformat(),
        # ... 完整报告内容
    }

    signer = ReportSigner("/path/to/private_key.pem")
    signature = signer.sign(report_data)

    report = await db.insert("reports", {
        "user_id": user_id,
        "device_id": device_id,
        "report_data": report_data,
        "signature": signature,
        "verification_url": f"https://deviceinspector.app/verify/{report_id}"
    })

    return {"report_id": report.id, "signature": signature}
```

#### 4.4.3 二手行情价格

```python
# routers/price.py
@router.get("/price/{model}")
async def get_market_price(model: str):
    """
    抓取闲鱼/转转同型号在售价格
    实际生产中建议对接第三方价格数据服务
    """
    cache_key = f"price:{model}"
    cached = await redis.get(cache_key)

    if cached:
        return json.loads(cached)

    # 实际生产中对接数据源
    # 这里假设有一个爬虫服务或第三方API
    price_data = {
        "model": model,
        "price_range": {
            "low": 2000,
            "median": 2800,
            "high": 3500
        },
        "source": "aggregated",
        "updated_at": datetime.now().isoformat()
    }

    # 缓存1小时
    await redis.setex(cache_key, 3600, json.dumps(price_data))

    return price_data
```

### 4.5 安全考虑

| 安全点 | 方案 |
|---|---|
| IAP收据校验 | Apple IAP receipt validation（服务端验证） |
| 报告防篡改 | RSA-256签名，私钥离线存储 |
| API频率限制 | Redis + IP限流 |
| 数据传输 | HTTPS强制 + HSTS |
| 用户隐私 | 不存储IMEI等敏感信息，仅存设备标识符哈希 |

---

## 五、技术风险和解决方案

### 5.1 iOS Deep Link读取系统设置页面的限制

| 风险 | 描述 | 解决方案 |
|---|---|---|
| iOS版本差异 | iOS 18+才支持App-Prefs:AppleAccount | 优雅降级到引导截图界面 |
| 读取返回数据 | App无法读取设置页面返回内容 | 引导用户在App内打开设置，App记录操作时间戳作为参考 |
| 用户拒绝授权 | 用户不点"信任此电脑" | 引导使用CheckM32在线查询替代 |

### 5.2 Android权限碎片化

| 风险 | 解决方案 |
|---|---|
| ADB权限被厂商限制 | 优先用标准Intent，Accessibility兜底 |
| 不同厂商设置路径不同 | 构建厂商适配表，覆盖主流机型90% |
| 用户不理解为何要开权限 | UI引导解释"仅本地检测，不上传数据" |

### 5.3 iOS App Store审核

| 风险 | 解决方案 |
|---|---|
| ¥1付费必须走IAP | 接入Apple IAP，审核时准备说明文档 |
| IAP退款率高 | 做好服务，让用户觉得值 |
| Deep Link被拒 | 已验证是标准iOS行为，无风险 |

---

## 六、开发里程碑规划

### Phase 1: MVP（4-6周）

**目标：上线最小可用版本，验证核心价值**

| 功能 | 优先级 | 说明 |
|---|---|---|
| 序列号扫码输入 | P0 | 摄像头扫码+手动输入 |
| 激活锁在线查询 | P0 | 对接CheckM32 API |
| 运营商锁检测引导 | P0 | Deep Link跳转+截图引导 |
| iOS基础信息读取 | P0 | 型号/容量/颜色/WiFi MAC等 |
| Android基础信息读取 | P0 | 同上 |
| 报告生成（基础版） | P1 | PDF导出，无签名 |

### Phase 2: 核心差异化（6-8周）

**目标：建立竞争壁垒，区分爱思**

| 功能 | 优先级 | 说明 |
|---|---|---|
| iOS 17零件更换历史 | P0 | 原厂零件验证 |
| MDM配置锁检测 | P0 | 企业机识别 |
| 翻新机序列号识别 | P0 | 官方翻新机判断 |
| 报告SHA-256签名 | P0 | 防伪验证 |
| 二手行情价格 | P1 | 闲鱼/转转数据 |

### Phase 3: 商业化（2-3周）

**目标：上线¥1永久进阶功能**

| 功能 | 优先级 | 说明 |
|---|---|---|
| IAP接入（¥1） | P0 | Apple/Google支付 |
| 高级报告模板 | P0 | 品牌化展示 |
| 报告分享图片 | P1 | 一键生成可分享卡片图 |
| 用户数据同步 | P2 | 云端历史记录 |

### Phase 4: 体验优化（持续）

- 硬件基础检测（电池、触控、传感器）
- 更多数据源接入（保修查询、维修记录）
- 社交分享引导（"我刚用DeviceInspector验了这台机"）

---

## 七、Flutter端核心实现（供参考）

### 7.1 依赖库

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter

  # 扫码
  mobile_scanner: ^5.0.0

  # HTTP
  dio: ^5.4.0

  # 状态管理
  flutter_riverpod: ^2.4.0

  # 本地存储
  shared_preferences: ^2.2.0

  # PDF生成
  pdf: ^3.10.0
  printing: ^5.12.0

  # 图片处理
  image_picker: ^1.0.0

  # 支付
  in_app_purchase: ^3.1.0

  # 分享
  share_plus: ^7.2.0

  # iOS平台通道
  cupertino_icons: ^1.0.6

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

### 7.2 Method Channel调用示例

```dart
// services/ios_native_bridge.dart
import 'package:flutter/services.dart';

class IOSNativeBridge {
  static const _channel = MethodChannel('com.deviceinspector/ios');

  static Future<bool> openSettingsPage(String page) async {
    try {
      final result = await _channel.invokeMethod('openSettings', {'page': page});
      return result['success'] ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getPartsHistory() async {
    try {
      final result = await _channel.invokeMethod('getPartsHistory');
      return Map<String, dynamic>.from(result);
    } on PlatformException {
      return null;
    }
  }
}

// 使用示例
ElevatedButton(
  onPressed: () {
    IOSNativeBridge.openSettingsPage('App-Prefs:Cellular');
  },
  child: Text('检测运营商锁'),
)
```

---

## 八、总结

**DeviceInspector的核心竞争力**：
1. 激活锁/运营商锁一站式检测（爱思不做）
2. iOS 17零件更换历史（爱思展示有限）
3. 可验证签名报告（爱思没有）
4. 翻新机序列号识别（爱思不做）

**开发优先级**：
1. 先做iOS（Deep Link + 零件历史是差异化核心）
2. Android做兼容（标准Intent兜底）
3. 后端先接CheckM32（最快验证激活锁查询）
4. 报告签名后置（MVP阶段可用截图替代）

**商业模式**：
- 免费：基础查询+激活锁跳转
- ¥1永久：零件历史+MDM+报告+行情