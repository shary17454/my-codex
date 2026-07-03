import argparse
import base64
import hashlib
import json
import os
import socket
import struct
import urllib.request


GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"


def get_page_ws(port: int, url_contains: str = "") -> str:
    with urllib.request.urlopen(f"http://127.0.0.1:{port}/json/list", timeout=10) as res:
        targets = json.loads(res.read().decode("utf-8"))
    for target in targets:
        if target.get("type") == "page" and url_contains in target.get("url", ""):
            return target["webSocketDebuggerUrl"]
    for target in targets:
        if target.get("type") == "page":
            return target["webSocketDebuggerUrl"]
    raise SystemExit("No page target found")


def parse_ws_url(ws_url: str):
    if not ws_url.startswith("ws://"):
        raise SystemExit("Only ws:// URLs are supported")
    rest = ws_url[len("ws://") :]
    host_port, path = rest.split("/", 1)
    host, port = host_port.split(":")
    return host, int(port), "/" + path


def recv_exact(sock, n):
    chunks = []
    remaining = n
    while remaining:
        chunk = sock.recv(remaining)
        if not chunk:
            raise ConnectionError("socket closed")
        chunks.append(chunk)
        remaining -= len(chunk)
    return b"".join(chunks)


def ws_recv(sock):
    first = recv_exact(sock, 2)
    b1, b2 = first
    opcode = b1 & 0x0F
    length = b2 & 0x7F
    if length == 126:
        length = struct.unpack("!H", recv_exact(sock, 2))[0]
    elif length == 127:
        length = struct.unpack("!Q", recv_exact(sock, 8))[0]
    masked = b2 & 0x80
    mask = recv_exact(sock, 4) if masked else b""
    payload = recv_exact(sock, length) if length else b""
    if masked:
        payload = bytes(b ^ mask[i % 4] for i, b in enumerate(payload))
    if opcode == 8:
        raise ConnectionError("websocket closed")
    if opcode == 9:
        return ws_recv(sock)
    return payload.decode("utf-8")


def ws_send(sock, text: str):
    payload = text.encode("utf-8")
    header = bytearray([0x81])
    length = len(payload)
    if length < 126:
        header.append(0x80 | length)
    elif length < 65536:
        header.append(0x80 | 126)
        header.extend(struct.pack("!H", length))
    else:
        header.append(0x80 | 127)
        header.extend(struct.pack("!Q", length))
    mask = os.urandom(4)
    header.extend(mask)
    encoded = bytes(b ^ mask[i % 4] for i, b in enumerate(payload))
    sock.sendall(bytes(header) + encoded)


def connect(ws_url: str):
    host, port, path = parse_ws_url(ws_url)
    sock = socket.create_connection((host, port), timeout=15)
    key = base64.b64encode(os.urandom(16)).decode("ascii")
    req = (
        f"GET {path} HTTP/1.1\r\n"
        f"Host: {host}:{port}\r\n"
        "Upgrade: websocket\r\n"
        "Connection: Upgrade\r\n"
        f"Sec-WebSocket-Key: {key}\r\n"
        "Sec-WebSocket-Version: 13\r\n\r\n"
    )
    sock.sendall(req.encode("ascii"))
    response = b""
    while b"\r\n\r\n" not in response:
        response += sock.recv(4096)
    if b" 101 " not in response.split(b"\r\n", 1)[0]:
        raise SystemExit(response.decode("utf-8", "replace"))
    accept = base64.b64encode(hashlib.sha1((key + GUID).encode("ascii")).digest())
    if accept not in response:
        raise SystemExit("WebSocket accept mismatch")
    return sock


def call(sock, msg_id: int, method: str, params=None):
    ws_send(sock, json.dumps({"id": msg_id, "method": method, "params": params or {}}))
    while True:
        data = json.loads(ws_recv(sock))
        if data.get("id") == msg_id:
            return data


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=9222)
    parser.add_argument("--url-contains", default="partsouq.com")
    parser.add_argument("--expr", required=True)
    args = parser.parse_args()

    ws_url = get_page_ws(args.port, args.url_contains)
    sock = connect(ws_url)
    call(sock, 1, "Runtime.enable")
    result = call(
        sock,
        2,
        "Runtime.evaluate",
        {
            "expression": args.expr,
            "awaitPromise": True,
            "returnByValue": True,
            "timeout": 30000,
        },
    )
    print(json.dumps(result, ensure_ascii=False))


if __name__ == "__main__":
    main()
