#!/usr/bin/env python3

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import socket
import ssl
from typing import List, Tuple


DEFAULT_CONFIG = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "config", "sites.json"
)


def load_sites(path: str) -> List[Tuple[str, int]]:
    with open(path, "r", encoding="utf-8") as handle:
        data = json.load(handle)
    if not isinstance(data, dict) or "sites" not in data:
        raise ValueError("Config file must contain a 'sites' array")

    hosts: List[Tuple[str, int]] = []
    for entry in data["sites"]:
        if isinstance(entry, str):
            hosts.append((entry, 443))
            continue
        if isinstance(entry, dict) and entry.get("host"):
            hosts.append((entry["host"], int(entry.get("port", 443))))
    if not hosts:
        raise ValueError("Provide at least one site in the config file")
    return hosts


def get_expiry(host: str, port: int, timeout: float) -> dt.datetime:
    context = ssl.create_default_context()
    with socket.create_connection((host, port), timeout=timeout) as sock:
        with context.wrap_socket(sock, server_hostname=host) as tls_sock:
            cert = tls_sock.getpeercert()
    not_after = cert.get("notAfter")
    if not_after is None:
        raise ValueError("Certificate missing notAfter field")
    expires = dt.datetime.strptime(not_after, "%b %d %H:%M:%S %Y %Z")
    return expires.replace(tzinfo=dt.timezone.utc)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Print HTTPS certificate expiry for a list of sites."
    )
    parser.add_argument(
        "-c",
        "--config",
        default=DEFAULT_CONFIG,
        help=f"Path to JSON config file (default: {DEFAULT_CONFIG})",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=5.0,
        help="Socket timeout in seconds. Default: 5",
    )
    args = parser.parse_args()

    try:
        targets = load_sites(args.config)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        raise SystemExit(f"Failed to load config: {exc}") from exc

    print(f"Checking {len(targets)} site(s)...")
    now = dt.datetime.now(dt.timezone.utc)
    for host, port in targets:
        try:
            expires = get_expiry(host, port, args.timeout)
            days_left = (expires - now).days
            when = expires.strftime("%Y-%m-%d %H:%M:%S %Z")
            print(f"{host}:{port} -> expires {when} ({days_left} days left)")
        except Exception as exc:
            print(f"{host}:{port} -> ERROR: {exc}")


if __name__ == "__main__":
    main()
