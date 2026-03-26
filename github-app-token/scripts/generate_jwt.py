#!/usr/bin/env python3
"""Generate a JWT for GitHub App authentication.

Reads from environment variables:
  GITHUB_APP_ID       - The GitHub App's numeric ID
  GITHUB_APP_PEM_FILE  - Path to the PEM-encoded private key file

Prints the signed JWT to stdout.
"""

import json
import os
import sys
import time
import base64
import hashlib

try:
    from cryptography.hazmat.primitives import hashes, serialization
    from cryptography.hazmat.primitives.asymmetric import padding

    USE_CRYPTOGRAPHY = True
except ImportError:
    import subprocess

    USE_CRYPTOGRAPHY = False


def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


def sign_with_cryptography(unsigned: str, pem_key: str) -> str:
    private_key = serialization.load_pem_private_key(pem_key.encode(), password=None)
    signature = private_key.sign(unsigned.encode(), padding.PKCS1v15(), hashes.SHA256())
    return b64url(signature)


def sign_with_openssl(unsigned: str, pem_key: str) -> str:
    result = subprocess.run(
        ["openssl", "dgst", "-sha256", "-sign", "/dev/stdin"],
        input=pem_key.encode(),
        capture_output=True,
        check=True,
        env={**os.environ, "OPENSSL_CONF": "/dev/null"},
    )
    # openssl dgst -sign reads key from stdin on some versions, but not all.
    # If that fails, write to a temp file.
    if result.returncode != 0:
        import tempfile

        with tempfile.NamedTemporaryFile(mode="w", suffix=".pem", delete=False) as f:
            f.write(pem_key)
            f.flush()
            result = subprocess.run(
                ["openssl", "dgst", "-sha256", "-sign", f.name],
                input=unsigned.encode(),
                capture_output=True,
                check=True,
            )
            os.unlink(f.name)
    return b64url(result.stdout)


def main():
    app_id = os.environ.get("GITHUB_APP_ID")
    pem_file = os.environ.get("GITHUB_APP_PEM_FILE")

    if not app_id:
        print("error: GITHUB_APP_ID is not set", file=sys.stderr)
        sys.exit(1)
    if not pem_file:
        print("error: GITHUB_APP_PEM_FILE is not set", file=sys.stderr)
        sys.exit(1)
    if not os.path.isfile(pem_file):
        print(f"error: PEM file not found: {pem_file}", file=sys.stderr)
        sys.exit(1)

    with open(pem_file, "r") as f:
        pem_key = f.read()

    now = int(time.time())
    header = b64url(json.dumps({"alg": "RS256", "typ": "JWT"}).encode())
    payload = b64url(
        json.dumps({"iat": now - 60, "exp": now + 600, "iss": app_id}).encode()
    )
    unsigned = f"{header}.{payload}"

    if USE_CRYPTOGRAPHY:
        signature = sign_with_cryptography(unsigned, pem_key)
    else:
        signature = sign_with_openssl(unsigned, pem_key)

    print(f"{unsigned}.{signature}")


if __name__ == "__main__":
    main()
