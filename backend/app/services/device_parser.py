"""
Device model parser based on serial number and IMEI.
Contains mapping of iPhone serial number prefixes to models and regions.
"""

from dataclasses import dataclass
from typing import Optional


@dataclass
class DeviceModel:
    model: str
    model_name: str
    region: str
    launch_year: int
    is_refurbished_possible: bool


# iPhone Serial Number Prefix → Model Mapping
# Serial numbers starting from different blocks indicate different production locations/times
SERIAL_PREFIX_MAP = {
    # iPhone 15 Pro Max
    "G0CW": DeviceModel("iPhone 15 Pro Max", "A3078", "China", 2023, True),
    "G0F5": DeviceModel("iPhone 15 Pro Max", "A3078", "China", 2023, True),
    "G0NQ": DeviceModel("iPhone 15 Pro Max", "A3078", "USA", 2023, False),
    # iPhone 15 Pro
    "G0L9": DeviceModel("iPhone 15 Pro", "A2848", "China", 2023, True),
    "G0N5": DeviceModel("iPhone 15 Pro", "A2848", "USA", 2023, False),
    # iPhone 15
    "G0L7": DeviceModel("iPhone 15", "A3090", "China", 2023, True),
    "G0M0": DeviceModel("iPhone 15", "A3090", "USA", 2023, False),
    # iPhone 14 Pro Max
    "F5GW": DeviceModel("iPhone 14 Pro Max", "A2896", "China", 2022, True),
    "F5NG": DeviceModel("iPhone 14 Pro Max", "A2896", "USA", 2022, False),
    "F5NK": DeviceModel("iPhone 14 Pro Max", "A2896", "Ireland", 2022, False),
    # iPhone 14 Pro
    "F5FL": DeviceModel("iPhone 14 Pro", "A2890", "China", 2022, True),
    "F5NH": DeviceModel("iPhone 14 Pro", "A2890", "USA", 2022, False),
    "F5NL": DeviceModel("iPhone 14 Pro", "A2890", "Ireland", 2022, False),
    # iPhone 14
    "F1LN": DeviceModel("iPhone 14", "A2885", "USA", 2022, False),
    "F1LQ": DeviceModel("iPhone 14", "A2885", "China", 2022, True),
    # iPhone 13 Pro Max
    "C7FW": DeviceModel("iPhone 13 Pro Max", "A2644", "China", 2021, True),
    "C7GX": DeviceModel("iPhone 13 Pro Max", "A2644", "USA", 2021, False),
    # iPhone 13 Pro
    "C7FH": DeviceModel("iPhone 13 Pro", "A2638", "China", 2021, True),
    "C7G4": DeviceModel("iPhone 13 Pro", "A2638", "USA", 2021, False),
    # iPhone 13
    "C7FG": DeviceModel("iPhone 13", "A2632", "China", 2021, True),
    "C7G3": DeviceModel("iPhone 13", "A2632", "USA", 2021, False),
    # iPhone 12 Pro Max
    "G6NW": DeviceModel("iPhone 12 Pro Max", "A2408", "China", 2020, True),
    "G6PW": DeviceModel("iPhone 12 Pro Max", "A2408", "USA", 2020, False),
    # iPhone 12 Pro
    "G6NX": DeviceModel("iPhone 12 Pro", "A2407", "China", 2020, True),
    "G6PX": DeviceModel("iPhone 12 Pro", "A2407", "USA", 2020, False),
    # iPhone 12
    "C4GW": DeviceModel("iPhone 12", "A2405", "China", 2020, True),
    "C4GX": DeviceModel("iPhone 12", "A2405", "USA", 2020, False),
    # iPhone SE (3rd gen)
    "C9KL": DeviceModel("iPhone SE (3rd gen)", "A2783", "China", 2022, True),
    "C9KK": DeviceModel("iPhone SE (3rd gen)", "A2783", "USA", 2022, False),
    # Older models
    "D22N": DeviceModel("iPhone 11 Pro", "A2218", "China", 2019, True),
    "D22L": DeviceModel("iPhone 11 Pro", "A2218", "USA", 2019, False),
    "D221": DeviceModel("iPhone 11 Pro Max", "A2220", "China", 2019, True),
    "D21W": DeviceModel("iPhone 11 Pro Max", "A2220", "USA", 2019, False),
}

# Production year/date code from 3rd-4th character of serial
YEAR_CODE = {
    "C": 2018, "D": 2019, "F": 2020, "G": 2021, "H": 2022,
    "J": 2023, "K": 2024, "L": 2025
}

# Production week code from 5th character
WEEK_CODE = "123456789ABCDEFGHJKLMNPQRSTUVWXYZ"


def parse_serial_number(serial: str) -> Optional[DeviceModel]:
    """
    Parse iPhone serial number to identify model, region, and production info.
    Supports both full 12-char serials and 4-char production prefixes.

    Format (full 12-char): AABCCDDVVSS where:
      AA = manufacturing team
      B = year code (C=2018, D=2019, F=2020, G=2021, H=2022, J=2023)
      CC = week code
      DD = device id (model)
      VV = variant
      SS = config
    """
    serial = serial.upper().strip()
    serial_len = len(serial)

    if serial_len == 12:
        # Full serial number
        prefix = serial[:4]
        if prefix in SERIAL_PREFIX_MAP:
            return SERIAL_PREFIX_MAP[prefix]

        # Extended lookup for 3-char prefixes
        prefix_3char = serial[:3]
        if len(prefix_3char) == 3 and prefix_3char.isalpha():
            return DeviceModel(
                model=f"Unknown (prefix: {prefix_3char})",
                model_name="Unknown",
                region="Unknown",
                launch_year=0,
                is_refurbished_possible=True
            )
        return None

    elif serial_len == 4:
        # 4-char production prefix (e.g., "G0L9")
        if serial in SERIAL_PREFIX_MAP:
            return SERIAL_PREFIX_MAP[serial]
        return None

    elif serial_len >= 3:
        # 3-char prefix lookup
        prefix_3char = serial[:3]
        if prefix_3char in SERIAL_PREFIX_MAP:
            return SERIAL_PREFIX_MAP[prefix_3char]
        for key in SERIAL_PREFIX_MAP:
            if key.startswith(prefix_3char):
                return SERIAL_PREFIX_MAP[key]
        return DeviceModel(
            model=f"Unknown (prefix: {prefix_3char})",
            model_name="Unknown",
            region="Unknown",
            launch_year=0,
            is_refurbished_possible=True
        )

    return None


def is_refurbished_serial(serial: str) -> bool:
    """
    Detect if a serial number indicates a refurbished device.
    Refurbished devices typically have 'F' as second character or
    specific prefixes that indicate reworked units.
    """
    serial = serial.upper()
    if len(serial) < 4:
        return False

    # Second character 'F' often indicates refurbished
    if serial[1] == 'F':
        return True

    # Specific refurbished prefixes
    refurb_prefixes = ["D", "F"]
    if serial[0] in refurb_prefixes and any(c.isdigit() for c in serial[1:3]):
        return True

    return False


def get_region_from_imei(imei: str) -> str:
    """
    Extract region from IMEI TAC (first 8 digits).
    This is a simplified version - real implementation would use a full database.
    """
    if len(imei) < 15:
        return "Unknown"

    tac = imei[:8]

    # Simplified region mapping based on TAC
    region_map = {
        "352099": "China",
        "357523": "USA",
        "358820": "USA",
        "353677": "Europe",
        "990000": "USA",
    }

    for prefix, region in region_map.items():
        if tac.startswith(prefix):
            return region

    return "Unknown"


def identify_device_model(serial: str, imei: Optional[str] = None) -> dict:
    """
    Identify device model from serial number and/or IMEI.
    Returns a dict with model info.
    """
    result = {
        "model": None,
        "model_name": None,
        "region": None,
        "launch_year": None,
        "is_refurbished": False,
        "serial_valid": False,
        "imei_valid": False,
        "source": None
    }

    # Parse serial number first
    device_info = parse_serial_number(serial)
    if device_info:
        result["model"] = device_info.model
        result["model_name"] = device_info.model_name
        result["region"] = device_info.region
        result["launch_year"] = device_info.launch_year
        result["is_refurbished"] = is_refurbished_serial(serial)
        result["serial_valid"] = True
        result["source"] = "serial"

    # Check IMEI if provided
    if imei and len(imei) >= 15:
        result["imei_valid"] = True
        if not result["region"] or result["region"] == "Unknown":
            result["region"] = get_region_from_imei(imei)

    return result