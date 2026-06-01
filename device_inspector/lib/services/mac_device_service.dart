import 'dart:io';

/// Mac设备信息服务
/// 通过system_profiler获取Mac硬件信息
class MacDeviceService {
  /// 获取Mac硬件信息
  Future<MacDeviceInfo> getMacDeviceInfo() async {
    try {
      final result = await Process.run(
        'system_profiler',
        ['SPHardwareDataType', '-json'],
      );
      if (result.exitCode != 0) {
        return MacDeviceInfo.empty();
      }

      final json = result.stdout.toString();
      final data = _parseSystemProfilerJson(json);
      return MacDeviceInfo.fromJson(data);
    } catch (e) {
      return MacDeviceInfo.empty();
    }
  }

  /// 获取电池信息
  Future<BatteryInfo> getBatteryInfo() async {
    try {
      final result = await Process.run(
        'system_profiler',
        ['SPBatteryDataType', '-json'],
      );
      if (result.exitCode != 0) {
        return BatteryInfo.empty();
      }

      final json = result.stdout.toString();
      final data = _parseSystemProfilerJson(json);
      return BatteryInfo.fromJson(data);
    } catch (e) {
      return BatteryInfo.empty();
    }
  }

  /// 获取维修历史 (如果有AppleCare)
  Future<String?> getAppleCareStatus() async {
    try {
      final result = await Process.run(
        'system_profiler',
        ['SPRepairDataType', '-json'],
      );
      if (result.exitCode != 0) return null;

      final json = result.stdout.toString();
      if (json.isEmpty) return null;

      final data = _parseSystemProfilerJson(json);
      // Repair data format varies, return raw string for now
      return data['repair']?.toString();
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> _parseSystemProfilerJson(String json) {
    try {
      // system_profiler -json outputs a JSON object with categories as keys
      // Each category contains an array of items
      // We need to extract the first level data
      final lines = json.split('\n');
      final buffer = StringBuffer();
      bool inArray = false;
      int depth = 0;

      for (final line in lines) {
        if (line.trim() == '[') {
          inArray = true;
          depth = 1;
          buffer.writeln(line);
        } else if (line.trim() == ']') {
          depth--;
          buffer.writeln(line);
          if (depth == 0) {
            inArray = false;
          }
        } else if (inArray) {
          buffer.writeln(line);
        }
      }

      if (buffer.isEmpty) {
        // Try simple parsing
        final startIndex = json.indexOf('[');
        final endIndex = json.lastIndexOf(']');
        if (startIndex != -1 && endIndex != -1) {
          final jsonArray = json.substring(startIndex, endIndex + 1);
          return {'items': _parseJsonArray(jsonArray)};
        }
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  List<Map<String, dynamic>> _parseJsonArray(String jsonArray) {
    // Simple JSON array parser for system_profiler output
    final items = <Map<String, dynamic>>[];
    try {
      // Find each object in the array
      int start = jsonArray.indexOf('{');
      while (start != -1) {
        int end = start;
        int depth = 0;
        bool inString = false;
        bool escape = false;

        while (end < jsonArray.length) {
          final c = jsonArray[end];
          if (escape) {
            escape = false;
          } else if (c == '\\') {
            escape = true;
          } else if (c == '"') {
            inString = !inString;
          } else if (!inString) {
            if (c == '{') depth++;
            if (c == '}') {
              depth--;
              if (depth == 0) {
                break;
              }
            }
          }
          end++;
        }

        if (end > start) {
          final objStr = jsonArray.substring(start, end + 1);
          items.add(_parseJsonObject(objStr));
        }
        start = jsonArray.indexOf('{', end + 1);
      }
    } catch (e) {
      // Ignore parse errors
    }
    return items;
  }

  Map<String, dynamic> _parseJsonObject(String json) {
    final result = <String, dynamic>{};
    try {
      final content = json.substring(1, json.length - 1);
      String? currentKey;
      StringBuffer valueBuffer = StringBuffer();
      bool inString = false;
      bool escape = false;
      int depth = 0;

      for (int i = 0; i < content.length; i++) {
        final c = content[i];
        if (escape) {
          valueBuffer.write(c);
          escape = false;
        } else if (c == '\\') {
          escape = true;
        } else if (c == '"') {
          inString = !inString;
          if (!inString && currentKey != null) {
            final value = valueBuffer.toString().trim();
            if (value.startsWith('{')) {
              // Nested object - parse recursively
              int end = i;
              int nestedDepth = 0;
              bool nestedInString = false;
              bool nestedEscape = false;

              while (end < content.length) {
                final nc = content[end];
                if (nestedEscape) {
                  nestedEscape = false;
                } else if (nc == '\\') {
                  nestedEscape = true;
                } else if (nc == '"') {
                  nestedInString = !nestedInString;
                } else if (!nestedInString) {
                  if (nc == '{') nestedDepth++;
                  if (nc == '}') {
                    nestedDepth--;
                    if (nestedDepth == 0) break;
                  }
                }
                end++;
              }
              result[currentKey] = _parseJsonObject(content.substring(i, end + 1));
              i = end;
              valueBuffer = StringBuffer();
              currentKey = null;
            } else {
              result[currentKey] = _convertJsonValue(value);
              i = i; // Don't increment - will be incremented in loop
              valueBuffer = StringBuffer();
              currentKey = null;
            }
          }
        } else if (inString) {
          valueBuffer.write(c);
        } else if (c == ':') {
          currentKey = valueBuffer.toString().trim();
          if (currentKey.startsWith('"')) {
            currentKey = currentKey.substring(1, currentKey.length - 1);
          }
          valueBuffer = StringBuffer();
        } else if (c == ',' || c == '\n' || c == ' ') {
          if (currentKey != null && valueBuffer.isNotEmpty) {
            result[currentKey] = _convertJsonValue(valueBuffer.toString().trim());
            valueBuffer = StringBuffer();
            currentKey = null;
          }
        } else {
          valueBuffer.write(c);
        }
      }
    } catch (e) {
      // Return empty on parse error
    }
    return result;
  }

  dynamic _convertJsonValue(String value) {
    if (value.isEmpty) return value;

    // Remove quotes if present
    if (value.startsWith('"') && value.endsWith('"')) {
      return value.substring(1, value.length - 1);
    }

    // Try parsing as number
    final intVal = int.tryParse(value);
    if (intVal != null) return intVal;

    final doubleVal = double.tryParse(value);
    if (doubleVal != null) return doubleVal;

    // Boolean
    if (value == 'true') return true;
    if (value == 'false') return false;

    return value;
  }
}

/// Mac设备硬件信息
class MacDeviceInfo {
  final String? modelName;        // e.g. "MacBook Pro"
  final String? modelIdentifier;  // e.g. "Mac14Pro"
  final String? serialNumber;
  final String? processorName;    // e.g. "Apple M2 Pro"
  final int? processorCores;
  final int? memory;             // GB
  final String? storage;         // e.g. "512GB SSD"
  final String? hardwareUuid;
  final String? osVersion;

  MacDeviceInfo({
    this.modelName,
    this.modelIdentifier,
    this.serialNumber,
    this.processorName,
    this.processorCores,
    this.memory,
    this.storage,
    this.hardwareUuid,
    this.osVersion,
  });

  factory MacDeviceInfo.empty() => MacDeviceInfo();

  factory MacDeviceInfo.fromJson(Map<String, dynamic> json) {
    // system_profiler -json returns hardware info under a hardware key
    final hardware = json['hardware'] as List<dynamic>?;
    if (hardware == null || hardware.isEmpty) {
      return MacDeviceInfo();
    }

    final data = hardware.first as Map<String, dynamic>;
    return MacDeviceInfo(
      modelName: data['machine_name']?.toString(),
      modelIdentifier: data['machine_model']?.toString(),
      serialNumber: data['sp_hardware_serial']?.toString(),
      processorName: data['chip_type']?.toString(),
      processorCores: _parseInt(data['cpu_type']),
      memory: _parseInt(data['sp_memory']),
      storage: data['sp disks_storage']?.toString(),
      hardwareUuid: data['hardware_uuid']?.toString(),
      osVersion: data['os_version']?.toString(),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    final str = value.toString().replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(str);
  }
}

/// 电池信息
class BatteryInfo {
  final int? cycleCount;
  final int? maxCapacity;        // mAh
  final int? currentCapacity;    // mAh
  final bool? isCharging;
  final bool? isFullyCharged;
  final String? health;

  BatteryInfo({
    this.cycleCount,
    this.maxCapacity,
    this.currentCapacity,
    this.isCharging,
    this.isFullyCharged,
    this.health,
  });

  factory BatteryInfo.empty() => BatteryInfo();

  factory BatteryInfo.fromJson(Map<String, dynamic> json) {
    final battery = json['battery'] as List<dynamic>?;
    if (battery == null || battery.isEmpty) {
      return BatteryInfo();
    }

    final data = battery.first as Map<String, dynamic>;
    return BatteryInfo(
      cycleCount: _parseInt(data['cycle_count']),
      maxCapacity: _parseInt(data['max_capacity']),
      currentCapacity: _parseInt(data['current_capacity']),
      isCharging: data['is_charging'] == true || data['is_charging'] == 'true',
      isFullyCharged: data['fully_charged'] == true || data['fully_charged'] == 'true',
      health: data['health']?.toString(),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    final str = value.toString().replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(str);
  }
}