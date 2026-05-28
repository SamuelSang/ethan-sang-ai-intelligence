import UIKit

// MARK: - SettingsPage Enum

/// 表示可跳转的系统设置页面。
/// URL Scheme 格式: App-Prefs:<Path>
enum SettingsPage: String, CaseIterable {
    case general      = "general"
    case appleAccount = "appleAccount"
    case cellular     = "cellular"
    case battery      = "battery"
    case privacy      = "privacy"
    case profile      = "profile"

    /// 对应的 App-Prefs URL Scheme 路径
    var urlSchemePath: String {
        switch self {
        case .general:
            return "App-Prefs:General"
        case .appleAccount:
            // App-Prefs:AppleAccount 仅 iOS 18+ 支持
            if #available(iOS 18, *) {
                return "App-Prefs:AppleAccount"
            } else {
                // iOS 17 及以下降级到 APPLE_ACCOUNT（旧路径）
                return "App-Prefs:APPLE_ACCOUNT"
            }
        case .cellular:
            return "App-Prefs:Cellular"
        case .battery:
            return "App-Prefs:BATTERY_USAGE"
        case .privacy:
            return "App-Prefs:Privacy"
        case .profile:
            return "App-Prefs:General&path=ManagedConfigurationList"
        }
    }

    /// 从字符串（Flutter 传入的 page 参数）初始化
    init?(rawPage: String) {
        if let page = SettingsPage(rawValue: rawPage) {
            self = page
        } else {
            return nil
        }
    }
}

// MARK: - DeepLinkHandler

/// 负责打开 iOS 系统设置页面的处理器。
struct DeepLinkHandler {

    /// 打开指定的设置页面。
    /// - Parameters:
    ///   - page: 目标设置页面
    ///   - completion: 回调，参数为是否成功打开
    static func open(page: SettingsPage, completion: @escaping (Bool) -> Void) {
        let urlString = page.urlSchemePath
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }

        DispatchQueue.main.async {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:]) { success in
                    completion(success)
                }
            } else {
                // 部分路径在模拟器或特定系统版本下不可用，尝试通用设置路径兜底
                let fallbackURLString = "App-Prefs:"
                if let fallbackURL = URL(string: fallbackURLString),
                   UIApplication.shared.canOpenURL(fallbackURL) {
                    UIApplication.shared.open(fallbackURL, options: [:]) { success in
                        completion(success)
                    }
                } else {
                    completion(false)
                }
            }
        }
    }

    /// 从 Flutter MethodChannel 传入的原始字符串打开设置页面。
    /// - Parameters:
    ///   - rawPage: Flutter 端传入的页面标识符字符串
    ///   - completion: 回调，包含操作结果 Map
    static func openFromRaw(_ rawPage: String?, completion: @escaping ([String: Any?]) -> Void) {
        guard let rawPage = rawPage, !rawPage.isEmpty else {
            completion([
                "success": false,
                "error": "Missing or empty 'page' argument"
            ])
            return
        }

        guard let page = SettingsPage(rawPage: rawPage) else {
            completion([
                "success": false,
                "error": "Unknown settings page: \(rawPage)"
            ])
            return
        }

        open(page: page) { success in
            if success {
                completion(["success": true, "error": nil])
            } else {
                completion([
                    "success": false,
                    "error": "Failed to open settings page: \(rawPage)"
                ])
            }
        }
    }
}
