import json
import base64
import hashlib
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding, rsa
from cryptography.hazmat.backends import default_backend
from pathlib import Path


class ReportSigner:
    """
    RSA-SHA256 report signing service.
    Generates and verifies signatures for inspection reports.
    """

    def __init__(self, private_key_path: str = None):
        if private_key_path is None:
            key_dir = Path(__file__).parent.parent.parent / "keys"
            key_path = key_dir / "private_key.pem"
        else:
            key_path = Path(private_key_path)

        if key_path.exists():
            with open(key_path, "rb") as f:
                self.private_key = serialization.load_pem_private_key(
                    f.read(), password=None, backend=default_backend()
                )
        else:
            # Generate a new key pair for demo (in production, use persistent keys)
            self.private_key = rsa.generate_private_key(
                public_exponent=65537,
                key_size=2048,
                backend=default_backend()
            )
            # Save private key for demo purposes
            if private_key_path is None:
                self._save_demo_key()
            else:
                key_path.parent.mkdir(parents=True, exist_ok=True)
                with open(key_path, "wb") as f:
                    f.write(self.private_key.private_bytes(
                        encoding=serialization.Encoding.PEM,
                        format=serialization.PrivateFormat.PKCS8,
                        encryption_algorithm=serialization.NoEncryption()
                    ))

    def _save_demo_key(self):
        """Save private key to file for demo (in production, use secure key storage)."""
        key_dir = Path(__file__).parent.parent.parent / "keys"
        key_dir.mkdir(exist_ok=True)
        private_key_path = key_dir / "private_key.pem"

        with open(private_key_path, "wb") as f:
            f.write(self.private_key.private_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PrivateFormat.PKCS8,
                encryption_algorithm=serialization.NoEncryption()
            ))

    def sign(self, report_data: dict) -> str:
        """
        Sign report data with RSA-SHA256.

        Args:
            report_data: Dictionary containing report fields

        Returns:
            Base64-encoded signature
        """
        # Canonicalize JSON (sorted keys for consistency)
        canonical_json = json.dumps(report_data, sort_keys=True, ensure_ascii=False)

        # Hash the report data
        digest = hashes.Hash(hashes.SHA256(), backend=default_backend())
        digest.update(canonical_json.encode("utf-8"))
        content_hash = digest.finalize()

        # Sign with RSA
        signature = self.private_key.sign(
            content_hash,
            padding.PKCS1v15(),
            hashes.SHA256()
        )

        return base64.b64encode(signature).decode("utf-8")

    def verify(self, report_data: dict, signature: str) -> bool:
        """
        Verify report signature.

        Args:
            report_data: Original report data
            signature: Base64-encoded signature to verify

        Returns:
            True if signature is valid, False otherwise
        """
        try:
            public_key = self.private_key.public_key()

            canonical_json = json.dumps(report_data, sort_keys=True, ensure_ascii=False)
            digest = hashes.Hash(hashes.SHA256(), backend=default_backend())
            digest.update(canonical_json.encode("utf-8"))
            content_hash = digest.finalize()

            signature_bytes = base64.b64decode(signature)

            public_key.verify(
                signature_bytes,
                content_hash,
                padding.PKCS1v15(),
                hashes.SHA256()
            )
            return True
        except Exception:
            return False

    def get_public_key_pem(self) -> str:
        """Get public key in PEM format for verification."""
        public_key = self.private_key.public_key()
        return public_key.public_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PublicFormat.SubjectPublicKeyInfo
        ).decode("utf-8")