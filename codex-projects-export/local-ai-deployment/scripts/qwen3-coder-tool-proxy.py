#!/usr/bin/env python3
"""OpenAI Chat Completions proxy for Qwen3-Coder XML tool calls.

Qwen3-Coder uses an XML function-call format that some llama.cpp builds expose
as ordinary message content.  This proxy converts complete XML calls into the
standard OpenAI ``message.tool_calls`` representation.  All other endpoints
and ordinary assistant messages are forwarded without semantic changes.
"""

from __future__ import annotations

import argparse
import gzip
import html
import json
import os
import re
import secrets
import sys
import time
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Any


FUNCTION_RE = re.compile(
    r"<function=([A-Za-z0-9_.:-]+)>\s*(.*?)\s*</function>", re.DOTALL
)
PARAMETER_RE = re.compile(
    r"<parameter=([A-Za-z0-9_.:-]+)>\s*(.*?)\s*</parameter>", re.DOTALL
)
JSON_TOOLS_RE = re.compile(r"<tools>\s*(\{.*?\})\s*</tools>", re.DOTALL)


def _parameter_types(tools: list[dict[str, Any]]) -> dict[str, dict[str, str]]:
    result: dict[str, dict[str, str]] = {}
    for tool in tools:
        function = tool.get("function") if isinstance(tool, dict) else None
        if not isinstance(function, dict):
            continue
        name = function.get("name")
        properties = function.get("parameters", {}).get("properties", {})
        if not isinstance(name, str) or not isinstance(properties, dict):
            continue
        result[name] = {
            key: value.get("type", "string")
            for key, value in properties.items()
            if isinstance(key, str) and isinstance(value, dict)
        }
    return result


def _coerce(value: str, expected_type: str) -> Any:
    value = html.unescape(value.strip())
    try:
        if expected_type == "integer":
            return int(value)
        if expected_type == "number":
            return float(value)
        if expected_type == "boolean":
            lowered = value.lower()
            if lowered == "true":
                return True
            if lowered == "false":
                return False
        if expected_type in {"array", "object"}:
            return json.loads(value)
        if expected_type == "null" and value.lower() == "null":
            return None
    except (TypeError, ValueError, json.JSONDecodeError):
        pass
    return value


def parse_tool_calls(
    content: str | None, tools: list[dict[str, Any]]
) -> tuple[str | None, list[dict[str, Any]]]:
    if not content:
        return content, []

    parameter_types = _parameter_types(tools)
    parsed: list[dict[str, Any]] = []
    matches = list(FUNCTION_RE.finditer(content))

    for match in matches:
        name = match.group(1)
        arguments: dict[str, Any] = {}
        for parameter in PARAMETER_RE.finditer(match.group(2)):
            parameter_name = parameter.group(1)
            expected_type = parameter_types.get(name, {}).get(parameter_name, "string")
            arguments[parameter_name] = _coerce(parameter.group(2), expected_type)
        parsed.append(
            {
                "id": f"call_{secrets.token_hex(12)}",
                "type": "function",
                "function": {
                    "name": name,
                    "arguments": json.dumps(arguments, ensure_ascii=False),
                },
            }
        )

    # Also accept the occasionally emitted <tools>{...}</tools> variant.
    if not parsed:
        for match in JSON_TOOLS_RE.finditer(content):
            try:
                item = json.loads(match.group(1))
            except json.JSONDecodeError:
                continue
            name = item.get("name")
            arguments = item.get("arguments")
            if not isinstance(name, str) or not isinstance(arguments, dict):
                continue
            parsed.append(
                {
                    "id": f"call_{secrets.token_hex(12)}",
                    "type": "function",
                    "function": {
                        "name": name,
                        "arguments": json.dumps(arguments, ensure_ascii=False),
                    },
                }
            )
        matches = list(JSON_TOOLS_RE.finditer(content))

    if not parsed:
        return content, []

    prefix = content[: matches[0].start()]
    prefix = re.sub(r"<tool_call>\s*$", "", prefix, flags=re.DOTALL).strip()
    return prefix or None, parsed


def transform_chat_completion(
    response: dict[str, Any], request_body: dict[str, Any]
) -> tuple[dict[str, Any], int]:
    parsed_count = 0
    tools = request_body.get("tools", [])
    if not isinstance(tools, list):
        tools = []

    for choice in response.get("choices", []):
        message = choice.get("message")
        if not isinstance(message, dict) or message.get("tool_calls"):
            continue
        content, tool_calls = parse_tool_calls(message.get("content"), tools)
        if not tool_calls:
            continue
        message["content"] = content
        message["tool_calls"] = tool_calls
        choice["finish_reason"] = "tool_calls"
        parsed_count += len(tool_calls)
    return response, parsed_count


class ProxyHandler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    server_version = "qwen3-coder-tool-proxy/1.0"

    @property
    def backend(self) -> str:
        return self.server.backend  # type: ignore[attr-defined]

    @property
    def upstream_timeout(self) -> float:
        return self.server.upstream_timeout  # type: ignore[attr-defined]

    def log_message(self, fmt: str, *args: Any) -> None:
        sys.stdout.write(
            f"{time.strftime('%Y-%m-%dT%H:%M:%S%z')} " + (fmt % args) + "\n"
        )
        sys.stdout.flush()

    def _request_headers(self, body: bytes | None) -> dict[str, str]:
        headers: dict[str, str] = {"Accept-Encoding": "gzip"}
        for name in ("Accept", "Authorization", "Range", "User-Agent"):
            value = self.headers.get(name)
            if value:
                headers[name] = value
        content_type = self.headers.get("Content-Type")
        if content_type:
            headers["Content-Type"] = content_type
        elif body is not None:
            headers["Content-Type"] = "application/json"
        return headers

    @staticmethod
    def _decode_gzip(
        method: str, headers: dict[str, str], payload: bytes
    ) -> tuple[dict[str, str], bytes]:
        if method != "HEAD" and headers.get("Content-Encoding", "").lower() == "gzip":
            payload = gzip.decompress(payload)
            headers.pop("Content-Encoding", None)
            headers.pop("Content-Length", None)
        return headers, payload

    def _forward(
        self, method: str, body: bytes | None = None
    ) -> tuple[int, dict[str, str], bytes]:
        request = urllib.request.Request(
            f"{self.backend}{self.path}",
            data=body,
            headers=self._request_headers(body),
            method=method,
        )
        try:
            with urllib.request.urlopen(request, timeout=self.upstream_timeout) as response:
                headers = dict(response.headers.items())
                headers, payload = self._decode_gzip(method, headers, response.read())
                return response.status, headers, payload
        except urllib.error.HTTPError as error:
            headers = dict(error.headers.items())
            headers, payload = self._decode_gzip(method, headers, error.read())
            return error.code, headers, payload

    def _send_bytes(
        self, status: int, upstream_headers: dict[str, str], payload: bytes
    ) -> None:
        hop_by_hop = {
            "connection",
            "content-length",
            "keep-alive",
            "proxy-authenticate",
            "proxy-authorization",
            "te",
            "trailer",
            "transfer-encoding",
            "upgrade",
            "server",
            "date",
        }
        self.send_response(status)
        for name, value in upstream_headers.items():
            if name.lower() not in hop_by_hop:
                self.send_header(name, value)
        if not any(name.lower() == "content-type" for name in upstream_headers):
            self.send_header("Content-Type", "application/octet-stream")
        self.send_header("Content-Length", str(len(payload)))
        if not any(name.lower() == "cache-control" for name in upstream_headers):
            self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(payload)

    def _send_sse(self, response: dict[str, Any]) -> None:
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream; charset=utf-8")
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Connection", "close")
        self.end_headers()

        base = {
            "id": response.get("id", f"chatcmpl-{secrets.token_hex(12)}"),
            "object": "chat.completion.chunk",
            "created": response.get("created", int(time.time())),
            "model": response.get("model", "qwen3-coder-30b-a3b-q4km"),
        }
        for choice in response.get("choices", []):
            index = choice.get("index", 0)
            message = choice.get("message", {})
            delta: dict[str, Any] = {"role": "assistant"}
            if message.get("content") is not None:
                delta["content"] = message.get("content")
            if message.get("tool_calls"):
                delta["tool_calls"] = [
                    {"index": tool_index, **tool_call}
                    for tool_index, tool_call in enumerate(message["tool_calls"])
                ]
            first = {**base, "choices": [{"index": index, "delta": delta, "finish_reason": None}]}
            final = {
                **base,
                "choices": [
                    {
                        "index": index,
                        "delta": {},
                        "finish_reason": choice.get("finish_reason", "stop"),
                    }
                ],
            }
            for event in (first, final):
                data = json.dumps(event, ensure_ascii=False, separators=(",", ":"))
                self.wfile.write(f"data: {data}\n\n".encode("utf-8"))

        if response.get("usage") is not None:
            usage = {**base, "choices": [], "usage": response["usage"]}
            data = json.dumps(usage, ensure_ascii=False, separators=(",", ":"))
            self.wfile.write(f"data: {data}\n\n".encode("utf-8"))
        self.wfile.write(b"data: [DONE]\n\n")
        self.wfile.flush()
        self.close_connection = True

    def do_GET(self) -> None:  # noqa: N802
        status, headers, payload = self._forward("GET")
        self._send_bytes(status, headers, payload)

    def do_HEAD(self) -> None:  # noqa: N802
        status, headers, _ = self._forward("HEAD")
        self.send_response(status)
        for name, value in headers.items():
            if name.lower() not in {"connection", "server", "date", "transfer-encoding"}:
                self.send_header(name, value)
        self.send_header("Content-Length", "0")
        self.end_headers()

    def do_POST(self) -> None:  # noqa: N802
        length = int(self.headers.get("Content-Length", "0"))
        original = self.rfile.read(length)
        if self.path.rstrip("/") != "/v1/chat/completions":
            status, headers, payload = self._forward("POST", original)
            self._send_bytes(status, headers, payload)
            return

        try:
            request_body = json.loads(original)
        except json.JSONDecodeError:
            self._send_bytes(
                400,
                {"Content-Type": "application/json"},
                b'{"error":"invalid JSON"}',
            )
            return

        client_stream = bool(request_body.get("stream"))
        upstream_body = dict(request_body)
        upstream_body["stream"] = False
        upstream_body.pop("stream_options", None)
        encoded = json.dumps(upstream_body, ensure_ascii=False).encode("utf-8")
        status, headers, payload = self._forward("POST", encoded)
        if status >= 400:
            self._send_bytes(status, headers, payload)
            return

        try:
            response = json.loads(payload)
            response, parsed_count = transform_chat_completion(response, request_body)
        except (json.JSONDecodeError, TypeError, ValueError) as error:
            message = json.dumps({"error": f"proxy transform failed: {error}"}).encode()
            self._send_bytes(502, {"Content-Type": "application/json"}, message)
            return

        self.log_message("POST %s parsed_tool_calls=%d", self.path, parsed_count)
        if client_stream:
            self._send_sse(response)
        else:
            output = json.dumps(response, ensure_ascii=False).encode("utf-8")
            self._send_bytes(
                status,
                {"Content-Type": "application/json; charset=utf-8"},
                output,
            )


def self_test() -> None:
    tools = [
        {
            "type": "function",
            "function": {
                "name": "shell_command",
                "parameters": {
                    "type": "object",
                    "properties": {"command": {"type": "string"}},
                },
            },
        }
    ]
    samples = [
        "<function=shell_command>\n<parameter=command>\nGet-ChildItem -Force\n</parameter>\n</function>\n</tool_call>",
        "<tool_call>\n<function=shell_command>\n<parameter=command>Write-Output ok</parameter>\n</function>\n</tool_call>",
        '<tools>{"name":"shell_command","arguments":{"command":"Get-Location"}}</tools>',
    ]
    for sample in samples:
        content, calls = parse_tool_calls(sample, tools)
        assert content is None
        assert len(calls) == 1
        assert calls[0]["function"]["name"] == "shell_command"
        json.loads(calls[0]["function"]["arguments"])
    print("self-test: ok")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--listen-host", default=os.getenv("QWEN_PROXY_HOST", "0.0.0.0"))
    parser.add_argument("--listen-port", type=int, default=int(os.getenv("QWEN_PROXY_PORT", "8080")))
    parser.add_argument("--backend", default=os.getenv("QWEN_PROXY_BACKEND", "http://127.0.0.1:8082"))
    parser.add_argument("--upstream-timeout", type=float, default=float(os.getenv("QWEN_PROXY_TIMEOUT", "3600")))
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return

    server = ThreadingHTTPServer((args.listen_host, args.listen_port), ProxyHandler)
    server.backend = args.backend.rstrip("/")  # type: ignore[attr-defined]
    server.upstream_timeout = args.upstream_timeout  # type: ignore[attr-defined]
    print(
        f"qwen3-coder-tool-proxy listening on {args.listen_host}:{args.listen_port}; "
        f"backend={server.backend}",
        flush=True,
    )
    server.serve_forever()


if __name__ == "__main__":
    main()
