import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {

    // MARK: - Constants

    private static let channelName = "com.deviceinspector/ios"

    // MARK: - Lifecycle

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // 注册 Flutter MethodChannel
        if let controller = window?.rootViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(
                name: AppDelegate.channelName,
                binaryMessenger: controller.binaryMessenger
            )
            channel.setMethodCallHandler { [weak self] call, result in
                self?.handleMethodCall(call, result: result)
            }
        }

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // MARK: - MethodChannel Handler

    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {

        case "openSettings":
            handleOpenSettings(call: call, result: result)

        case "getPartsHistory":
            handleGetPartsHistory(result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - openSettings

    /// 打开 iOS 系统设置页面。
    /// Flutter 调用格式:
    /// ```dart
    /// channel.invokeMethod('openSettings', {'page': 'general'})
    /// ```
    /// 返回格式: `{'success': bool, 'error': String?}`
    private func handleOpenSettings(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any]
        let rawPage = args?["page"] as? String

        DeepLinkHandler.openFromRaw(rawPage) { resultMap in
            // 将 [String: Any?] 转换为 FlutterResult 可接受的类型
            let flutterMap: [String: Any] = resultMap.compactMapValues { $0 }
            result(flutterMap)
        }
    }

    // MARK: - getPartsHistory

    /// 获取 iOS 17+ 零件修复历史。
    /// Flutter 调用格式:
    /// ```dart
    /// channel.invokeMethod('getPartsHistory')
    /// ```
    /// 返回格式:
    /// ```json
    /// {
    ///   "success": true,
    ///   "data": [
    ///     {
    ///       "partType": "battery",
    ///       "isGenuine": true,
    ///       "repairFacility": null,
    ///       "repairDate": "2024-01-01T00:00:00Z",
    ///       "serialNumber": "XXXX"
    ///     }
    ///   ],
    ///   "error": null
    /// }
    /// ```
    private func handleGetPartsHistory(result: @escaping FlutterResult) {
        guard #available(iOS 17, *) else {
            let response: [String: Any] = [
                "success": false,
                "data": [],
                "error": "Parts history requires iOS 17 or later"
            ]
            result(response)
            return
        }

        // 在后台线程执行 IORegistry 读取，避免阻塞主线程
        DispatchQueue.global(qos: .userInitiated).async {
            let partsData = PartsHistoryService.fetchPartsHistoryAsMaps()

            DispatchQueue.main.async {
                // 将 [String: Any?] 中的 Optional 值处理为 Flutter 可传输的类型
                let sanitizedData: [[String: Any]] = partsData.map { item in
                    item.compactMapValues { $0 }
                }

                let response: [String: Any] = [
                    "success": true,
                    "data": sanitizedData,
                    "error": NSNull()
                ]
                result(response)
            }
        }
    }
}
