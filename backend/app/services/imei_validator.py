"""
IMEI Validator using Luhn algorithm.
"""

def luhn_checksum(imei: str) -> bool:
    """Validate IMEI using Luhn algorithm."""
    digits = [int(d) for d in imei if d.isdigit()]
    if len(digits) != 15:
        return False

    odd_digits = digits[-1::-2]
    even_digits = digits[-2::-2]

    total = sum(odd_digits)
    for d in even_digits:
        total += sum(divmod(d * 2, 10))

    return total % 10 == 0


def validate_imei(imei: str) -> tuple[bool, str]:
    """
    Validate IMEI format and checksum.
    Returns (is_valid, message).
    """
    cleaned = imei.replace("-", "").replace(" ", "").strip()

    if not cleaned.isdigit():
        return False, "IMEI must contain only digits"

    if len(cleaned) == 16:
        # IMEI-SV format (14 digits + 2)
        cleaned = cleaned[:14]

    if len(cleaned) != 15:
        return False, f"IMEI must be 15 digits, got {len(cleaned)}"

    if not luhn_checksum(cleaned):
        return False, "IMEI checksum validation failed"

    return True, "Valid IMEI"


def get_imei_type(imei: str) -> str:
    """Get type of IMEI based on TAC (Type Allocation Code)."""
    cleaned = "".join(d for d in imei if d.isdigit())
    tac = cleaned[:8]
    manufacturer_tacs = {
        "35209900": "Apple",
        "35752309": "Apple",
        "35882010": "Apple",
        "35367705": "Apple",
        "99000000": "Apple",
        "99000086": "Apple",
    }
    return manufacturer_tacs.get(tac, "Unknown")