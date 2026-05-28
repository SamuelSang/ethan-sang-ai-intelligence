import Foundation
import IOKit

// MARK: - PartHistory Model

/// 单条零件修复记录。
struct PartHistory {
    /// 零件类型（如 "display", "battery", "camera" 等）
    let partType: String
    /// 是否为原装零件
    let isGenuine: Bool
    /// 维修机构名称（可选）
    let repairFacility: String?
    /// 维修日期（可选）
    let repairDate: Date?
    /// 零件序列号（可选）
    let serialNumber: String?

    /// 转换为 Flutter MethodChannel 可传输的 Map 格式
    func toDictionary() -> [String: Any?] {
        var dict: [String: Any?] = [
            "partType": partType,
            "isGenuine": isGenuine,
            "repairFacility": repairFacility,
            "serialNumber": serialNumber
        ]
        if let date = repairDate {
            // 以 ISO 8601 字符串传递日期
            dict["repairDate"] = ISO8601DateFormatter().string(from: date)
        } else {
            dict["repairDate"] = nil
        }
        return dict
    }
}

// MARK: - PartsHistoryService

/// 负责从 IORegistry 读取 iOS 17+ 零件修复历史的服务。
struct PartsHistoryService {

    // MARK: - IORegistry 键名常量

    private static let kServiceName     = "AppleARMPMUCharger"  // 电池相关服务示例
    private static let kPartsInfoKey    = "ComponentRepairHistory"

    // MARK: - Public API

    /// 获取零件修复历史记录。
    /// 要求 iOS 17+，且设备未越狱（否则 IORegistry 权限可能异常）。
    /// - Returns: 零件修复历史数组，若不支持或无数据则返回空数组。
    static func fetchPartsHistory() -> [PartHistory] {
        guard #available(iOS 17, *) else {
            return []
        }
        guard !isJailbroken() else {
            return []
        }

        var parts: [PartHistory] = []

        // 尝试从 IORegistry 读取已知包含零件信息的服务
        parts += readFromIORegistry()

        // 若 IORegistry 未返回数据，尝试读取系统诊断日志（沙盒允许范围内）
        if parts.isEmpty {
            parts += readFromDiagnosticLog()
        }

        return parts
    }

    /// 返回适合 Flutter MethodChannel 的 Map 列表。
    static func fetchPartsHistoryAsMaps() -> [[String: Any?]] {
        return fetchPartsHistory().map { $0.toDictionary() }
    }

    // MARK: - Private Helpers

    /// 通过 IORegistry 遍历 IOService 读取零件修复信息。
    private static func readFromIORegistry() -> [PartHistory] {
        var results: [PartHistory] = []

        // 遍历 IOPlatformExpertDevice 获取设备级零件信息
        let matchingDict = IOServiceMatching("IOPlatformExpertDevice")
        let service = IOServiceGetMatchingService(kIOMainPortDefault, matchingDict)
        defer { if service != IO_OBJECT_NULL { IOObjectRelease(service) } }

        guard service != IO_OBJECT_NULL else { return results }

        // 尝试读取 ComponentRepairHistory 属性
        if let rawValue = IORegistryEntryCreateCFProperty(
            service,
            kPartsInfoKey as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() {
            if let historyArray = rawValue as? [[String: Any]] {
                results = historyArray.compactMap { parseIORegistryEntry($0) }
            }
        }

        // 补充：遍历 AppleSmartBattery（电池零件）
        results += readBatteryPartsFromIORegistry()

        return results
    }

    /// 读取电池相关零件信息。
    private static func readBatteryPartsFromIORegistry() -> [PartHistory] {
        var results: [PartHistory] = []

        let matchingDict = IOServiceMatching("AppleSmartBattery")
        var iter: io_iterator_t = IO_OBJECT_NULL
        let kr = IOServiceGetMatchingServices(kIOMainPortDefault, matchingDict, &iter)
        guard kr == KERN_SUCCESS, iter != IO_OBJECT_NULL else { return results }
        defer { IOObjectRelease(iter) }

        var service = IOIteratorNext(iter)
        while service != IO_OBJECT_NULL {
            defer {
                IOObjectRelease(service)
                service = IOIteratorNext(iter)
            }

            // 读取电池序列号
            var serialNumber: String? = nil
            if let snRaw = IORegistryEntryCreateCFProperty(
                service, "BatterySerialNumber" as CFString, kCFAllocatorDefault, 0
            )?.takeRetainedValue() as? String {
                serialNumber = snRaw
            }

            // 读取是否为原装电池（AppleRawMaxCapacity 接近设计容量视为原装标志，此处使用 FCC 标志）
            var isGenuine = true
            if let genuineRaw = IORegistryEntryCreateCFProperty(
                service, "AppleGenuine" as CFString, kCFAllocatorDefault, 0
            )?.takeRetainedValue() as? Bool {
                isGenuine = genuineRaw
            }

            // 读取维修日期（如有）
            var repairDate: Date? = nil
            if let dateRaw = IORegistryEntryCreateCFProperty(
                service, "RepairDate" as CFString, kCFAllocatorDefault, 0
            )?.takeRetainedValue() {
                if let dateInterval = dateRaw as? Double {
                    repairDate = Date(timeIntervalSince1970: dateInterval)
                } else if let dateString = dateRaw as? String {
                    repairDate = ISO8601DateFormatter().date(from: dateString)
                }
            }

            let part = PartHistory(
                partType: "battery",
                isGenuine: isGenuine,
                repairFacility: nil,
                repairDate: repairDate,
                serialNumber: serialNumber
            )
            results.append(part)
        }

        return results
    }

    /// 将 IORegistry 返回的原始字典解析为 PartHistory。
    private static func parseIORegistryEntry(_ dict: [String: Any]) -> PartHistory? {
        guard let partType = dict["PartType"] as? String else { return nil }
        let isGenuine     = dict["IsGenuine"] as? Bool ?? true
        let repairFacility = dict["RepairFacility"] as? String
        let serialNumber   = dict["SerialNumber"] as? String

        var repairDate: Date? = nil
        if let dateString = dict["RepairDate"] as? String {
            repairDate = ISO8601DateFormatter().date(from: dateString)
        } else if let dateInterval = dict["RepairDate"] as? Double {
            repairDate = Date(timeIntervalSince1970: dateInterval)
        }

        return PartHistory(
            partType: partType,
            isGenuine: isGenuine,
            repairFacility: repairFacility,
            repairDate: repairDate,
            serialNumber: serialNumber
        )
    }

    /// 从沙盒内可访问的诊断日志目录读取零件信息（兜底方案）。
    private static func readFromDiagnosticLog() -> [PartHistory] {
        // iOS 沙盒内通常无法直接访问系统级诊断日志，
        // 此方法作为扩展点，可在越狱检测通过后扩充实现。
        return []
    }

    // MARK: - Jailbreak Detection

    /// 简单越狱检测：检查常见越狱路径和沙盒逃逸能力。
    private static func isJailbroken() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/"
        ]
        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        // 尝试写入沙盒外路径
        let testPath = "/private/jailbreak_test_\(UUID().uuidString)"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true
        } catch {
            return false
        }
        #endif
    }
}
