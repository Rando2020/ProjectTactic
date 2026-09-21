#!/usr/bin/env python3
"""Wait for a Godot Web canvas to finish loading, then capture two frames."""

from __future__ import annotations

import argparse
import base64
import json
import time
import urllib.request
from pathlib import Path

import websocket


def devtools_target(port: int, timeout: float) -> str:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        try:
            with urllib.request.urlopen(f"http://127.0.0.1:{port}/json", timeout=2) as response:
                targets = json.load(response)
            for target in targets:
                if target.get("type") == "page" and target.get("webSocketDebuggerUrl"):
                    return str(target["webSocketDebuggerUrl"])
        except (OSError, ValueError):
            pass
        time.sleep(0.25)
    raise TimeoutError("Chrome DevTools page target did not become available")


def command(connection, message_id: int, method: str, params: dict | None = None) -> dict:
    payload = {"id": message_id, "method": method}
    if params:
        payload["params"] = params
    connection.send(json.dumps(payload))
    while True:
        response = json.loads(connection.recv())
        if response.get("id") == message_id:
            if "error" in response:
                raise RuntimeError(f"DevTools {method} failed: {response['error']}")
            return response.get("result", {})


def loading_overlay_hidden(connection, message_id: int) -> bool:
    result = command(
        connection,
        message_id,
        "Runtime.evaluate",
        {
            "expression": """
                (() => {
                    const status = document.getElementById('status');
                    if (!status) return true;
                    const style = getComputedStyle(status);
                    return style.visibility === 'hidden' || style.display === 'none';
                })()
            """,
            "returnByValue": True,
        },
    )
    return bool(result.get("result", {}).get("value", False))


def capture(connection, message_id: int, path: Path) -> None:
    result = command(
        connection,
        message_id,
        "Page.captureScreenshot",
        {"format": "png", "fromSurface": True, "captureBeyondViewport": False},
    )
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(base64.b64decode(result["data"]))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=9222)
    parser.add_argument("--timeout", type=float, default=45.0)
    parser.add_argument("--first", type=Path, required=True)
    parser.add_argument("--second", type=Path, required=True)
    args = parser.parse_args()

    ws_url = devtools_target(args.port, args.timeout)
    connection = websocket.create_connection(ws_url, timeout=10, http_proxy_host=None)
    try:
        command(connection, 1, "Page.enable")
        command(connection, 2, "Runtime.enable")
        deadline = time.monotonic() + args.timeout
        message_id = 3
        while time.monotonic() < deadline:
            if loading_overlay_hidden(connection, message_id):
                break
            message_id += 1
            time.sleep(0.5)
        else:
            raise TimeoutError("Godot loading overlay did not become hidden")

        time.sleep(2.0)
        message_id += 1
        capture(connection, message_id, args.first)
        time.sleep(6.0)
        message_id += 1
        capture(connection, message_id, args.second)
    finally:
        connection.close()

    print(f"Browser captures: {args.first}, {args.second}")


if __name__ == "__main__":
    main()
